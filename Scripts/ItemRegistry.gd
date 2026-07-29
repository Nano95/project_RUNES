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

	# CRAFT EQUIPS
	_equip("Copper Legs", "legs", false, "defense", 1, 3, "none", 0, 0.0, "Sturdy copper leggings.", 40)
	_equip("Iron Legs",   "legs", false, "defense", 2, 4, "none", 0, 0.0, "Reliable iron leggings.", 70)
	_equip("Golden Legs", "legs", false, "defense", 4, 6, "none", 0, 0.0, "Gleaming golden leggings.", 110)
	_equip("Copper Sword", "weapon", false, "attack",  1, 3,  "none", 0, 0.0, "A solid copper blade.", 45)
	_equip("Iron Sword",   "weapon", false, "attack",  3, 5,  "none", 0, 0.0, "A reliable iron sword.", 75)
	_equip("Iron Shield",  "shield", false, "defense", 3, 5,  "none", 0, 0.0, "A sturdy iron shield.",  65)
	_equip("Golden Armor",  "armor", false, "defense", 5, 7,  "none", 0, 0.0, "A gleaming gold armor.",  90)
	_equip("Orc Helmet",   "helmet", false, "defense", 3, 6,  "none", 0, 0.0, "Crude but effective.",   80)
	_equip("Fang Spear",        "weapon", false, "attack",  4,  7,  "none",           0,    0.0,  "Tipped with a creature fang.",  55)
	
	_equip("Wooden Shield",      "shield", false, "defense", 1, 2, "none", 0, 0.0, "Better than nothing.",         30)
	_equip("Crude Blade",       "weapon", false, "attack",  2,  2,  "none",           0,    0.0,  "A crude blade.",                20)
	_equip("Orcish Axe",        "weapon", false, "attack",  2,  4,  "none",           0,    0.0,  "A crude but heavy axe.",        40)
	_equip("Giant Club",        "weapon", true,  "attack",  5,  9,  "none",           0,    0.0,  "Impossibly heavy.",             55)
	_equip("War Hammer",        "weapon", true,  "attack",  8,  12, "none",           0,    0.0,  "Crushes bone and armor alike.", 80)
	_equip("Shaman Staff",      "weapon", true,  "attack",  6,  8,  "none",           0,    0.0,  "Humming with dark energy.",     65)
	_equip("Bark Shield",       "shield", false, "defense", 4,  7,  "none",           0,    0.0,  "Carved from ancient wood.",     85)
	_equip("Reinforced Shield", "shield", false, "defense", 2,  4,  "none",           0,    0.0,  "Solid and dependable.",         50)
	_equip("Cursed Shield",     "shield", false, "defense", 5,  8,  "cursed_block",   70,   1.0,  "Something is wrong with it.",   75)
	_equip("Leather Armor",     "armor",  false, "defense", 2,  4,  "none",           0,    0.0,  "Basic leather protection.",     45)
	_equip("Shadow Armor",      "armor",  false, "defense", 6,  10, "none",           0,    0.0,  "Absorbs light.",                110)
	_equip("Banshee Veil",      "armor",  false, "defense", 2,  4,  "none",           0,    0.0,  "Woven from wailing spirits.",   120)
	_equip("Iron Helmet",       "helmet", false, "defense", 2,  3,  "none",           0,    0.0,  "Simple but sturdy.",            25)
	_equip("Leather Helmet",    "helmet", false, "defense", 1,  2,  "none",           0,    0.0,  "A simple leather helm.",        30)
	_equip("Elven Helmet",      "helmet", false, "defense", 2,  4,  "none",           0,    0.0,  "Light and finely crafted.",     70)
	_equip("Dark Knight Helm",  "helmet", false, "defense", 4,  7,  "none",           0,    0.0,  "Forged in shadow.",             90)
	_equip("Reinforced Boots",  "boots",  false, "defense", 1,  3,  "none",           0,    0.0,  "Sturdy and well-made.",         55)
	
	_equip("Sword of Hollow", "weapon", false, "attack",  6,  9,  "none", 0, 0.0, "Whispers when swung.",           110)
	_equip("Gargoyle Armor",  "armor",  false, "defense", 5,  8,  "none", 0, 0.0, "Stone-hard and silent.",         120)
	_equip("Crested Shield",  "shield", false, "defense", 6,  9,  "none", 0, 0.0, "Bears a forgotten crest.",       150)
	_equip("Commander Helm",  "helmet", false, "defense", 5,  8,  "none", 0, 0.0, "Worn by those who led.",         100)
	_equip("Paladin Armor",   "armor",  false, "defense", 8,  12, "none", 0, 0.0, "Heavy but nearly impenetrable.", 180)
	_equip("King's Crown",    "helmet", false, "defense", 7,  10, "none", 0, 0.0, "Cold and terrible.",             300)
		
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
	_add("Hollow Shard",   "part", true, 0.3, "A fragment of something hollow.",     35)
	_add("Gargoyle Wing",  "part", true, 0.5, "Leathery and surprisingly light.",    40)
	_add("Stone Fragment", "part", true, 0.4, "Chipped from something ancient.",     20)
	_add("Priest Relic",   "part", true, 0.2, "Something unholy about it.",          45)
	_add("Bone Fragment",  "part", true, 0.2, "Brittle but useful.",                 15)
	_add("Paladin Crest",  "part", true, 0.2, "Heavy with former glory.",            80)

	# ── HUNTING GROUNDS ───────────────────────────────────────
	_add("Rat Tail",        "part",      true,  0.1, "A scaly rat tail.",                 5)
	_add("Slime Gel",       "part",      true,  0.3, "Sticky green gel.",                 6)
	_add("Bat Wing",        "part",      true,  0.2, "A leathery bat wing.",              7)
	_add("Frog Leg",        "part",      true,  0.3, "Slimy but valuable.",               8)
	_add("Royal Slime Core","part",      true,  0.8, "Pulsing with strange energy.",      120)

	# ── OUTSKIRTS ─────────────────────────────────────────────
	_add("Cyclops Eye",     "part",      true,  0.5, "Still staring.",                    40)
	
	# ── DARKWOOD FOREST ───────────────────────────────────────
	_add("Spider Silk",     "part",      true,  0.2, "Stronger than steel.",              30)

	# ── SUMONING ITEMS  ───────────────────────────────────────
	_add("Forsaken Seal",    "part", true,  0.3, "Radiates forgotten power.",        120)
	
	# ── FORAGEABLES ───────────────────────────────────────
	_add("Wild Herb",           "forageable", true,  0.5, "Common but useful.",               5)
	_add("Red Berry",           "forageable", true,  0.5, "Sweet and slightly toxic.",        4)
	_add("Bloodroot",           "forageable", true,  0.5, "Deep red root.",                   8)
	_add("Gloomcap",            "forageable", true,  0.5, "A dark mushroom.",                 10)
	_add("Deathbloom",       "forageable", true, 0.1, "A flower that blooms in death.",     25)
	_add("Nightshade",       "forageable", true, 0.1, "Poisonous. Handle with care.",       20)
	_add("Voidleaf",         "forageable", true, 0.1, "Withered and dark.",                 30)
	# ── ORES ─────────────────────────────────────────────
	_add("Copper Ore",          "ore",        true,  1.5, "Common metal ore.",                8)
	_add("Iron Ore",            "ore",        true,  1.8, "Heavy and valuable.",              15)
	_add("Coal",                "ore",        true,  1.6, "Burns long and hot.",              10)
	_add("Gold Ore",        "ore",       true,  1.2, "Heavy and precious.",               35)

	# ── BARS ─────────────────────────────────────────────
	_add("Copper Bar", "ore", true, 0.8, "Smelted copper.",     15)
	_add("Iron Bar",   "ore", true, 1.0, "Smelted iron.",       25)
	_add("Gold Bar",   "ore", true, 1.2, "Smelted gold.",       60)

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
	_add("Death Brew",         "potion", true, 3.0, "Restores 70 HP.",  50)
	_add("Shadow Tonic",       "potion", true, 3.2, "Restores 90 HP.",  65)
	_add("Nightshade Elixir",  "potion", true, 3.5, "Restores 110 HP.", 85)
	
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
