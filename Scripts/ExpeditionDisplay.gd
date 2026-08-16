extends Panel
class_name ExpeditionDisplay

@export var timerLabel: Label
@export var locationLabel: Label
@export var eventLog: RichTextLabel
@export var startStopBtn: Button
@export var returnToTownBtn: Button
@export var expeditionSystem: ExpeditionSystem
@export var uiController:UIController

var main = null
var uiTimer: Timer

func _ready() -> void:
	main = Utils.get_main()

	uiTimer = Timer.new()
	uiTimer.wait_time = 1.0
	uiTimer.one_shot = false
	uiTimer.timeout.connect(updateTimerLabel)
	add_child(uiTimer)

	GameEvents.expeditionStarted.connect(onExpeditionStarted)
	GameEvents.expeditionCompleted.connect(onExpeditionCompleted)
	GameEvents.expeditionStopped.connect(onExpeditionStopped)
	GameEvents.expeditionEventFired.connect(onExpeditionEventFired)

	startStopBtn.pressed.connect(onStartStopPressed)
	returnToTownBtn.pressed.connect(onReturnToTownPressed)

	hide()

func open() -> void:
	refresh()
	if main.game_data.isExpeditionActive:
		uiTimer.start()
	show()

func refresh() -> void:
	updateTimerLabel()
	updateButtons()
	rebuildEventLog()

# ── TIMER ─────────────────────────────────────────────────
func updateTimerLabel() -> void:
	if not main.game_data.isExpeditionActive:
		timerLabel.text = "No active expedition"
		locationLabel.text = "Expedition's HQ"
		uiTimer.stop()
		return

	@warning_ignore("narrowing_conversion")
	var now: int = Time.get_unix_time_from_system()
	var secondsLeft: int = max(0, main.game_data.expeditionEndTimestamp - now)
	@warning_ignore("integer_division")
	var minutesLeft: int = secondsLeft / 60
	var secsLeft: int = secondsLeft % 60
	locationLabel.text = main.game_data.expeditionArea
	timerLabel.text = "%02d:%02d remaining" % [
		minutesLeft,
		secsLeft
	]

# ── BUTTONS ───────────────────────────────────────────────
func updateButtons() -> void:
	if main.game_data.isExpeditionActive:
		startStopBtn.text = "Stop Expedition"
	else:
		startStopBtn.text = "Start Expedition"

func onStartStopPressed() -> void:
	Utils.animateButtonPress(startStopBtn)
	if main.game_data.isExpeditionActive:
		expeditionSystem.stopExpedition()
	else:
		# For now default to first unlocked area
		var area = main.game_data.unlockedAreas[0] if not main.game_data.unlockedAreas.is_empty() else "Hunting Grounds"
		expeditionSystem.startExpedition(area)

func onReturnToTownPressed() -> void:
	uiController.hideExpeditionMode()
	hide()

# ── EVENT LOG ─────────────────────────────────────────────
func rebuildEventLog() -> void:
	eventLog.bbcode_enabled = true
	eventLog.text = ""

	if main.game_data.expeditionTimeline.is_empty():
		eventLog.text = "[i][color=#888888]No expedition data yet.[/color][/i]"
		return

	var lastIndex = main.game_data.expeditionProgressIndex
	if lastIndex < 0:
		eventLog.text = "[i][color=#888888]Expedition just started...[/color][/i]"
		return

	for i in range(lastIndex + 1):
		var event = main.game_data.expeditionTimeline[i]
		eventLog.text += _formatEvent(event, i + 1)

	# Scroll to bottom
	await get_tree().process_frame
	eventLog.scroll_to_line(eventLog.get_line_count())

func onExpeditionEventFired(event: Dictionary) -> void:
	if not visible:
		return
	eventLog.bbcode_enabled = true
	eventLog.text += _formatEvent(event, main.game_data.expeditionProgressIndex + 1)
	await get_tree().process_frame
	eventLog.scroll_to_line(eventLog.get_line_count())

func _formatEvent(event: Dictionary, minute: int) -> String:
	var color = _getEventColor(event.get("type", "empty"))
	var title = event.get("title", "")
	var desc = event.get("description", "")
	var damage = event.get("damage", 0)
	var gold = event.get("gold", 0)
	var item = event.get("item", "")
	var hp = event.get("hpAfter", 50)

	var line = "#%d — [color=%s]%s[/color]" % [minute, color, title]
	if desc != "":
		line += "\n[color=#888888]%s[/color]" % desc
	if damage > 0:
		line += "  [color=#e74c3c]-%d HP[/color] [color=#888888](→ %d)[/color]" % [damage, hp]
	if gold > 0:
		line += "  [color=#c8880a]+%dg[/color]" % gold
	if item != "":
		line += "  [color=#27ae60]+%s[/color]" % item
	if event.get("dungeon", false):
		line += "  [color=#9b59b6]★ Dungeon found![/color]"
	line += "\n\n"
	return line

func _getEventColor(type: String) -> String:
	match type:
		"monster":  return "#e74c3c"
		"trap":     return "#e67e22"
		"item":     return "#27ae60"
		"gold":     return "#c8880a"
		"dungeon":  return "#9b59b6"
		_:          return "#888888"

# ── SIGNALS ───────────────────────────────────────────────
func onExpeditionStarted(_area: String, _duration: int) -> void:
	eventLog.text = ""
	updateButtons()
	updateTimerLabel()
	uiTimer.start()

func onExpeditionCompleted(survived: bool) -> void:
	updateButtons()
	updateTimerLabel()
	uiTimer.stop()
	if survived:
		eventLog.text += "[color=#27ae60]Expedition complete! Collect your rewards.[/color]\n"
	else:
		eventLog.text += "[color=#e74c3c]Expeditioner collapsed and was brought back safely.[/color]\n"

func onExpeditionStopped() -> void:
	updateButtons()
	updateTimerLabel()
	uiTimer.stop()
