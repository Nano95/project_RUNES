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
	_equip("Crude Blade",    "weapon", "", 0,  4,  0, {},                    "A crude blade.",              20)
	_equip("Wooden Shield",  "shield", "", 0,  0,  5, {},                    "Better than nothing.",        30)
	_equip("Leather Helmet", "helmet", "", 5,  0,  0, {},                    "A simple leather helm.",      20)
	_equip("Leather Armor",  "armor",  "", 15, 0,  0, {},                    "Basic leather protection.",   35)
	_equip("Leather Legs",   "legs",   "", 10, 0,  0, {},                    "Simple leather leggings.",    25)
	_equip("Leather Boots",  "boots",  "", 0,  0,  0, {"dodge": 0.02},       "Worn leather boots.",         20)
	_equip("T0 Map", "expeditionMap", "", 0, 0, 0, {"unlocksArea": "Hunting Grounds"}, "A basic map of the Hunting Grounds.", 0)
	_equip("T0 Survival Gear", "survivalGear", "", 0, 0, 0, {"expeditionMinutes": 10}, "Basic survival pack.", 0)

	# Orc Set (Hunting Grounds)
	_equip("T1 Map", "expeditionMap", "", 0, 0, 0, {"unlocksArea": "Slime Swamps"},    "A map of the Slime Swamps.", 150)
	_equip("T1 Survival Gear", "survivalGear", "", 0, 0, 0, {"expeditionMinutes": 20}, "Reinforced survival pack.", 200)
	_equip("Orc Helmet",      "helmet", "Orc", 15, 0,  0, {},                "Forged from orc bone.",              80)
	_equip("Orc Armor",       "armor",  "Orc", 35, 0,  0, {},                "Heavy orcish plate.",                120)
	_equip("Orc Legs",        "legs",   "Orc", 20, 0,  0, {},                "Crude but sturdy.",                  80)
	_equip("Orc Boots",       "boots",  "Orc", 10, 0,  0, {"dodge": 0.03},   "Grants access to Orc lands.",        60)
	_equip("Orcish Axe",      "weapon", "",    0,  10, 0, {},                "A crude but heavy axe.",             40)
	_equip("Orc King Shield", "shield", "",    0,  0,  8, {},                "Shield of the Orc King.",            150)

	# Slimy Set (Slime Swamps)
	_equip("Slimy Helmet", "helmet", "Slimy", 6,  0, 0, {"poisonResistance": 0.08}, "Infused with swamp essence.",  80)
	_equip("Slimy Armor",  "armor",  "Slimy", 18, 0, 0, {"poisonResistance": 0.20}, "Resistant to poison.",         120)
	_equip("Slimy Legs",   "legs",   "Slimy", 8,  0, 0, {"poisonResistance": 0.15}, "Heavy with swamp mud.",        90)
	_equip("Slimy Boots",  "boots",  "Slimy", 8,  0, 0, {"dodge": 0.04},            "Grants access to Slime Swamps.", 70)
	_equip("Slimy Blade",  "weapon", "",      0, 17, 0, {},             "Coated in slime.",      60)
	_equip("Slimy Shield", "shield", "",      0,  0, 15, {},             "Hardens on impact.",    70)
	# Orc monster part drops
	_add("Orc Leather",       "part", true,  0.3, "Rough orcish hide.",           10)
	_add("Orc General Crest", "part", true,  0.2, "Mark of an Orc General.",      55)
	_add("King's Tusk",       "part", true,  0.3, "A massive orc tusk.",          80)
	_add("Warchief Totem", "summon", false, 0.5, "Summons the Orc King. Use in the field.", 500)
	
	# Slime Parts
	_add("Slime Gel",   "part", true, 0.2, "Sticky green gel.",          6)
	_add("Slime Core",  "part", true, 0.3, "Pulsing with slime energy.", 45)
	_add("Royal Gel",   "part", true, 0.3, "Fit for a slime king.",      80)

	# Sandling Set
	_equip("Sandling Helmet", "helmet", "Sandling", 22, 0,  0,  {},              "A hood worn by sandlings.",     90)
	_equip("Sandling Armor",  "armor",  "Sandling", 45, 0,  0,  {},              "Dense bone plating.",           140)
	_equip("Sandling Legs",   "legs",   "Sandling", 28, 0,  0,  {},              "Bone-reinforced leggings.",     100)
	_equip("Sandling Boots",  "boots",  "Sandling", 14, 0,  0,  {"dodge": 0.05}, "Silent in the sand.",           80)
	# Sandling weapons
	_equip("Sandling Blade",  "weapon", "", 0, 22, 0,  {},              "Carved from sandling remains.", 90)
	_equip("Sandling Shield", "shield", "", 0, 0,  20, {},              "Hardened bone shield.",         100)
	_equip("T2 Map", "expeditionMap", "", 0, 0, 0, {"unlocksArea": "Sandling Dunes"},    "A map of the Sandling Dunes.", 150)
	_equip("T2 Survival Gear", "survivalGear", "", 0, 0, 0, {"expeditionMinutes": 30}, "Hydrating survival pack.", 200)

	# Parts
	_add("Bone Dust",    "part", true,  0.2, "Fine dust from animated bones.",     8)
	_add("Crystal Bone", "part", true,  0.4, "Crystallized by dark magic.",        60)
	_add("Ancient Relic","part", true,  0.3, "Radiates dark energy.",             100)
	# Summon
	_add("Necromancer Totem", "summon", false, 0.5, "Summons the Mad Necromancer.", 300)
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
	_add("Twilight Potion",     "potion",     true,  5.0, "Restores 55 HP.",                  50)
	_add("Regen Potion",         "potion", true, 2.0, "Restores 50 HP over 5 ticks.",  60)
	#_add("Greater Regen Potion", "potion", true, 2.5, "Restores 125 HP over 5 ticks.", 100)
	_add("Minor Battle Potion", "potion",     true, 2.3, "Attracts monsters for 3 events.",   25)
	_add("Battle Potion",       "potion",     true, 2.3, "Attracts monsters for 6 events.",   45)
	_add("Great Battle Potion", "potion",     true, 2.3, "Attracts monsters for 10 events.",  80)
	
	_add("Minor Foraging Potion", "potion", true, 2.3, "Increases forageable encounters for 3 events.",  20)
	_add("Foraging Potion",       "potion", true, 2.3, "Increases forageable encounters for 6 events.",  35)
	_add("Great Foraging Potion", "potion", true, 2.3, "Increases forageable encounters for 10 events.", 60)
	_add("Minor Antidote",  "potion", true, 0.5, "Reduces poison by 10.", 30)
	_add("Antidote",        "potion", true, 0.5, "Reduces poison by 20.", 55)
	_add("Large Antidote",  "potion", true, 0.5, "Reduces poison by 30.", 80)

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

# _equip signature
func _equip(itemName: String, slot: String, setName: String,
			hpBonus: int, atkBonus: int, defBonus: int,
			effects: Dictionary, description: String, value: int) -> void:
	var e = EquipmentData.new()
	e.itemName = itemName
	e.slot = slot
	e.setName = setName
	e.hpBonus = hpBonus
	e.atkBonus = atkBonus
	e.defBonus = defBonus
	e.effects = effects
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

	var grade = ""
	var gradeHpBonus = 0
	var gradeBonus = 0  # for weapon ATK and shield DEF
	var gradeEffects = {}

	if (graded):
		var roll = randf()
		if roll < 0.03:
			grade = "SS"
			gradeHpBonus = 5
			gradeBonus = 5
			for effect in def.effects:
				gradeEffects[effect] = def.effects[effect] * 0.5
		elif roll < 0.13:
			grade = "S"
			gradeHpBonus = 3
			gradeBonus = 3
			for effect in def.effects:
				gradeEffects[effect] = def.effects[effect] * 0.375
		elif roll < 0.43:
			grade = "A"
			gradeHpBonus = 2
			gradeBonus = 2
			for effect in def.effects:
				gradeEffects[effect] = def.effects[effect] * 0.25
		else:
			grade = "B"
			gradeHpBonus = 1
			gradeBonus = 1
			for effect in def.effects:
				gradeEffects[effect] = def.effects[effect] * 0.125

	return {
		"name": itemName,
		"instanceId": "%s_%s_%s" % [
			itemName.left(4).to_lower().replace(" ", ""),
			"%04x" % randi_range(0, 65535),
			"%08x" % Time.get_ticks_usec()
		],
		"slot": def.slot,
		"setName": def.setName,
		"hpBonus": def.hpBonus,
		"atkBonus": def.atkBonus,
		"defBonus": def.defBonus,
		"effects": def.effects.duplicate(),
		"grade": grade,
		"gradeHpBonus": gradeHpBonus,
		"gradeBonus": gradeBonus,
		"gradeEffects": gradeEffects,
		"enhancement": 0,
		"effectType": def.effectType,
		"effectValue": def.effectValue,
		"effectChance": def.effectChance,
		"isEquipment": true,
		"qty": 1
	}

static func getSprite(itemName: String) -> Texture2D:
	var path = EQUIPMENT_SPRITES.get(itemName, "")
	if path == "":
		return null
	return load(path) as Texture2D

const EQUIPMENT_SPRITES: Dictionary = {
	# Starter
	"Crude Blade":    "res://Sprites/Equipment/CrudeBlade.png",
	"Wooden Shield":  "res://Sprites/Equipment/WoodenShield.png",
	"Leather Helmet": "res://Sprites/Equipment/LeatherHelmet.png",
	"Leather Armor":  "res://Sprites/Equipment/LeatherArmor.png",
	"Leather Legs":   "res://Sprites/Equipment/LeatherLegs.png",
	"Leather Boots":  "res://Sprites/Equipment/LeatherBoots.png",
	"T0 Map":         "res://Sprites/Equipment/T0Map.png",
	"T0 Survival Gear": "res://Sprites/Equipment/T0SurvivalGear.png",
	# Orc Set
	"Orc Helmet":     "res://Sprites/Equipment/OrcHelmet.png",
	"Orc Armor":      "res://Sprites/Equipment/OrcArmor.png",
	"Orc Legs":       "res://Sprites/Equipment/OrcLegs.png",
	"Orc Boots":      "res://Sprites/Equipment/OrcBoots.png",
	"Orcish Axe":     "res://Sprites/Equipment/OrcishAxe.png",
	"Orc King Shield":"res://Sprites/Equipment/OrcKingShield.png",
	"T1 Map":         "res://Sprites/Equipment/T1Map.png",
	"T1 Survival Gear": "res://Sprites/Equipment/T1SurvivalGear.png",
	# Slimy Set
	"Slimy Helmet":   "res://Sprites/Equipment/SlimeHelmet.png",
	"Slimy Armor":    "res://Sprites/Equipment/SlimeArmor.png",
	"Slimy Legs":     "res://Sprites/Equipment/SlimeLegs.png",
	"Slimy Boots":    "res://Sprites/Equipment/SlimeBoots.png",
	"Slimy Blade":    "res://Sprites/Equipment/SlimeBlade.png",
	"Slimy Shield":   "res://Sprites/Equipment/SlimeShield.png",
	# Sandling Set
	"Sandling Helmet": "res://Sprites/Equipment/BoneHelmet.png",
	"Sandling Armor":  "res://Sprites/Equipment/BoneArmor.png",
	"Sandling Legs":   "res://Sprites/Equipment/BoneLegs.png",
	"Sandling Boots":  "res://Sprites/Equipment/BoneBoots.png",
	"Sandling Blade":  "res://Sprites/Equipment/BoneBlade.png",
	"Sandling Shield": "res://Sprites/Equipment/BoneShield.png",
	# T2 Expedition gear
	"T2 Map":           "res://Sprites/Equipment/T2Map.png",
	"T2 Survival Gear": "res://Sprites/Equipment/T2SurvivalGear.png",
}
