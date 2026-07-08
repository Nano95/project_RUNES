extends Control
class_name MainController

@export_category("Other")
@export var tickTimer:Timer

@export_category("UI")
@export var eventLog: RichTextLabel

func _ready() -> void:
	GameEvents.eventLogged.connect(_on_event_logged)
	tickTimer.wait_time = 1.2
	tickTimer.timeout.connect(onTick)
	tickTimer.start()
	GameEvents.eventLogged.emit("Welcome back to town!", "town")

func onTick() -> void:
	GameEvents.tickFired.emit()

func _on_event_logged(text: String, style: String) -> void:
	eventLog.append_text(Utils.format_log(text, style))
