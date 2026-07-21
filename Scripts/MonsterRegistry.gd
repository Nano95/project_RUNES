extends Node

var areaMonsters: Dictionary = {}

func _ready() -> void:
	areaMonsters = {
		"Hunting Grounds": {
			"weak": [
				_make("Giant Rat", "weak", 15, 9, 6, 1, 5, [
					_drop("Rat Tail", 0.45),
					_drop("Creature Fang", 0.05),
				]),
				_make("Green Slime", "weak", 12, 8, 5, 1, 4, [
					_drop("Slime Gel", 0.45),
				]),
				_make("Cave Bat", "weak", 10, 6, 6, 0, 3, [
					_drop("Bat Wing", 0.45),
					_drop("Creature Fang", 0.05),
				]),
			],
			"medium": [
				_make("Orc Scout", "medium", 35, 11, 20, 5, 14, [
					_drop("Orc Tooth", 0.45),
					_drop("Beast Skin", 0.25),
					_drop("Iron Helmet", 0.1)
				]),
				_make("Wild Wolf", "medium", 30, 10, 18, 4, 12, [
					_drop("Beast Skin", 0.35),
					_drop("Giant Fang", 0.01),
				]),
				_make("Bog Frog", "medium", 28, 12, 16, 3, 10, [
					_drop("Frog Leg", 0.45),
				]),
			],
			"strong": [
				_make("Orc Warrior", "strong", 70, 20, 50, 14, 30, [
					_drop("Orc Tooth", 0.45),
					_drop("Beast Skin", 0.20),
					_drop("Orcish Axe", 0.05),
					_drop("Reinforced Shield", 0.1)
				]),
				_make("War Wolf", "strong", 60, 22, 48, 12, 26, [
					_drop("Beast Skin", 0.35),
					_drop("Giant Fang", 0.05),
				]),
			],
			"elite": [
				_make("King Slime", "elite", 300, 35, 200, 80, 150, [
					_drop("Slime Gel", 0.90),
					_drop("Royal Slime Core", 0.03),
				]),
			],
		},

		"Outskirts": {
			"weak": [
				_make("Orc Scout", "weak", 35, 11, 20, 5, 14, [
					_drop("Orc Tooth", 0.45),
					_drop("Beast Skin", 0.25),
				]),
				_make("Wild Wolf", "weak", 30, 10, 18, 4, 12, [
					_drop("Beast Skin", 0.35),
					_drop("Giant Fang", 0.01),
				]),
				_make("Bog Frog", "weak", 28, 12, 16, 3, 10, [
					_drop("Frog Leg", 0.45),
				]),
			],
			"medium": [
				_make("Rotworm", "medium", 65, 16, 32, 10, 22, [
					_drop("Creature Fang", 0.20),
					_drop("Fang Spear", 0.01)
				]),
				_make("Cyclops", "medium", 80, 22, 40, 15, 30, [
					_drop("Cyclops Eye", 0.25),
				]),
				_make("Bandit", "medium", 60, 18, 35, 12, 25, [
					_drop("Leather Armor", 0.10),
					_drop("Leather Helmet", 0.10),
				]),
			],
			"strong": [
				_make("Orc Shaman", "strong", 100, 28, 70, 25, 50, [
					_drop("Orc Tooth", 0.45),
					_drop("Shaman Staff", 0.10),
				]),
				_make("War Wolf", "strong", 90, 30, 65, 22, 45, [
					_drop("Beast Skin", 0.35),
					_drop("Giant Fang", 0.05),
				]),
				_make("Stone Troll", "strong", 120, 26, 75, 28, 55, [
					_drop("Copper Ore", 0.90),
					_drop("Iron Ore", 0.50),
					_drop("Coal", 0.40),
					_drop("Gold Ore", 0.20),
				]),
			],
			"elite": [
				_make("Bandit King", "elite", 450, 50, 350, 150, 280, [
					_drop("War Hammer", 0.25),
					_drop("Reinforced Boots", 0.10),
				]),
			],
		},

		"Darkwood Forest": {
			"weak": [
				_make("Rotworm", "weak", 65, 12, 20, 8, 16, [
					_drop("Creature Fang", 0.20),
					_drop("Fang Spear", 0.01)
				]),
				_make("Stone Troll", "weak", 120, 18, 25, 10, 20, [
					_drop("Copper Ore", 0.90),
					_drop("Iron Ore", 0.50),
					_drop("Coal", 0.40),
					_drop("Gold Ore", 0.20),
				]),
				_make("Bandit", "weak", 60, 14, 22, 8, 18, [
					_drop("Leather Armor", 0.10),
					_drop("Leather Helmet", 0.10),
				]),
			],
			"medium": [
				_make("Corrupt Elf", "medium", 90, 24, 55, 20, 40, [
					_drop("Elven Helmet", 0.25),
				]),
				_make("Werewolf", "medium", 130, 35, 85, 28, 55, [
					_drop("Giant Fang", 0.50),
				]),
				_make("Giant Spider", "medium", 100, 28, 75, 25, 50, [
					_drop("Spider Silk", 0.10),
				]),
			],
			"strong": [
				_make("Dark Druid", "strong", 180, 45, 130, 50, 90, [
					_drop("Cloth", 0.30),
				]),
				_make("Lost Soul", "strong", 150, 50, 140, 45, 85, [
					_drop("Dark Essence", 0.10),
				]),
				_make("Weeping Willow", "strong", 200, 42, 135, 48, 88, [
					_drop("Bark Shield", 0.05),
				]),
			],
			"elite": [
				_make("Banshee", "elite", 650, 70, 500, 200, 400, [
					_drop("Dark Essence", 0.90),
					_drop("Banshee Veil", 0.25),
				]),
			],
		},
	}

func _make(monsterName: String, tier: String, hp: int, atk: int, xp: int, goldMin: int, goldMax: int, loot: Array[DropEntry] = []) -> MonsterData:
	var m = MonsterData.new()
	m.monsterName = monsterName
	m.tier = tier
	m.hp = hp
	m.atk = atk
	m.xp = xp
	m.goldMin = goldMin
	m.goldMax = goldMax
	m.dropTable = loot
	return m

### Rarity    | Chance
### Common    | 0.45
### Uncommon  | 0.25
### Rare      | 0.10
### Very Rare | 0.03
### Unique    | 0.01
func _drop(itemName: String, chance: float) -> DropEntry:
	var l = DropEntry.new()
	l.itemName = itemName
	l.dropChance = chance
	return l

func rollTier(eventCount: int) -> String:
	var weakChance: int
	var mediumChance: int
	var strongChance: int
	
	# These do not add up to 100. The REMAINDER is going to be the ELITE CHANCE
	if (eventCount <= 10):
		weakChance = 100; mediumChance = 0; strongChance = 0 # No elite chance
	elif (eventCount <= 20):
		weakChance = 90; mediumChance = 10; strongChance = 0 # No elite chance
	elif (eventCount <= 40):
		weakChance = 70; mediumChance = 25; strongChance = 4 # 1% elite chance...
	elif (eventCount <= 70):
		weakChance = 38; mediumChance = 35; strongChance = 25 # 2% 
	elif (eventCount <= 100):
		weakChance = 23; mediumChance = 35; strongChance = 39 # 3% 
	else:
		weakChance = 18; mediumChance = 38; strongChance = 39 # 5% 

	var roll = randi() % 100
	if roll < weakChance:
		return "weak"
	elif roll < weakChance + mediumChance:
		return "medium"
	elif roll < weakChance + mediumChance + strongChance:
		return "strong"
	return "elite"

func rollMonster(area: String, tier: String) -> MonsterData:
	if not areaMonsters.has(area):
		return null
	var tierList = areaMonsters[area][tier] as Array
	return tierList[randi() % tierList.size()]

func rollDrops(monster: MonsterData) -> Array[String]:
	var drops: Array[String] = []
	for entry in monster.dropTable:
		if randf() <= entry.dropChance:
			drops.append(entry.itemName)
	return drops
