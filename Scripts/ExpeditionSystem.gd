extends Node
class_name ExpeditionSystem

var main:MainNode
var expeditionTimer: Timer
@export var expeditionTimeline: ExpeditionTimeline

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

	# Clear previous expedition inventory
	main.game_data.expeditionInventory = []
	main.game_data.pendingExpeditionGold = 0
	main.game_data.expeditionProgressIndex = -1
	main.game_data.expeditionHealth = 50

	# Generate full timeline upfront
	var timeline = expeditionTimeline.generateTimeline(duration, area)
	main.game_data.expeditionTimeline = timeline
	main.game_data.expeditionDurationMinutes = duration

	# Set timestamps
	@warning_ignore("narrowing_conversion")
	var now: int = Time.get_unix_time_from_system()
	main.game_data.expeditionStartTimestamp = now
	main.game_data.expeditionEndTimestamp = now + (duration * 60)
	main.game_data.isExpeditionActive = true
	main.game_data.expeditionArea = area

	main.save_game()
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

	if secondsLeft <= 0:
		# Process any remaining events
		_processRemainingEvents()
		_handleExpeditionComplete()
		return

	# Process next event
	var nextIndex = main.game_data.expeditionProgressIndex + 1
	if nextIndex < main.game_data.expeditionTimeline.size():
		var event = main.game_data.expeditionTimeline[nextIndex]
		_applyEvent(event)
		main.game_data.expeditionProgressIndex = nextIndex
		main.save_game()
		GameEvents.expeditionEventFired.emit(event)

		# Stop early if expeditioner died
		if main.game_data.expeditionHealth <= 0:
			_handleExpeditionComplete()

# ── OFFLINE SYNC ──────────────────────────────────────────
func syncOfflineProgress() -> void:
	if not main.game_data.isExpeditionActive:
		return

	@warning_ignore("narrowing_conversion")
	var now: int = Time.get_unix_time_from_system()
	var secondsLeft: int = main.game_data.expeditionEndTimestamp - now

	# Case A — expedition finished while away
	if secondsLeft <= 0:
		_processRemainingEvents()
		_handleExpeditionComplete()
		return

	# Case B — expedition still running, catch up on missed events
	var totalSeconds = main.game_data.expeditionDurationMinutes * 60
	var secondsPassed = totalSeconds - secondsLeft
	@warning_ignore("integer_division")
	var minutesPassed = secondsPassed / 60
	var targetIndex = minutesPassed - 1

	if targetIndex >= 0:
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

	# Resume timer
	if expeditionTimer.is_stopped():
		if expeditionTimer.is_stopped():
			@warning_ignore("narrowing_conversion")
			var newNow: int = Time.get_unix_time_from_system()
			var newSecondsPassed = (main.game_data.expeditionDurationMinutes * 60) - \
								(main.game_data.expeditionEndTimestamp - newNow)
			var secondsIntoCurrentMinute = newSecondsPassed % 60
			var secondsUntilNextMinute = 60 - secondsIntoCurrentMinute

			if secondsUntilNextMinute >= 59:
				# Already aligned, start normally
				expeditionTimer.wait_time = 60.0
				expeditionTimer.one_shot = false
				expeditionTimer.start()
			else:
				# Wait for remainder of current minute then start normal timer
				var alignTimer = get_tree().create_timer(secondsUntilNextMinute)
				alignTimer.timeout.connect(func():
					expeditionTimer.wait_time = 60.0
					expeditionTimer.one_shot = false
					expeditionTimer.start()
					onTimerTick()  # fire immediately on alignment
				)

	print("Expedition resumed. Minutes left: %d" % ceil(secondsLeft / 60.0))

func _processRemainingEvents() -> void:
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
