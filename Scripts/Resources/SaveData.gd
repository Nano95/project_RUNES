extends Resource
class_name SaveData

@export_category("General")
@export var inventory: Array[EquipmentInstance] = []

@export_category("Player")
@export var current_level:int = 1
@export var total_exp:float = 0 # true amoutn of exp player has
@export var current_exp:float = 0 # Drives UI -- progress Bar -- and resets to 0 on level up
@export var total_gold:float = 0
@export var current_gold:float = 0
@export var equipped = {
	"slot1": null,
	"slot2": null
}
@export var available_ap:int = 0
@export var base_stats:Dictionary = { "health": 10, "focus": 10, "power": 10, "luck": 10 }
@export var allocated_stats:Dictionary = { "health": 0, "focus": 0, "power": 0, "luck": 0 }

@export_category("Stats")
@export var runes_used:int = 0
@export var enemies_killed:int = 0

func add_item_to_inventory(item: EquipmentInstance) -> void:
	inventory.append(item)

func remove_item_from_inventory(item: EquipmentInstance) -> void:
	inventory.erase(item)

func equip(item: EquipmentInstance, slot):
	equipped[slot] = item

func unequip(slot):
	equipped[slot] = null
