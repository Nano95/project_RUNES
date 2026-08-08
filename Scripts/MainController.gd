extends Control
class_name MainController

var main:MainNode
@export var equipmentSystem:EquipmentSystem
@export_category("Other")
@export var tickTimer:Timer

@export_category("UI")
@export var eventLog: RichTextLabel

func _ready() -> void:
	main = Utils.get_main()
	GameEvents.eventLogged.connect(_on_event_logged)
	tickTimer.wait_time = 1.0
	tickTimer.timeout.connect(onTick)
	tickTimer.start()
	GameEvents.eventLogged.emit("Welcome back to town!", "town", false)
	
	if not main.game_data.equippedWeapon.is_empty():
		return  # already has gear, don't overwrite

	var weapon = ItemRegistry.rollEquipmentInstance("Crude Blade")
	var shield = ItemRegistry.rollEquipmentInstance("Wooden Shield")
	var helmet = ItemRegistry.rollEquipmentInstance("Leather Helmet")
	var armor = ItemRegistry.rollEquipmentInstance("Leather Armor")
	var legs = ItemRegistry.rollEquipmentInstance("Leather Legs")
	var boots = ItemRegistry.rollEquipmentInstance("Leather Boots")

	main.game_data.equippedWeapon = weapon
	main.game_data.equippedShield = shield
	main.game_data.equippedHelmet = helmet
	main.game_data.equippedArmor = armor
	main.game_data.equippedLegs = legs
	main.game_data.equippedBoots = boots
	main.save_game()

func onTick() -> void:
	GameEvents.tickFired.emit()

func _on_event_logged(text: String, style: String, track_event_number: bool = true) -> void:
	if (track_event_number):
		eventLog.append_text(Utils.format_log_line(main.game_data.eventCount, text, style))
	else:
		eventLog.append_text(Utils.format_log(text, style) + "\n")
