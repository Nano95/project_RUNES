extends VBoxContainer
class_name LootManager

@export var loot_entry_scene: PackedScene

var active_entries := {}  # key: loot_type, value: LootEntry instance

func add_loot(loot_name: String, icon:Texture, quantity: int) -> void:
	if active_entries.has(loot_name):
		# Refresh existing entry
		active_entries[loot_name].add_quantity(quantity)
	else:
		# Create new entry
		var entry := loot_entry_scene.instantiate() as LootEntry
		entry.setup(loot_name, icon, quantity)

		add_child(entry)
		active_entries[loot_name] = entry

		# When entry frees itself, remove from dictionary
		entry.tree_exited.connect(func():
			active_entries.erase(loot_name))

func get_loot_info(key: String) -> Dictionary:
	if loot_data.has(key):
		return loot_data[key]
	else:
		push_warning("Loot key not found: %s" % key)
		return {}


func add_loot_from_key(key: String, quantity: int) -> void:
	var info := get_loot_info(key)
	if info.is_empty():
		return

	var loot_name:String = info["name"]
	var icon:Texture = info["icon"]

	add_loot(loot_name, icon, quantity)


var loot_data = {
	"gold": {
		"name": "Gold",
		"short_name": "gold",
		"icon": load("res://Sprites/GOLD_ICON.png")
	},
	"physical essence": {
		"name": "Physical Essence",
		"short_name": "phys ess",
		"icon": load("res://Sprites/ESSENCE_ICON.png")
	},
	"fire essence": {
		"name": "Fire Essence",
		"short_name": "fire ess",
		"icon": load("res://Sprites/ESSENCE_ICON.png")
	}
}
