extends Node

var items: Dictionary = {}

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
	# ── MONSTER PARTS ─────────────────────────────────────

	# Hunting Grounds
	_add("Rat Tail",            "part",       true,  0.9, "A scaly rat tail.",                5)
	_add("Rat Fur",             "part",       true,  0.2, "Coarse fur from a giant rat.",     8)
	_add("Rat Tooth",           "part",       true,  0.1, "A small sharp tooth.",             6)
	_add("Slime Gel",           "part",       true,  0.3, "Sticky green gel.",                6)
	_add("Slime Chunk",         "part",       true,  0.4, "A wobbling chunk of slime.",       4)
	_add("Bat Wing",            "part",       true,  0.2, "A leathery bat wing.",             7)
	_add("Bat Fang",            "part",       true,  0.1, "A tiny curved fang.",              5)
	_add("Orc Tooth",           "part",       true,  0.3, "Yellowed and cracked.",            8)
	_add("Orc Leather",         "part",       true,  0.5, "Rough orcish hide.",               12)
	_add("Orc Scout Badge",     "part",       true,  0.2, "A crude insignia.",                20)
	_add("Wolf Pelt",           "part",       true,  0.6, "A thick wolf pelt.",               15)
	_add("Wolf Claw",           "part",       true,  0.2, "A sharp curved claw.",             10)
	_add("Wolf Fang",           "part",       true,  0.2, "A long wolf fang.",                10)
	_add("Frog Leg",            "part",       true,  0.3, "Slimy but valuable.",              8)
	_add("Bog Slime",           "part",       true,  0.3, "Foul smelling bog residue.",       5)
	_add("Frog Eye",            "part",       true,  0.1, "Bulbous and unsettling.",          12)
	_add("Worm Meat",           "part",       true,  0.5, "Rank flesh from a rotworm.",       10)
	_add("Rotworm Shell",       "part",       true,  0.6, "A hardened carapace segment.",     14)
	_add("Worm Head",           "part",       true,  0.4, "Still twitching.",                 18)
	_add("Rotworm Trophy",      "part",       true,  0.3, "Proof of a hard fight.",           35)
	_add("Orcish Axe",          "equipment",  false, 3.0, "A crude but heavy axe.",           40)
	_add("Orc Armor Scrap",     "part",       true,  1.0, "Battered orcish plate.",           18)
	_add("Warrior Crest",       "part",       true,  0.2, "A mark of rank among orcs.",       45)
	_add("War Wolf Claw",       "part",       true,  0.3, "Larger than a normal claw.",       20)
	_add("Alpha Fang",          "part",       true,  0.3, "From the pack leader.",            28)
	_add("War Wolf Heart",      "part",       true,  0.4, "Still warm.",                      50)
	# King Slime drops
	_add("Slime Crown Fragment","part",       true,  0.5, "Part of a royal crown.",           80)
	_add("Royal Slime Core",    "part",       true,  0.8, "Pulsing with strange energy.",     120)
	_add("King's Ooze",         "part",       true,  0.3, "Regal and revolting.",             100)

	# Outskirts
	_add("Crude Blade",         "equipment",  false, 2.0, "Better than nothing.",             25)
	_add("Cyclops Toe",         "part",       true,  1.0, "Enormous and warty.",              22)
	_add("Giant Club",          "equipment",  false, 5.0, "Impossibly heavy.",                55)
	_add("Cyclops Eye",         "part",       true,  0.5, "Still staring.",                   40)
	_add("Cyclops Trophy",      "part",       true,  0.4, "For the brave.",                   60)
	_add("Bandit Hood",         "part",       true,  0.4, "Smells of cheap ale.",             18)
	_add("Stolen Goods",        "part",       true,  0.5, "Origin unknown.",                  22)
	_add("Bandit Blade",        "equipment",  false, 2.5, "Notched but sharp.",               35)
	_add("Bandit Crest",        "part",       true,  0.2, "A gang insignia.",                 45)
	_add("Shaman Staff",        "equipment",  false, 2.0, "Humming with dark energy.",        65)
	_add("Orc Talisman",        "part",       true,  0.2, "A ward against spirits.",          35)
	_add("Hex Rune",            "part",       true,  0.1, "Carved in blood.",                 55)
	_add("Shaman Heart",        "part",       true,  0.4, "Blackened and shriveled.",         90)
	_add("War Wolf Pelt",       "part",       true,  0.8, "Thick and battle-scarred.",        35)
	_add("Troll Hide",          "part",       true,  1.0, "Rough as stone.",                  20)
	_add("Stone Club",          "equipment",  false, 6.0, "A literal rock on a stick.",       45)
	_add("Troll Wart",          "part",       true,  0.5, "Grotesque but alchemically useful.",18)
	_add("Troll Trophy",        "part",       true,  0.4, "Impressive to some.",              55)
	# Bandit King drops
	_add("King's Ransom",       "part",       true,  0.3, "A small fortune in gems.",         200)
	_add("Bandit King Crown",   "part",       true,  0.5, "Gaudy and gold-plated.",           250)

	# Darkwood Forest
	_add("Druid Staff",         "equipment",  false, 2.0, "Carved from rotwood.",             80)
	_add("Dark Rune",           "part",       true,  0.1, "Radiates wrongness.",              45)
	_add("Druid Cloak",         "part",       true,  0.6, "Woven from forest shadow.",        55)
	_add("Corrupted Seed",      "part",       true,  0.1, "It pulses faintly.",               65)
	_add("Werewolf Claw",       "part",       true,  0.3, "Razor sharp.",                     35)
	_add("Werewolf Pelt",       "part",       true,  0.8, "Coarse and matted.",               40)
	_add("Werewolf Fang",       "part",       true,  0.2, "Serrated edge.",                   38)
	_add("Moon Stone",          "part",       true,  0.2, "Glows faintly at night.",          70)
	_add("Spider Silk",         "part",       true,  0.2, "Stronger than steel.",             30)
	_add("Spider Fang",         "part",       true,  0.2, "Drips venom.",                     28)
	_add("Venom Gland",         "part",       true,  0.2, "Handle with care.",                45)
	_add("Spider Eye Cluster",  "part",       true,  0.3, "Eight eyes in one.",               55)
	_add("Elder Rune",          "part",       true,  0.1, "Ancient and powerful.",            85)
	_add("Nature Crown",        "part",       true,  0.4, "Woven from living branches.",      110)
	_add("Heart of the Wood",   "part",       true,  0.5, "The forest weeps without it.",     180)
	_add("Vampire Fang",        "part",       true,  0.1, "Still sharp.",                     40)
	_add("Blood Vial",          "part",       true,  0.2, "Filled with dark blood.",          35)
	_add("Vampire Cape",        "part",       true,  0.5, "Dramatically billowing.",          65)
	_add("Crimson Ring",        "part",       true,  0.1, "Warm to the touch.",               90)
	_add("Golem Core",          "part",       true,  0.8, "The source of its animation.",     75)
	_add("Poison Stone",        "part",       true,  0.5, "Seeping green.",                   55)
	_add("Toxic Shard",         "part",       true,  0.3, "Handle with gloves.",              65)
	_add("Venom Heart",         "part",       true,  0.4, "Pumping still.",                   120)
	# Rotfather drops
	_add("Rotwood Bark",        "part",       true,  0.6, "Bark from the corrupted heart.",   100)
	_add("Rotfather Eye",       "part",       true,  0.4, "Sees even in death.",              150)
	_add("Heart of Rot",        "part",       true,  0.5, "The source of the corruption.",    220)

	# Ashfield Ruins
	_add("Bone",                "part",       true,  0.3, "A bleached bone.",                 5)
	_add("Skull",               "part",       true,  0.5, "Empty eyed.",                      12)
	_add("Rusty Sword",         "equipment",  false, 3.0, "Barely holds an edge.",            15)
	_add("Rotten Flesh",        "part",       true,  0.4, "Foul smelling.",                   6)
	_add("Zombie Hand",         "part",       true,  0.3, "Still grasping.",                  10)
	_add("Brain Matter",        "part",       true,  0.3, "Unspeakable.",                     8)
	_add("Ectoplasm",           "part",       true,  0.2, "Faintly luminous.",                20)
	_add("Soul Shard",          "part",       true,  0.1, "A trapped fragment of spirit.",    45)
	_add("Ghost Veil",          "part",       true,  0.3, "Gossamer thin.",                   38)
	_add("Dark Knight Helm",    "equipment",  false, 3.0, "Forged in shadow.",                90)
	_add("Shadow Steel",        "part",       true,  0.8, "Darker than iron.",                55)
	_add("Cursed Shield",       "equipment",  false, 4.0, "Something is wrong with it.",      75)
	_add("Knight Soul",         "part",       true,  0.2, "Bound to the armor.",              100)
	_add("Golem Bone",          "part",       true,  0.6, "Animated calcium.",                25)
	_add("Ancient Marrow",      "part",       true,  0.4, "From something old.",              40)
	_add("Bone Rune",           "part",       true,  0.2, "Carved into femur.",               55)
	_add("Lich Dust",           "part",       true,  0.1, "All that remains.",                80)
	_add("Lich Robe",           "part",       true,  0.5, "Still radiates cold.",             95)
	_add("Lich Staff",          "equipment",  false, 2.0, "Hums with death magic.",           120)
	_add("Soul Gem",            "part",       true,  0.2, "A trapped soul inside.",           110)
	_add("Lich Crown",          "part",       true,  0.3, "Dark and terrible.",               200)
	_add("Death Blade",         "equipment",  false, 3.5, "Kills twice.",                     130)
	_add("Shadow Armor",        "part",       true,  1.5, "Absorbs light.",                   110)
	_add("Death Seal",          "part",       true,  0.2, "Marks the bearer.",                120)
	_add("Shadow Essence",      "part",       true,  0.2, "Bottled darkness.",                65)
	_add("Dark Claw",           "part",       true,  0.3, "Cold as death.",                   55)
	_add("Void Shard",          "part",       true,  0.2, "From somewhere else.",             80)
	_add("Shadow Heart",        "part",       true,  0.4, "Beats irregularly.",               130)
	# Ashen King drops
	_add("Ashen Crown Fragment","part",       true,  0.4, "A piece of something terrible.",   200)
	_add("Ashen King Robe",     "part",       true,  0.8, "Still smoldering.",                280)
	_add("Crown of Ash",        "part",       true,  0.5, "Heavy with dark power.",           400)

	# Abyssal Depths
	_add("Demon Hide",          "part",       true,  1.0, "Resistant to fire.",               90)
	_add("Demon Claw",          "part",       true,  0.4, "Barbed and cruel.",                85)
	_add("Infernal Shard",      "part",       true,  0.3, "Burns cold.",                      100)
	_add("Demon Eye",           "part",       true,  0.3, "Still seeing.",                    110)
	_add("Crawler Shell",       "part",       true,  0.8, "Nearly impenetrable.",             80)
	_add("Abyssal Acid",        "part",       true,  0.3, "Eats through anything.",           95)
	_add("Crawler Fang",        "part",       true,  0.3, "Hollow for venom.",                75)
	_add("Void Residue",        "part",       true,  0.2, "Left where reality tore.",         120)
	_add("Flayer Tentacle",     "part",       true,  0.4, "Writhing faintly.",                90)
	_add("Psychic Crystal",     "part",       true,  0.2, "Thinking thoughts at you.",        130)
	_add("Mind Shard",          "part",       true,  0.2, "A fragment of consumed mind.",     110)
	_add("Flayer Brain",        "part",       true,  0.5, "Do not look directly at it.",      180)
	_add("Demon Heart",         "part",       true,  0.6, "Burning hot.",                     150)
	_add("Infernal Core",       "part",       true,  0.8, "The engine of a demon.",           200)
	_add("Pit Lord Seal",       "part",       true,  0.3, "Commands lesser demons.",          220)
	_add("Demon Soul",          "part",       true,  0.1, "Screaming faintly.",               350)
	_add("Void Essence",        "part",       true,  0.2, "Pure nothingness, bottled.",       180)
	_add("Walker Rune",         "part",       true,  0.1, "Allows passage between worlds.",   250)
	_add("Abyssal Heart",       "part",       true,  0.5, "Beating in wrong rhythm.",         200)
	_add("Horror Flesh",        "part",       true,  0.6, "Reshaping itself slowly.",         160)
	_add("Abyssal Shard",       "part",       true,  0.3, "A splinter of the abyss.",         190)
	_add("Horror Eye",          "part",       true,  0.3, "Watching everything.",             170)
	_add("Horror Core",         "part",       true,  0.6, "Pulsing wrongly.",                 230)
	_add("Void Crown",          "part",       true,  0.4, "Worn by something ancient.",       400)
	# Void Sovereign drops
	_add("Void Sigil Fragment", "part",       true,  0.3, "A piece of absolute power.",       500)
	_add("Sovereign Scale",     "part",       true,  0.5, "Iridescent and cold.",             450)
	_add("Crown of the Void",   "part",       true,  0.6, "Reality bends around it.",         800)

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
	_add("Minor Heal Potion",   "potion",     true,  2.3, "Restores 20 HP.",                  15)
	_add("Health Potion",       "potion",     true,  2.8, "Restores 30 HP.",                  20)
	_add("Strong Heal Potion",  "potion",     true,  3.4, "Restores 50 HP.",                  35)
	_add("Herbal Elixir",       "potion",     true,  3.8, "Restores 60 HP.",                  45)
	_add("Twilight Potion",     "potion",     true,  5.0, "Restores 70 HP.",                  55)

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
