extends Resource
class_name EquipmentInstance

@export var base: EquipmentBase
@export var rarity: String
@export var level: int
@export var rolled_mods := {}  # Dictionary of stat → value

func get_total_stats() -> Dictionary:
	var stats = base.base_stats.duplicate()
	for key in rolled_mods.keys():
		stats[key] += rolled_mods[key]
	return stats
