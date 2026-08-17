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
func startExpedition(area: String) -> void:
	if main.game_data.isExpeditionActive:
		return
	var duration = getExpeditionDuration()
	if duration <= 0:
		GameEvents.eventLogged.emit(
			"You need Expedition Boots to send out an expeditioner.", "system", false
		)
		return

	# Clear previous expedition data
	main.game_data.expeditionInventory = []
	main.game_data.pendingExpeditionGold = 0
	main.game_data.expeditionProgressIndex = -1
	main.game_data.expeditionHealth = 50
	lastProcessedMinuteIndex = -1  # ← reset in memory tracker

	# Generate full timeline upfront
	var timeline = expeditionTimeline.generateTimeline(duration, area)
	main.game_data.expeditionTimeline = timeline
	main.game_data.expeditionDurationMinutes = duration

	# Set timestamps
	var secondsPerMinute = DEBUG_SECONDS_PER_MINUTE if DEBUG_SPEED else 60
	@warning_ignore("narrowing_conversion")
	var now: int = Time.get_unix_time_from_system()
	main.game_data.expeditionStartTimestamp = now
	main.game_data.expeditionEndTimestamp = now + (duration * secondsPerMinute)
	main.game_data.isExpeditionActive = true
	main.game_data.expeditionArea = area
	main.save_game()

	# Start timer at 1 second intervals
	expeditionTimer.stop()
	expeditionTimer.wait_time = 1.0  # ← 1 second, not secondsPerMinute
	expeditionTimer.one_shot = false
	expeditionTimer.start()

	GameEvents.expeditionStarted.emit(area, duration)
	GameEvents.eventLogged.emit(
		"Expeditioner sent to %s. Returns in %d minutes." % [area, duration],
		"town", false
	)
	print("Expedition started at %s | Ends at %s" % [
		_readableTime(now),
		_readableTime(main.game_data.expeditionEndTimestamp)
	])

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
	if item != "":
		main.game_data.expeditionInventory.append({"name": item, "qty": 1})

	# Dungeon
	if event.get("dungeon", false):
		GameEvents.dungeonDiscovered.emit(main.game_data.expeditionArea)

# ── EXPEDITION COMPLETE ───────────────────────────────────
func _handleExpeditionComplete() -> void:
	expeditionTimer.stop()
	main.game_data.isExpeditionActive = false
	main.save_game()

	var survived = main.game_data.expeditionHealth > 0
	var msg = "Expeditioner returned from %s!" % main.game_data.expeditionArea
	if not survived:
		msg = "Expeditioner collapsed and was brought back to safety."

	GameEvents.eventLogged.emit(msg, "town", false)
	GameEvents.expeditionCompleted.emit(survived)

# ── HELPERS ───────────────────────────────────────────────
func getExpeditionDuration() -> int:
	return 10  # TEMP: remove when boots system is in
	var boots = main.game_data.equippedExpeditionBoots
	if not boots or boots.is_empty():
		return 0
	return boots.get("expeditionMinutes", 0)

func _readableTime(timestamp: int) -> String:
	var datetime = Time.get_datetime_dict_from_unix_time(timestamp)
	return "%02d:%02d:%02d" % [datetime["hour"], datetime["minute"], datetime["second"]]
