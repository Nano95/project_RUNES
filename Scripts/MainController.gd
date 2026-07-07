extends Control
class_name MainController

@export_category("Other")
@export var tickTimer:Timer

@export_category("UI")
@export var eventLog: RichTextLabel

func _ready() -> void:
	GameEvents.eventLogged.connect(_on_event_logged)
	tickTimer.wait_time = 1.2
	tickTimer.timeout.connect(_on_tick)
	tickTimer.start()
	GameEvents.eventLogged.emit("You are in the safe zone.", "town")
	await get_tree().create_timer(2.0).timeout
	$AreaSystem.enterArea("Outskirts")
	await get_tree().create_timer(3.0).timeout
	$AreaSystem.exitArea()

func _on_tick() -> void:
	GameEvents.tickFired.emit()

func _on_event_logged(text: String, style: String) -> void:
	eventLog.append_text(Utils.format_log(text, style))
