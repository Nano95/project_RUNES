extends Resource
class_name SaveData

@export_category("Test_game")
@export var hp: int = 80
@export var baseHp: int = 80
@export var eventCount: int = 0
@export var gold: int = 0
@export var currentWeight: float = 0.0
@export var maxWeight: float = 50.0
@export var sessionKills: int = 0

@export var currentArea: String = "Town"
@export var inArea: bool = false
@export var unlockedAreas: Array[String] = ["Hunting Grounds", "Slime Swamps"]  # Outskirts unlocked by default

@export var inCombat: bool = false
@export var currentMonsterName: String = ""
@export var currentMonsterTier: String = ""
@export var currentMonsterHp: int = 0
@export var currentMonsterAtk: int = 0
@export var isFleeing: bool = false
@export var fleeTicks: int = 0
@export var activeStatusEffects: Dictionary = {}

@export var backpack: Array[Dictionary] = []
@export var backpackMax: int = 20
@export var chest: Array[String] = []
@export var chests: Array[ChestData] = []
@export var chestMax: int = 15
@export var savedGold: int = 0

@export var stats: Dictionary = {
	"kills": {},
	"deaths": 0,
	"totalGoldEarned": 0,
}

@export var discoveredRecipes: Array[String] = []

@export var equippedWeapon: Dictionary = {
	"name": "Crude Blade",
	"instanceId": "crud_6993_003b6df2",
	"slot": "weapon",
	"setName": "",
	"hpBonus": 0,
	"atkBonus": 4,
	"defBonus": 0,
	"effects": {},
	"grade": "",
	"gradeHpBonus": 0,
	"gradeEffects": {},
	"enhancement": 0,
	"effectType": "none",
	"effectValue": 0,
	"effectChance": 0,
	"isEquipment": true,
	"qty": 1
}
@export var equippedShield: Dictionary = {
	"name": "Wooden Shield",
	"instanceId": "wood_230a_003b6df9",
	"slot": "shield",
	"setName": "",
	"hpBonus": 0,
	"atkBonus": 0,
	"defBonus": 5,
	"effects": {},
	"grade": "",
	"gradeHpBonus": 0,
	"gradeEffects": {},
	"enhancement": 0,
	"effectType": "none",
	"effectValue": 0,
	"effectChance": 0,
	"isEquipment": true,
	"qty": 1
}
@export var equippedArmor: Dictionary = {
	"name": "Leather Armor",
	"instanceId": "leat_e037_003b6de3",
	"slot": "armor",
	"setName": "",
	"hpBonus": 15,
	"atkBonus": 0,
	"defBonus": 0,
	"effects": {},
	"grade": "",
	"gradeHpBonus": 0,
	"gradeEffects": {},
	"enhancement": 0,
	"effectType": "none",
	"effectValue": 0,
	"effectChance": 0,
	"isEquipment": true,
	"qty": 1
}
@export var equippedHelmet: Dictionary = {
	"name": "Leather Helmet",
	"instanceId": "leat_751d_003b6ddb",
	"slot": "helmet",
	"setName": "",
	"hpBonus": 5,
	"atkBonus": 0,
	"defBonus": 0,
	"effects": {},
	"grade": "",
	"gradeHpBonus": 0,
	"gradeEffects": {},
	"enhancement": 0,
	"effectType": "none",
	"effectValue": 0,
	"effectChance": 0,
	"isEquipment": true,
	"qty": 1
}
@export var equippedLegs: Dictionary = {
	"name": "Leather Legs",
	"instanceId": "leat_2181_003b6dea",
	"slot": "legs",
	"setName": "",
	"hpBonus": 10,
	"atkBonus": 0,
	"defBonus": 0,
	"effects": {},
	"grade": "",
	"gradeHpBonus": 0,
	"gradeEffects": {},
	"enhancement": 0,
	"effectType": "none",
	"effectValue": 0,
	"effectChance": 0,
	"isEquipment": true,
	"qty": 1
}
@export var equippedBoots: Dictionary = {
	"name": "Leather Boots",
	"instanceId": "leat_b400_003b6dcc",
	"slot": "boots",
	"setName": "",
	"hpBonus": 0,
	"atkBonus": 0,
	"defBonus": 0,
	"effects": {
		"dodge": 0.02
	},
	"grade": "",
	"gradeHpBonus": 0,
	"gradeEffects": {},
	"enhancement": 0,
	"effectType": "none",
	"effectValue": 0,
	"effectChance": 0,
	"isEquipment": true,
	"qty": 1
}
@export var equippedRing: Dictionary = {}
@export var equippedAmulet: Dictionary = {}

@export_category("Expeditions")
@export var isExpeditionActive: bool = false
@export var expeditionArea: String = ""
@export var expeditionStartTimestamp: int = 0
@export var expeditionEndTimestamp: int = 0
@export var expeditionDurationMinutes: int = 0
@export var expeditionTimeline: Array[Dictionary] = []
@export var expeditionProgressIndex: int = -1
@export var expeditionHealth: int = 50
@export var expeditionInventory: Array[Dictionary] = []
@export var pendingExpeditionGold: int = 0
@export var equippedExpeditionBoots: Dictionary = {}

@export_category("Bazaar")
@export var equippedStand: Dictionary = {}
@export var equippedLock: Dictionary = {}
@export var equippedScale: Dictionary = {}

@export_category("General")
@export var loot_inventory:Dictionary = {
}
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
	"slot2": null,
	"slot3": null,
	"slot4": null,
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
@export var slot_progress = { 
	"slot1": 0, 
	"slot2": 0,
	"slot3": 0,
	"slot4": 0,
	"slot5": 0,
	"slot6": 0
}
@export var unlocked_monster_families = {
	"area1": false,
	"area2": false,
	"area3": false,
	"area4": false,
	"area5": false
}
@export var rested_data := {
	"active_buff": "",        # "health", "power", "focus", "xp", or ""
	"battles_left": 0,        # 0–10
	"charges": 0,             # 0–10
	"last_logout_time": 0,     # Unix timestamp
	"minutes_per_charge": 60,
	"max_charges": 10
}

@export var available_ap:int = 0
@export var base_stats:Dictionary = { "health": 10, "focus": 10, "power": 10, "luck": 10 }
@export var allocated_stats:Dictionary = { "health": 0, "focus": 0, "power": 0, "luck": 0 }
@export var blessing_coins:int = 0
@export var prestige_level:int = 0
@export var prestige_unlocked:bool = false

@export_category("Focus Chamber")
@export var focus_chamber_trial_highscore:int=0
@export var focus_chamber_practice_easy_highscore:int=0
@export var focus_chamber_practice_med_highscore:int=0
@export var focus_chamber_practice_hard_highscore:int=0
@export var focus_chamber_time_available:int=0
@export var last_focus_chamber_summary:Array = []

@export_category("Stats")
@export var highest_level_reached:int = 0
@export var total_blessing_coins_earned:int = 0
@export var total_exp_lifetime: int = 0
@export var total_gold_lifetime: int = 0
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

@export_category("Upgrades")
@export var element_upgrades := {
	"arcane": 0,
	"earth": 0,
	"electric": 0,
	"fire": 0,
	"ice": 0
}

@export_category("Settings")
@export var grid_opacity:float = 1.0 # from 0.0 to 1.0
@export var grid_y_pos_offset:float = 0.0
@export var two_tap_attack:bool = false
@export var fast_mode:bool = false
@export var player_screenshake:bool = true
@export var enemy_screenshake:bool = true
@export var rune_particles:bool = true
@export var damaged_flash:bool = true

func reset_settings() -> void:
	grid_opacity = 1.0
	grid_y_pos_offset = 0.0
	two_tap_attack = false
	fast_mode = false
	player_screenshake = true
	enemy_screenshake = true
	rune_particles = true
	damaged_flash = true

func add_loot(loot_item: LootItem, qty:int):
	if not loot_inventory.has(loot_item.name):
		loot_inventory[loot_item.name] = 0
	loot_inventory[loot_item.name] += qty
func add_loot_by_name(loot_name: String, qty:int):
	if not loot_inventory.has(loot_name):
		loot_inventory[loot_name] = 0
	loot_inventory[loot_name] += qty

func remove_loot_from_inventory(loot_item: LootItem, qty:int) -> int:
	loot_inventory[loot_item.name] -= qty
	if (loot_inventory[loot_item.name] <= 0):
		loot_inventory.erase(loot_item.name)
		return 0
	
	return loot_inventory[loot_item.name]

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
	slot_progress[slot_label] = 0

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

func get_ascension_level(offset:int=0) -> int:
	return 40 + ((prestige_level + offset) * 10)

func check_prestige_unlocked() -> bool:
	prestige_unlocked = current_level >= get_ascension_level()
	return prestige_unlocked

func ascension_restart_data() -> void:
	var starter_rune_pack:Dictionary = { # Start pack
			"Arcane Cross": 100,
			"Arcane Explosion": 80,
			"Arcane Strike": 250,
			"Light Healing": 25
		}
	
	var inheritance_active: bool = is_blessing_active("inheritance1_5")
	if (inheritance_active):
		var carryover := {}
		for rune_name in rune_inv.keys():
			var original_amount = rune_inv[rune_name]
			var inherited_amount := int(original_amount * 0.05)  # 5% carryover
			carryover[rune_name] = inherited_amount
		
		# Build the new rune inventory fresh from the starter_rune_pack
		rune_inv = starter_rune_pack

		# Apply carryover to the new rune inventory
		# Carry over may have all other types of runes, so check for the name so that we can add them without errors
		for rune_name in carryover.keys():
			if !(rune_inv.has(rune_name)):
				rune_inv[rune_name] = 0
			rune_inv[rune_name] += carryover[rune_name]
	else:
		rune_inv = starter_rune_pack
	
	total_blessing_coins_earned += current_level 
	current_level = 1
	total_exp_lifetime += int(total_exp) # In the stats panel it can be a sum of these 2
	total_exp = 0 
	current_exp = 0
	total_gold_lifetime += int(total_gold)
	total_gold = 0
	current_gold = 0
	var inner_reservoir:bool = is_blessing_active("essence_package")
	var ess_num:int = 1500 if (inner_reservoir) else 0
	total_essences = {
		"arcane": ess_num,
		"fire": ess_num,
		"ice": ess_num,
		"earth": ess_num,
		"electric": ess_num
	}
	current_essences = {
		"arcane": ess_num,
		"fire": ess_num,
		"ice": ess_num,
		"earth": ess_num,
		"electric": ess_num
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
	slot_progress = { 
		"slot1": 0, 
		"slot2": 0,
		"slot3": 0,
		"slot4": 0,
		"slot5": 0,
		"slot6": 0
	}
	unlocked_monster_families = {
		"area1": false,
		"area2": false,
		"area3": false,
		"area4": false,
		"area5": false
	}
	available_ap = 0
	base_stats = { "health": 10, "focus": 10, "power": 10, "luck": 10 }
	allocated_stats = { "health": 0, "focus": 0, "power": 0, "luck": 0 }
	
	# CURRENT STATS -- NOT TOTAL ACROSS ALL RUNS
	current_run_runes_obtained = {}
	total_run_monster_kills = {}
	prestige_level += 1
	prestige_unlocked = false

func reset_data() -> void:
	rune_inv = { # Start pack
		"Arcane Cross": 100,
		"Arcane Explosion": 80,
		"Arcane Strike": 250,
		"Light Healing": 25
	}
	current_level = 1
	total_exp = 0 
	current_exp = 0
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
	slot_progress = { 
		"slot1": 0, 
		"slot2": 0,
		"slot3": 0,
		"slot4": 0,
		"slot5": 0,
		"slot6": 0
	}
	unlocked_monster_families = {
		"area1": false,
		"area2": false,
		"area3": false,
		"area4": false,
		"area5": false
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
	
	blessing_coins = 0
	prestige_level = 0
	prestige_unlocked = false
	
	highest_level_reached = 0
	total_blessing_coins_earned = 0
	total_exp_lifetime = 0
	total_gold_lifetime = 0
	
	element_upgrades = {
		"arcane": 0,
		"earth": 0,
		"electric": 0,
		"fire": 0,
		"ice": 0
	}
	
	last_crafting_timestamp = 0
	focus_chamber_trial_highscore = 0
	focus_chamber_practice_easy_highscore = 0
	focus_chamber_practice_med_highscore = 0
	focus_chamber_practice_hard_highscore = 0
	focus_chamber_time_available = 0
	
	reset_settings()
	reset_blessings()
	reset_curses()

func is_blessing_active(blessing_name:String) -> bool:
	for blessing in blessings:
		if (blessing["id"] == blessing_name):
			return blessing["toggled"]
	
	return false

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
		locked = true,
		cost = 40,
		type = "offline",
		category = "runes"
	},
	{
		id = "essence_package",
		name = "Inner Reservoir",
		desc = "Begin each ascension run with 1,500 essence of every type.",
		toggled = false,
		locked = true,
		cost = 50,
		type = "economy",
		category = "essence"
	},
	{
		id = "mod_gold-20",
		name = "Pick Pocket",
		desc = "Earn 20% more gold from defeated monsters.",
		toggled = false,
		locked = true,
		cost = 70,
		type = "economy",
		category = "gold"
	},
	{
		id = "extra_rune_slot",
		name = "Extra Channel",
		desc = "+1 rune slot available in battle.",
		toggled = false,
		locked = true,
		cost = 100,
		type = "combat",
		category = "buff"
	},
	{
		id = "mod_essences-10",
		name = "Channeler",
		desc = "Earn 10% more essences from defeated monsters.",
		toggled = false,
		locked = true,
		cost = 30,
		type = "economy",
		category = "essence"
	},
	{
		id = "mod_essences-15",
		name = "Grand Channeler",
		desc = "Earn 15% more essences from defeated monsters.",
		toggled = false,
		locked = true,
		cost = 50,
		type = "economy",
		category = "essence"
	},
	{
		id = "mod_exp-15",
		name = "Student",
		desc = "Earn 15% more exp from defeated monsters.",
		toggled = false,
		locked = true,
		cost = 40,
		type = "economy",
		category = "exp"
	},
	{
		id = "mod_exp-20",
		name = "Scholar",
		desc = "Earn 20% more exp from defeated monsters.",
		toggled = false,
		locked = true,
		cost = 95,
		type = "economy",
		category = "exp"
	},
	{
		id = "mod_rested-battle-4",
		name = "Lasting Rest",
		desc = "Your restfulness lasts longer, extending the duration of your max rested blessing by 4.",
		toggled = false,
		locked = true,
		cost = 35,
		type = "economy",
		category = "exp"
	},
	{
		id = "mod_rested-battle-6",
		name = "Deep Restoration",
		desc = "Your restorative energy runs deeper, further extending the number of max rested blessing by 6.",
		toggled = false,
		locked = true,
		cost = 70,
		type = "economy",
		category = "exp"
	},
	{
		id = "inheritance1_5",
		name = "Inheritance",
		desc = "Start each ascension run with 5% of your rune inventory.",
		toggled = false,
		locked = true,
		cost = 40,
		type = "stat",
		category = "runes"
	}
]
@export var curses:Array = [
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
		id = "arcane_debuff-15",
		name = "Arcane Fracture",
		desc = "Your arcane spells deal 15% less damage.",
		toggled = false,
		type = "combat",
		category = "debuff"
	},
	{
		id = "mod_hp-25",
		name = "Bloodthirst",
		desc = "Monsters spawn with 25% more health.",
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
		id = "mod_exp_gold-10",
		name = "Stubborn",
		desc = "Earn 10% less exp from defeated monsters.",
		toggled = false,
		type = "economy",
		category = "exp"
	},
]

func reset_blessings() -> void:
	for blessing in blessings:
		blessing['toggled'] = false
		blessing['locked'] = true

func reset_curses() -> void:
	for curse in curses:
		curse['toggled'] = false
