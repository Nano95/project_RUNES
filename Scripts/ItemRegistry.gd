extends Node

var items: Dictionary = {}
var equipmentDefs: Dictionary = {}

func _ready() -> void:
	_register()

const STACK_CAPS: Dictionary = {
	"part":       30,
	"ore":        20,
	"forageable": 20,
	"wood":       10,
	"potion":     10,
	"equipment":  1,
	"summon": 1  # can only carry one at a time
}

func getStackCap(itemName: String) -> int:
	var item = getItem(itemName)
	if not item:
		return 1
	return STACK_CAPS.get(item.itemType, 1)

func _register() -> void:
	# Starter gear — no grade, no set
	_equip("Crude Blade",    "weapon", "", 0, 4,  0, 0.0,  "A crude blade.",              20)
	_equip("Wooden Shield",  "shield", "", 0, 0,  5, 0.0,  "Better than nothing.",        30)
	_equip("Leather Helmet", "helmet", "", 5, 0,  0, 0.0,  "A simple leather helm.",      20)
	_equip("Leather Armor",  "armor",  "", 15, 0, 0, 0.0,  "Basic leather protection.",   35)
	_equip("Leather Legs",   "legs",   "", 10, 0, 0, 0.0,  "Simple leather leggings.",    25)
	_equip("Leather Boots",  "boots",  "", 0,  0, 0, 0.02, "Worn leather boots.",         20)
	
	# Orc Set (Hunting Grounds)
	_equip("Orc Helmet",        "helmet",  "Orc",   15, 0, 0,  0.0,  "Forged from orc bone.",         80)
	_equip("Orc Armor",         "armor",   "Orc",   35, 0, 0,  0.0,  "Heavy orcish plate.",           120)
	_equip("Orc Legs",          "legs",    "Orc",   20, 0, 0,  0.0,  "Crude but sturdy.",             80)
	_equip("Orc Boots",         "boots",   "Orc",   10, 0, 0,  0.03, "Grants access to Orc lands.",   60)
	# Orc weapons and shield
	_equip("Orcish Axe",        "weapon",  "",      0, 10, 0,  0.0,  "A crude but heavy axe.",        40)
	_equip("Orc King Shield",   "shield",  "",      0,  0, 8,  0.0,  "A gleaming shield of the Orc King.",       150)
	# Orc monster part drops
	_add("Orc Leather",       "part", true,  0.3, "Rough orcish hide.",           10)
	_add("Orc General Crest", "part", true,  0.2, "Mark of an Orc General.",      55)
	_add("King's Tusk",       "part", true,  0.3, "A massive orc tusk.",          80)
	_add("Warchief Totem", "summon", false, 0.5, "Summons the Orc King. Use in the field.", 500)
	
	# ── FORAGEABLES ───────────────────────────────────────
	_add("Wild Herb",           "forageable", true,  0.5, "Common but useful.",               5)
	_add("Red Berry",           "forageable", true,  0.5, "Sweet and slightly toxic.",        4)
	_add("Bloodroot",           "forageable", true,  0.5, "Deep red root.",                   8)
	_add("Gloomcap",            "forageable", true,  0.5, "A dark mushroom.",                 10)

	# ── ORES ─────────────────────────────────────────────
	_add("Copper Ore",          "ore",        true,  1.5, "Common metal ore.",                8)
	_add("Iron Ore",            "ore",        true,  1.8, "Heavy and valuable.",              15)
	_add("Coal",                "ore",        true,  1.6, "Burns long and hot.",              10)
	_add("Gold Ore",        "ore",       true,  1.2, "Heavy and precious.",               35)

	# ── BARS ─────────────────────────────────────────────
	_add("Copper Bar", "ore", true, 0.8, "Smelted copper.",     15)
	_add("Iron Bar",   "ore", true, 1.0, "Smelted iron.",       25)
	_add("Gold Bar",   "ore", true, 1.2, "Smelted gold.",       60)

	# ── POTIONS ──────────────────────────────────────────
	_add("Berry Extract",       "potion",     true,  2.3, "Restores 15 HP.",                  10)
	_add("Minor Health Potion",   "potion",     true,  2.3, "Restores 20 HP.",                  15)
	_add("Health Potion",       "potion",     true,  2.8, "Restores 30 HP.",                  20)
	_add("Twilight Potion",     "potion",     true,  5.0, "Restores 70 HP.",                  55)

	_add("Minor Battle Potion", "potion",     true, 2.3, "Attracts monsters for 3 events.",   25)
	_add("Battle Potion",       "potion",     true, 2.3, "Attracts monsters for 6 events.",   45)
	_add("Great Battle Potion", "potion",     true, 2.3, "Attracts monsters for 10 events.",  80)
	
	_add("Minor Foraging Potion", "potion", true, 2.3, "Increases forageable encounters for 3 events.",  20)
	_add("Foraging Potion",       "potion", true, 2.3, "Increases forageable encounters for 6 events.",  35)
	_add("Great Foraging Potion", "potion", true, 2.3, "Increases forageable encounters for 10 events.", 60)

func _add(itemName: String, itemType: String, stackable: bool, weight: float, description: String, value: int) -> void:
	var item = ItemData.new()
	item.itemName = itemName
	item.itemType = itemType
	item.stackable = stackable
	item.weight = weight
	item.description = description
	item.value = value
	items[itemName] = item

func getItem(itemName: String) -> ItemData:
	return items.get(itemName, null)

func getWeight(itemName: String) -> float:
	var item = getItem(itemName)
	return item.weight if item else 0.0

func getType(itemName: String) -> String:
	var item = getItem(itemName)
	return item.itemType if item else ""

func isStackable(itemName: String) -> bool:
	var item = getItem(itemName)
	return item.stackable if item else false

# _equip registers an item in the equipmentDefs (definitions) dictionary
# it covers equipment-specific properties that only gear needs:
func _equip(itemName: String, slot: String, setName: String, 
			hpBonus: int, atkBonus: int, defBonus: int, 
			dodgeBonus: float, description: String, value: int) -> void:
	var e = EquipmentData.new()
	e.itemName = itemName
	e.slot = slot
	e.setName = setName
	e.hpBonus = hpBonus
	e.atkBonus = atkBonus
	e.defBonus = defBonus
	e.dodgeBonus = dodgeBonus
	e.description = description
	e.value = value
	equipmentDefs[itemName] = e
	_add(itemName, "equipment", false, _getEquipWeight(slot), description, value)

func _getEquipWeight(slot: String) -> float:
	match slot:
		"weapon": return 6.0
		"shield": return 4.5
		"armor":  return 6.0
		"helmet": return 3.5
		"boots":  return 1.0
		"ring":   return 0.1
		"amulet": return 0.1
		_:        return 1.0

func getEquipmentDef(itemName: String) -> EquipmentData:
	return equipmentDefs.get(itemName, null)

func rollEquipmentInstance(itemName: String, graded: bool = false) -> Dictionary:
	var def = getEquipmentDef(itemName)
	if not def:
		return {}

	# Roll grade if looted
	var grade = ""
	var gradeBonus = 0
	if graded:
		var roll = randf()
		if roll < 0.10:
			grade = "S"
			gradeBonus = 15
		elif roll < 0.40:
			grade = "A"
			gradeBonus = 10
		else:
			grade = "B"
			gradeBonus = 5

	return {
		"name": itemName,
		"instanceId": "%s_%s" % [itemName.left(4).to_lower().replace(" ", ""),
					   "%04x" % randi_range(0, 65535)],
		"slot": def.slot,
		"setName": def.setName,
		"hpBonus": def.hpBonus,
		"atkBonus": def.atkBonus,
		"defBonus": def.defBonus,
		"dodgeBonus": def.dodgeBonus,
		"grade": grade,
		"gradeBonus": gradeBonus,
		"enhancement": 0,
		"effectType": def.effectType,
		"effectValue": def.effectValue,
		"effectChance": def.effectChance,
		"isEquipment": true,
		"qty": 1
	}
