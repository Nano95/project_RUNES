extends Node
class_name ExpeditionSystem

var main:MainNode
var expeditionTimer: Timer
@export var expeditionTimeline: ExpeditionTimeline
var lastProcessedMinuteIndex: int = -1
var alignmentPending: bool = false

const DEBUG_SPEED = true  # set to false for production
const DEBUG_SECONDS_PER_MINUTE = 10  # 10 seconds = 1 expedition minute

func _ready() -> void:
	main = Utils.get_main()
	expeditionTimer = Timer.new()
	expeditionTimer.wait_time = 60.0  # one minute
	expeditionTimer.one_shot = false
	expeditionTimer.timeout.connect(onTimerTick)
	add_child(expeditionTimer)

# ── START / STOP ──────────────────────────────────────────
func startExpedition() -> void:
	if main.game_data.isExpeditionActive:
		return
	var duration = getExpeditionDuration()
	if duration <= 0:
		_logToExpedition(
			"You need Expedition Boots to send out an expeditioner.", "system"
		)
		return

	# Clear previous expedition data
	main.game_data.pendingExpeditionInventory = []
	main.game_data.expeditionProgressIndex = -1
	main.game_data.expeditionHealth = 50
	lastProcessedMinuteIndex = -1  # ← reset in memory tracker

	# Generate full timeline upfront
	var timeline = expeditionTimeline.generateTimeline(duration)
	# store starting area as Hunting Grounds always
	main.game_data.expeditionArea = "Hunting Grounds"
	main.game_data.expeditionTimeline = timeline
	main.game_data.expeditionDurationMinutes = duration

	# Set timestamps
	var secondsPerMinute = DEBUG_SECONDS_PER_MINUTE if DEBUG_SPEED else 60
	@warning_ignore("narrowing_conversion")
	var now: int = Time.get_unix_time_from_system()
	main.game_data.expeditionStartTimestamp = now
	main.game_data.expeditionEndTimestamp = now + (duration * secondsPerMinute)
	main.game_data.isExpeditionActive = true
	main.save_game()

	# Start timer at 1 second intervals
	expeditionTimer.stop()
	expeditionTimer.wait_time = 1.0  # ← 1 second, not secondsPerMinute
	expeditionTimer.one_shot = false
	expeditionTimer.start()

	GameEvents.expeditionStarted.emit(duration)
	_logToBoth(
		"Expeditioner has left the town! Returns in %d minutes." % duration,
		"empty", "town"
	)

func stopExpedition() -> void:
	main.game_data.isExpeditionActive = false
	expeditionTimer.stop()
	main.save_game()
	GameEvents.expeditionStopped.emit()
	GameEvents.eventLogged.emit(
		"Expedition recalled early.", "system", false
	)

# ── TIMER TICK ────────────────────────────────────────────
func onTimerTick() -> void:
	if not main.game_data.isExpeditionActive:
		expeditionTimer.stop()
		return

	@warning_ignore("narrowing_conversion")
	var now: int = Time.get_unix_time_from_system()
	var secondsLeft: int = main.game_data.expeditionEndTimestamp - now
	var secondsPerMinute = DEBUG_SECONDS_PER_MINUTE if DEBUG_SPEED else 60

	# Calculate current minute index same way as brother
	var minutesRemainingCeil: int = ceil(secondsLeft / float(secondsPerMinute))
	var currentMinuteIndex: int = main.game_data.expeditionDurationMinutes - minutesRemainingCeil - 1
	currentMinuteIndex = min(currentMinuteIndex, main.game_data.expeditionTimeline.size() - 1)

	# Only fire when we cross a new minute boundary
	if currentMinuteIndex > lastProcessedMinuteIndex:
		lastProcessedMinuteIndex = currentMinuteIndex

		if currentMinuteIndex >= 0:
			main.game_data.expeditionProgressIndex = currentMinuteIndex

			if currentMinuteIndex >= main.game_data.expeditionTimeline.size():
				_handleExpeditionComplete()
				return

			var event = main.game_data.expeditionTimeline[currentMinuteIndex]
			if event.is_empty():
				GameEvents.expeditionEventFired.emit(event)
				return

			_applyEvent(event)
			main.save_game()
			GameEvents.expeditionEventFired.emit(event)

			if main.game_data.expeditionHealth <= 0:
				_handleExpeditionComplete()
				return

	# Check if last block processed
	var isLastBlockProcessed = main.game_data.expeditionProgressIndex >= \
							   main.game_data.expeditionTimeline.size() - 1

	if isLastBlockProcessed:
		main.game_data.isExpeditionActive = false
		expeditionTimer.stop()
		_handleExpeditionComplete()
		return

	# Safety: time expired but events remain
	if secondsLeft <= 0 and not isLastBlockProcessed:
		_processRemainingEvents()
		_handleExpeditionComplete()

# ── OFFLINE SYNC ──────────────────────────────────────────
func syncOfflineProgress() -> void:
	if not main.game_data.isExpeditionActive:
		return

	@warning_ignore("narrowing_conversion")
	var now: int = Time.get_unix_time_from_system()
	var secondsLeft: int = main.game_data.expeditionEndTimestamp - now
	var secondsPerMinute = DEBUG_SECONDS_PER_MINUTE if DEBUG_SPEED else 60

	if secondsLeft <= 0:
		_processRemainingEvents()
		_handleExpeditionComplete()
		return

	var totalSeconds = main.game_data.expeditionDurationMinutes * secondsPerMinute
	var secondsPassed = totalSeconds - secondsLeft
	@warning_ignore("integer_division")
	var fullMinutesPassed = secondsPassed / secondsPerMinute
	var targetIndex = fullMinutesPassed - 1

	if targetIndex > main.game_data.expeditionProgressIndex:
		for i in range(main.game_data.expeditionProgressIndex + 1, targetIndex + 1):
			if i >= main.game_data.expeditionTimeline.size():
				break
			var event = main.game_data.expeditionTimeline[i]
			_applyEvent(event)
			main.game_data.expeditionProgressIndex = i
			GameEvents.expeditionEventFired.emit(event)
			if main.game_data.expeditionHealth <= 0:
				_handleExpeditionComplete()
				return
		main.save_game()

	# Critical — sync lastProcessedMinuteIndex so onTimerTick doesn't refire
	lastProcessedMinuteIndex = main.game_data.expeditionProgressIndex

	if expeditionTimer.is_stopped():
		expeditionTimer.wait_time = 1.0
		expeditionTimer.one_shot = false
		expeditionTimer.start()

	GameEvents.expeditionSynced.emit()
	print("Expedition resumed. Minutes left: %d" % ceil(secondsLeft / float(secondsPerMinute)))

func _processRemainingEvents() -> void:
	print("=== PROCESS REMAINING ===")
	print("progressIndex before: ", main.game_data.expeditionProgressIndex)
	var lastIndex = main.game_data.expeditionTimeline.size() - 1
	for i in range(main.game_data.expeditionProgressIndex + 1, lastIndex + 1):
		var event = main.game_data.expeditionTimeline[i]
		_applyEvent(event)
		main.game_data.expeditionProgressIndex = i
		GameEvents.expeditionEventFired.emit(event)
		if main.game_data.expeditionHealth <= 0:
			break
	main.save_game()

# ── APPLY EVENT ───────────────────────────────────────────
func _applyEvent(event: Dictionary) -> void:
	if main.game_data.expeditionHealth <= 0:
		return

	# Damage
	var damage = event.get("damage", 0)
	if damage > 0:
		main.game_data.expeditionHealth = max(0, main.game_data.expeditionHealth - damage)

	# Gold
	var gold = event.get("gold", 0)
	if gold > 0:
		main.game_data.pendingExpeditionGold += gold
		main.game_data.stats["totalGoldEarned"] += gold

	# Item
	var item = event.get("item", "")
	var qty = event.get("qty", 1)
	if item != "":
		var stackCap = ItemRegistry.getStackCap(item)
		var remaining = qty
		# Try to merge into existing stacks
		for stack in main.game_data.pendingExpeditionInventory:
			if remaining <= 0:
				break
			if stack.get("name") == item and stack.get("qty", 0) < stackCap:
				var space = stackCap - stack["qty"]
				var toAdd = min(space, remaining)
				stack["qty"] += toAdd
				remaining -= toAdd
		# Create new stack for remainder
		if remaining > 0:
			main.game_data.pendingExpeditionInventory.append({"name": item, "qty": remaining})
	# Dungeon
	if event.get("dungeon", false):
		GameEvents.dungeonDiscovered.emit(main.game_data.expeditionArea)

# ── EXPEDITION COMPLETE ───────────────────────────────────
func _handleExpeditionComplete() -> void:
	expeditionTimer.stop()
	main.game_data.isExpeditionActive = false
	# Replace bin contents with new expedition loot
	# (already populated during the expedition via _applyEvent)
	# Clear pending gold — auto collect it
	main.game_data.savedGold += main.game_data.pendingExpeditionGold
	main.game_data.stats["totalGoldEarned"] += main.game_data.pendingExpeditionGold
	if main.game_data.pendingExpeditionGold > 0:
		_logToBoth("Expedition gold collected: +%dg" % main.game_data.pendingExpeditionGold, 
			"town")
		GameEvents.goldDeposited.emit(main.game_data.pendingExpeditionGold)
	main.game_data.pendingExpeditionGold = 0
	main.game_data.expeditionInventory = main.game_data.pendingExpeditionInventory.duplicate()
	main.game_data.pendingExpeditionInventory = []
	
	main.save_game()

	var survived = main.game_data.expeditionHealth > 0
	var msg = "Expeditioner returned from %s!" % main.game_data.expeditionArea
	if not survived:
		msg = "Expeditioner collapsed and was brought back to safety."

	_logToBoth(msg, "empty", "town")
	GameEvents.expeditionCompleted.emit(survived)

# ── HELPERS ───────────────────────────────────────────────
func getExpeditionDuration() -> int:
	var boots = main.game_data.equippedExpeditionBoots
	if not boots or boots.is_empty():
		return 0
	return boots.get("effects", {}).get("expeditionMinutes", 0)

func _readableTime(timestamp: int) -> String:
	var datetime = Time.get_datetime_dict_from_unix_time(timestamp)
	return "%02d:%02d:%02d" % [datetime["hour"], datetime["minute"], datetime["second"]]

func _logToExpedition(message: String, type: String = "empty") -> void:
	GameEvents.expeditionEventFired.emit({
		"type": type,
		"title": message,
		"description": "",
		"damage": 0,
		"gold": 0,
		"item": "",
		"qty": 0,
		"dungeon": false,
		"showNumber": false
	})

func _logToBoth(message: String, expType: String = "empty", logType: String = "town") -> void:
	GameEvents.eventLogged.emit(message, logType, false)
	_logToExpedition(message, expType)
