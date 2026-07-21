extends Control
class_name MainController

var main:MainNode
@export_category("Other")
@export var tickTimer:Timer

@export_category("UI")
@export var eventLog: RichTextLabel

func _ready() -> void:
	main = Utils.get_main()
	GameEvents.eventLogged.connect(_on_event_logged)
	tickTimer.wait_time = 0.4
	tickTimer.timeout.connect(onTick)
	tickTimer.start()
	GameEvents.eventLogged.emit("Welcome back to town!", "town", false)

func onTick() -> void:
	GameEvents.tickFired.emit()

func _on_event_logged(text: String, style: String, track_event_number: bool = true) -> void:
	if (track_event_number):
		eventLog.append_text(Utils.format_log_line(main.game_data.eventCount, text, style))
	else:
		eventLog.append_text(Utils.format_log(text, style) + "\n")
