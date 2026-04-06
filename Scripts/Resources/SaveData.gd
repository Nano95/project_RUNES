extends Resource
class_name SaveData

@export_category("General")
@export var inventory: Array[EquipmentInstance] = []
@export var rune_inv: Dictionary = { # Start pack
	"Arcane Cross": 100,
	"Arcane Explosion": 80,
	"Arcane Strike": 250,
	"Light Healing": 25
}
@export var last_crafting_timestamp:int = 0

@export_category("Player")
@export var current_level:int = 1
@export var total_exp:float = 0 # true amoutn of exp player has
@export var current_exp:float = 0 # Drives UI -- progress Bar -- and resets to 0 on level up
@export var total_gold:float = 0
@export var current_gold:float = 0
@export var total_essences:Dictionary = {
	"arcane": 0,
	"fire": 0,
	"ice": 0,
	"earth": 0,
	"electric": 0
}
@export var current_essences:Dictionary = {
	"arcane": 0,
	"fire": 0,
	"ice": 0,
	"earth": 0,
	"electric": 0
}
@export var equipped = {
	"slot1": null,
	"slot2": null
}

@export var selected_battle_runes = {
	"slot1": null,
	"slot2": null,
	"slot3": null,
	"slot4": null,
	"slot5": null,
	"slot6": null,
	"slot7": null,
	"slot8": null,
}
# Null or rune names
@export var offline_runes = {
	"slot1": null,
	"slot2": null,
	"slot3": null,
	"slot4": null,
	"slot5": null,
	"slot6": null
}
@export var offline_rune_timestamps = { 
	"slot1": 0, 
	"slot2": 0,
	"slot3": 0,
	"slot4": 0,
	"slot5": 0,
	"slot6": 0
}
@export var unlocked_monster_families = {
	"slimes": false,
	"orcs": false,
	"sandlings": false,
	"dwarves": false,
	"jungle": false
}
@export var available_ap:int = 0
@export var base_stats:Dictionary = { "health": 10, "focus": 10, "power": 10, "luck": 10 }
@export var allocated_stats:Dictionary = { "health": 0, "focus": 0, "power": 0, "luck": 0 }
@export var prestige_points_available:int = 0 
@export var prestige_points_spent:int = 0 
@export var prestige_level:int = 0
@export var prestige_unlocked:bool = false
@export_category("Stats")

@export var highest_level_reached:int = 0
@export var total_prestige_points_earned:int = 0
@export var runes_used:int = 0
@export var enemies_killed:int = 0
@export var total_runes_obtained: Dictionary = {
	#"Arcane Cross": 20,
	#"Arcane Explosion": 10,
	#"Arcane Strike": 100,
	#"Great Healing": 25
}
# these reset every time that you prestige.
@export var current_run_runes_obtained: Dictionary = {
	#"Arcane Cross": 20,
	#"Arcane Explosion": 10,
	#"Arcane Strike": 100,
	#"Great Healing": 25
}

@export var total_monster_kills: Dictionary = {
	#"slime hatchling": 20,
	#"elite slime": 10,
}
@export var total_run_monster_kills: Dictionary = {
	#"slime hatchling": 20,
	#"elite slime": 10,
}

func add_item_to_inventory(item: EquipmentInstance) -> void:
	inventory.append(item)

func remove_item_from_inventory(item: EquipmentInstance) -> void:
	inventory.erase(item)

func equip(item: EquipmentInstance, slot):
	equipped[slot] = item

func unequip(slot):
	equipped[slot] = null

func get_rune_count(rune_name:String) -> int:
	if (rune_inv.get(rune_name)):
		return rune_inv[rune_name]
	return 0

func add_rune_to_inv(rune:RuneData, qty:int, notify:bool = false) -> void:
	if (notify && is_instance_valid(Utils)):
		pass
		#Utils.spawn_notification(item_name, quantity)
	if rune.name in rune_inv:
		rune_inv[rune.name] += qty
		return
	
	rune_inv[rune.name] = qty

func remove_rune_from_inv(rune:RuneData, qty:int) -> int:
	rune_inv[rune.name] -= qty
	if (rune_inv[rune.name] <= 0):
		rune_inv.erase(rune.name)
		clear_rune_from_battle_loadout(rune.name)
		
		return 0
	
	return rune_inv[rune.name]

# Data can be null or a string (rune name)
func set_battle_rune_slot(id:int, data) -> void:
	if (data == ""): 
		data = null
	var slot_label:String = str("slot", id)
	selected_battle_runes[slot_label] = data

# Data can be null or a string (rune name)
func set_offline_rune_slot(id:int, data) -> void:
	if (data == ""): 
		data = null
	var slot_label:String = str("slot", id)
	offline_runes[slot_label] = data
	# Reset the timestamp
	if (data == null):
		offline_rune_timestamps[slot_label] = 0

# Returns null or string
func get_offline_rune_slot(id):
	var slot_label:String = str("slot", id)
	return offline_runes[slot_label]

func add_crafted_runes_by_name(runes:Dictionary) -> void:
	for rune_name in runes.keys():
		var qty:int = runes[rune_name]
		# FOR THE INVENTORY
		if (rune_name in rune_inv):
			rune_inv[rune_name] += qty
		else:
			rune_inv[rune_name] = qty
		# FOR THE STATS
		if (rune_name in current_run_runes_obtained):
			current_run_runes_obtained[rune_name] += qty
		else:
			current_run_runes_obtained[rune_name] = qty
		
		if (rune_name in total_runes_obtained):
			total_runes_obtained[rune_name] += qty
		else:
			total_runes_obtained[rune_name] = qty

func clear_rune_from_battle_loadout(rune_name: String) -> void:
	for slot in selected_battle_runes.keys():
		if selected_battle_runes[slot] == rune_name:
			selected_battle_runes[slot] = null
			return


func reset_data() -> void:
	rune_inv = { # Start pack
	"Arcane Cross": 100,
	"Arcane Explosion": 80,
	"Arcane Strike": 250,
	"Light Healing": 25
}
	current_level = 1
	total_exp = 0 # true am
	current_exp = 0 # Drive
	total_gold = 0
	current_gold = 0
	total_essences = {
		"arcane": 0,
		"fire": 0,
		"ice": 0,
		"earth": 0,
		"electric": 0
	}
	current_essences = {
		"arcane": 0,
		"fire": 0,
		"ice": 0,
		"earth": 0,
		"electric": 0
	}
	selected_battle_runes = {
		"slot1": null,
		"slot2": null,
		"slot3": null,
		"slot4": null,
		"slot5": null,
		"slot6": null,
		"slot7": null,
		"slot8": null,
	}
	offline_runes = {
		"slot1": null,
		"slot2": null,
		"slot3": null,
		"slot4": null,
		"slot5": null,
		"slot6": null
	}
	offline_rune_timestamps = { 
		"slot1": 0, 
		"slot2": 0,
		"slot3": 0,
		"slot4": 0,
		"slot5": 0,
		"slot6": 0
	}
	unlocked_monster_families = {
		"slimes": false,
		"orcs": false,
		"sandlings": false,
		"dwarves": false,
		"jungle": false
	}
	available_ap = 0
	base_stats = { "health": 10, "focus": 10, "power": 10, "luck": 10 }
	allocated_stats = { "health": 0, "focus": 0, "power": 0, "luck": 0 }
	
	# STATS
	runes_used = 0
	enemies_killed = 0
	total_runes_obtained = {}
	current_run_runes_obtained = {}
	total_monster_kills = {}
	total_run_monster_kills = {}

func is_curse_active(curse_name:String) -> bool:
	for curse in curses:
		if (curse["id"] == curse_name):
			return curse["toggled"]
	
	return false

@export var blessings:Array = [
	{
		id = "mod_offline_production-20",
		name = "Deep Sleep",
		desc = "Rest Hard. Offline rune production is 20% faster",
		toggled = false,
		cost = 40,
		type = "offline",
		category = "runes"
	},
	{
		id = "essence_package",
		name = "Inner Reservoir",
		desc = "Begin each run with 1,500 essence of every type.",
		toggled = false,
		cost = 50,
		type = "economy",
		category = "essence"
	},
	{
		id = "mod_gold-20",
		name = "Pick Pocket",
		desc = "Earn 20% more gold from defeated monsters.",
		toggled = false,
		cost = 70,
		type = "economy",
		category = "gold"
	},
	{
		id = "extra_rune_slot",
		name = "Battle",
		desc = "+1 rune slot available in battle.",
		toggled = false,
		cost = 100,
		type = "combat",
		category = "buff"
	},
	{
		id = "mod_essences-10",
		name = "Channeler",
		desc = "Earn 10% more essences from defeated monsters.",
		toggled = false,
		cost = 30,
		type = "economy",
		category = "essence"
	},
	{
		id = "mod_essences-15",
		name = "Grand Channeler",
		desc = "Earn 15% more essences from defeated monsters.",
		toggled = false,
		cost = 50,
		type = "economy",
		category = "essence"
	},
	{
		id = "mod_exp-15",
		name = "Student",
		desc = "Earn 15% more exp from defeated monsters.",
		toggled = false,
		cost = 40,
		type = "economy",
		category = "exp"
	},
	{
		id = "mod_exp-20",
		name = "Scholar",
		desc = "Earn 20% more exp from defeated monsters.",
		toggled = false,
		cost = 95,
		type = "economy",
		category = "exp"
	},
]
@export var curses:Array = [
	{
		id = "mod_hp-25",
		name = "Bloodthirst",
		desc = "Monsters spawn with 25% more health.",
		toggled = false,
		type = "combat",
		category = "monsters"
	},
	{
		id = "death_toll",
		name = "Death's Toll",
		desc = "House always wins. You don't preserve the loot gained in that floor if you die.",
		toggled = false,
		type = "economy",
		category = "loot"
	},
	{
		id = "mod_elites-10",
		name = "Ascended Foes",
		desc = "Elite monsters appear 10% more often.",
		toggled = false,
		type = "combat",
		category = "monsters"
	},
	{
		id = "mod_monster_speed-1",
		name = "Relentless",
		desc = "Monsters attack 1 turn faster.",
		toggled = false,
		type = "combat",
		category = "monsters"
	},
	{
		id = "arcane_debuff-15",
		name = "Arcane Fracture",
		desc = "Your arcane spells deal 15% less damage.",
		toggled = false,
		type = "combat",
		category = "debuff"
	},
	{
		id = "mod_exp_gold-10",
		name = "Stubborn",
		desc = "Earn 10% less exp from defeated monsters.",
		toggled = false,
		type = "economy",
		category = "exp"
	},
]
