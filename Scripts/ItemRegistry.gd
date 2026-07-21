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
}

func getStackCap(itemName: String) -> int:
	var item = getItem(itemName)
	if not item:
		return 1
	return STACK_CAPS.get(item.itemType, 1)

func _register() -> void:

	_equip("Wooden Shield",      "shield", false, "defense", 1, 2, "none", 0, 0.0, "Better than nothing.",         30)
	_equip("Crude Blade",       "weapon", false, "attack",  1,  3,  "none",           0,    0.0,  "A crude blade.",                20)
	_equip("Orcish Axe",        "weapon", false, "attack",  3,  6,  "none",           0,    0.0,  "A crude but heavy axe.",        40)
	_equip("Bandit Blade",      "weapon", false, "attack",  2,  5,  "none",           0,    0.0,  "Notched but sharp.",            35)
	_equip("Rusty Sword",       "weapon", false, "attack",  0,  1,  "none",           0,    0.0,  "Barely holds an edge.",         15)
	_equip("Fang Spear",        "weapon", false, "attack",  4,  7,  "none",           0,    0.0,  "Tipped with a creature fang.",  55)
	_equip("Giant Club",        "weapon", true,  "attack",  5,  9,  "none",           0,    0.0,  "Impossibly heavy.",             55)
	_equip("War Hammer",        "weapon", true,  "attack",  6,  10, "none",           0,    0.0,  "Crushes bone and armor alike.", 80)
	_equip("Shaman Staff",      "weapon", true,  "attack",  4,  7,  "none",           0,    0.0,  "Humming with dark energy.",     65)
	_equip("Bark Shield",       "shield", false, "defense", 3,  5,  "none",           0,    0.0,  "Carved from ancient wood.",     85)
	_equip("Reinforced Shield", "shield", false, "defense", 2,  4,  "none",           0,    0.0,  "Solid and dependable.",         50)
	_equip("Cursed Shield",     "shield", false, "defense", 3,  5,  "cursed_block",   70,   1.0,  "Something is wrong with it.",   75)
	_equip("Leather Armor",     "armor",  false, "defense", 2,  4,  "none",           0,    0.0,  "Basic leather protection.",     45)
	_equip("Shadow Armor",      "armor",  false, "defense", 6,  10, "none",           0,    0.0,  "Absorbs light.",                110)
	_equip("Banshee Veil",      "armor",  false, "defense", 2,  4,  "none",           0,    0.0,  "Woven from wailing spirits.",   120)
	_equip("Iron Helmet",       "helmet", false, "defense", 1,  3,  "none",           0,    0.0,  "Simple but sturdy.",            25)
	_equip("Leather Helmet",    "helmet", false, "defense", 1,  2,  "none",           0,    0.0,  "A simple leather helm.",        30)
	_equip("Elven Helmet",      "helmet", false, "defense", 2,  4,  "none",           0,    0.0,  "Light and finely crafted.",     70)
	_equip("Dark Knight Helm",  "helmet", false, "defense", 4,  7,  "none",           0,    0.0,  "Forged in shadow.",             90)
	_equip("Reinforced Boots",  "boots",  false, "defense", 1,  3,  "none",           0,    0.0,  "Sturdy and well-made.",         55)
	# Rings and amulets — no stat type, effect driven
	_equip("Ring of Protection", "ring",   false, "defense", 1, 2, "none", 0, 0.0, "A plain ring, solid defense.", 80)
	_equip("Ring of Vitality",  "ring",   false, "none",    0,  0,  "checkpoint_heal",10,   1.0,  "Pulses with warm energy.",      200)
	_equip("Ring of Greed",     "ring",   false, "none",    0,  0,  "gold_bonus",     15,   1.0,  "Smells faintly of coin.",       180)
	_equip("Ring of Wisdom",    "ring",   false, "none",    0,  0,  "xp_bonus",       15,   1.0,  "Hums with ancient knowledge.",  180)
	_equip("Amulet of Regen",   "amulet", false, "none",    0,  0,  "regen",          2,    1.0,  "Slowly restores vitality.",     220)

	# ── MONSTER PARTS ─────────────────────────────────────
	# ── SHARED MATERIALS ─────────────────────────────────────
	_add("Creature Fang",   "part",      true,  0.1, "A fang from a wild creature.",      8)
	_add("Beast Skin",      "part",      true,  0.3, "Rough skin from a beast.",          10)
	_add("Giant Fang",      "part",      true,  0.2, "A large curved fang.",              15)
	_add("Orc Tooth",       "part",      true,  0.2, "Yellowed and cracked.",             8)
	_add("Dark Essence",    "part",      true,  0.1, "A fragment of dark energy.",        45)
	_add("Cloth",           "part",      true,  0.2, "Coarse woven fabric.",              6)

	# ── HUNTING GROUNDS ───────────────────────────────────────
	_add("Rat Tail",        "part",      true,  0.1, "A scaly rat tail.",                 5)
	_add("Slime Gel",       "part",      true,  0.3, "Sticky green gel.",                 6)
	_add("Bat Wing",        "part",      true,  0.2, "A leathery bat wing.",              7)
	_add("Frog Leg",        "part",      true,  0.3, "Slimy but valuable.",               8)
	_add("Royal Slime Core","part",      true,  0.8, "Pulsing with strange energy.",      120)

	# ── OUTSKIRTS ─────────────────────────────────────────────
	_add("Cyclops Eye",     "part",      true,  0.5, "Still staring.",                    40)
	_add("Leather Armor",   "equipment", false, 3.5, "Basic leather protection.",         45)
	_add("Leather Helmet",  "equipment", false, 2.0, "A simple leather helm.",            30)
	_add("Shaman Staff",    "equipment", false, 2.0, "Humming with dark energy.",         65)
	_add("Copper Ore",      "ore",       true,  0.5, "Common metal ore.",                 8)
	_add("Iron Ore",        "ore",       true,  0.8, "Heavy and valuable.",               15)
	_add("Coal",            "ore",       true,  0.6, "Burns long and hot.",               10)
	_add("Gold Ore",        "ore",       true,  1.2, "Heavy and precious.",               35)
	_add("War Hammer",      "equipment", false, 5.0, "Crushes bone and armor alike.",     80)
	_add("Reinforced Boots","equipment", false, 2.5, "Sturdy and well-made.",             55)

	# ── DARKWOOD FOREST ───────────────────────────────────────
	_add("Elven Helmet",    "equipment", false, 1.5, "Light and finely crafted.",         70)
	_add("Spider Silk",     "part",      true,  0.2, "Stronger than steel.",              30)
	_add("Bark Shield",     "equipment", false, 3.5, "Carved from ancient wood.",         85)
	_add("Banshee Veil",    "equipment", false, 1.0, "Woven from wailing spirits.",       120)

	# ── FORAGEABLES ───────────────────────────────────────
	_add("Wild Herb",           "forageable", true,  0.5, "Common but useful.",               5)
	_add("Red Berry",           "forageable", true,  0.5, "Sweet and slightly toxic.",        4)
	_add("Bloodroot",           "forageable", true,  0.5, "Deep red root.",                   8)
	_add("Gloomcap",            "forageable", true,  0.5, "A dark mushroom.",                 10)

	# ── ORES ─────────────────────────────────────────────
	_add("Copper Ore",          "ore",        true,  1.5, "Common metal ore.",                8)
	_add("Iron Ore",            "ore",        true,  1.8, "Heavy and valuable.",              15)
	_add("Coal",                "ore",        true,  1.6, "Burns long and hot.",              10)
	_add("Tin Ore",             "ore",        true,  1.5, "Useful for alloys.",               12)

	# ── WOOD ─────────────────────────────────────────────
	_add("Oak Log",             "ore",        true,  5.0, "Sturdy hardwood.",                 10)
	_add("Pine Wood",           "ore",        true,  3.8, "Light and workable.",              8)
	_add("Dark Timber",         "ore",        true,  6.2, "Dense and dark grained.",          18)

	# ── POTIONS ──────────────────────────────────────────
	_add("Berry Extract",       "potion",     true,  2.3, "Restores 15 HP.",                  10)
	_add("Minor Health Potion",   "potion",     true,  2.3, "Restores 20 HP.",                  15)
	_add("Health Potion",       "potion",     true,  2.8, "Restores 30 HP.",                  20)
	_add("Strong Heal Potion",  "potion",     true,  3.4, "Restores 50 HP.",                  35)
	#_add("Herbal Elixir",       "potion",     true,  3.8, "Restores 60 HP.",                  45)
	_add("Twilight Potion",     "potion",     true,  5.0, "Restores 70 HP.",                  55)
	_add("Minor Battle Potion", "potion",     true, 2.3, "Attracts monsters for 3 events.",   25)
	_add("Battle Potion",       "potion",     true, 2.3, "Attracts monsters for 6 events.",   45)
	_add("Great Battle Potion", "potion",     true, 2.3, "Attracts monsters for 10 events.",  80)

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
func _equip(itemName: String, slot: String, twoHanded: bool, statType: String,
			statMin: int, statMax: int, effectType: String, effectValue: int,
			effectChance: float, description: String, value: int) -> void:
	var e = EquipmentData.new()
	e.itemName = itemName
	e.slot = slot
	e.twoHanded = twoHanded
	e.statType = statType
	e.statMin = statMin
	e.statMax = statMax
	e.effectType = effectType
	e.effectValue = effectValue
	e.effectChance = effectChance
	e.description = description
	e.value = value
	equipmentDefs[itemName] = e
	print("equipment defs count: ", equipmentDefs.size())
	# Also register in items dict for weight/type lookup
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

func rollEquipmentInstance(itemName: String) -> Dictionary:
	var def = getEquipmentDef(itemName)
	if not def:
		return {}
	var bonus = randi_range(def.statMin, def.statMax) if def.statMax > 0 else 0
	return {
		"name": itemName,
		"instanceId": "%s_%s" % [itemName.left(4).to_lower().replace(" ", ""), 
					   "%04x" % randi_range(0, 65535)],
		"slot": def.slot,
		"twoHanded": def.twoHanded,
		"statType": def.statType,
		"statBonus": bonus,
		"enhancement": 0,
		"effectType": def.effectType,
		"effectValue": def.effectValue,
		"effectChance": def.effectChance,
		"isEquipment": true,
		"qty": 1
	}
