extends Node

var areaMonsters: Dictionary = {}

func _ready() -> void:
	areaMonsters = {
		"Hunting Grounds": {
			"weak": [
				_make("Orcling", "weak", 15, 11, 1, 4, {}, [
					_drop("Orc Leather", 0.08),
					_drop("Orc Helmet", 0.03),
				]),
				_make("Orc Grunt", "weak", 18, 12, 1, 5, {}, [
					_drop("Orc Leather", 0.08),
					_drop("Orc Helmet", 0.03),
				]),
				_make("Orc Runt", "weak", 12, 10, 0, 3, {}, [
					_drop("Orc Leather", 0.08),
					_drop("Orc Helmet", 0.02),
				]),
			],
			"medium": [
				_make("Orc Warrior", "medium", 45, 17, 5, 10, {}, [
					_drop("Orc Leather", 0.11),
					_drop("Orc Legs", 0.04),
					_drop("Orcish Axe", 0.05),
					
				]),
				_make("Orc Brute", "medium", 55, 19, 6, 11, {}, [
					_drop("Orc Leather", 0.11),
					_drop("Orc Legs", 0.04),
					_drop("Orcish Axe", 0.05),
				]),
				_make("Orc Raider", "medium", 50, 18, 5, 10, {}, [
					_drop("Orc Leather", 0.11),
					_drop("Orc Legs", 0.03),
					_drop("Orcish Axe", 0.05),
				]),
			],
			"strong": [
				_make("Mounted Orc", "strong", 90, 27, 10, 15, {}, [
					_drop("Orc Leather", 0.15),
					_drop("Orc Boots", 0.05),
					_drop("Orc Armor", 0.04),
				]),
				_make("Orc General", "strong", 110, 30, 12, 15, {}, [
					_drop("Orc Leather", 0.15),
					_drop("Orc General Crest", 0.10),
					_drop("Orc Boots", 0.05),
					_drop("Orc Armor", 0.05),
				]),
				_make("Orc Warchief", "strong", 130, 30, 10, 15, {}, [
					_drop("Orc Leather", 0.20),
					_drop("Orc General Crest", 0.15),
					_drop("Orc Boots", 0.06),
					_drop("Orc Armor", 0.05),
				]),
			],
			"elite": [
				_make("Orc King", "elite", 500, 50, 100, 200, {}, [
					_drop("Orc Leather", 0.90),
					_drop("Orc General Crest", 0.45),
					_drop("King's Tusk", 0.15),
					_drop("Orc King Shield", 0.25),
					_drop("Orc Helmet", 0.20),
					_drop("Orc Armor", 0.20),
					_drop("Orc Legs", 0.20),
					_drop("Orc Boots", 0.20),
				]),
			],
		},
		"Slime Swamps": {
			"weak": [
				_make("Small Slime", "weak", 20, 8, 1, 5, {"poison": 0.3}, [
					_drop("Slime Gel", 0.08),
					_drop("Slimy Shield", 0.03),
				]),
				_make("Green Slime", "weak", 25, 10, 2, 7, {"poison": 0.3}, [
					_drop("Slime Gel", 0.08),
					_drop("Slimy Shield", 0.03),
				]),
				_make("Blue Slime", "weak", 30, 12, 2, 8, {"poison": 1.0}, [
					_drop("Slime Gel", 0.08),
					_drop("Slimy Shield", 0.04),
				]),
			],
			"medium": [
				_make("Bog Slime", "medium", 60, 18, 6, 16, {}, [
					_drop("Slime Gel", 0.12),
					_drop("Slimy Blade", 0.04),
					_drop("Slimy Armor", 0.03),
				]),
				_make("Toxic Slime", "medium", 70, 20, 7, 18, {"poison": 0.33}, [
					_drop("Slime Gel", 0.12),
					_drop("Slime Core", 0.10),
					_drop("Slimy Blade", 0.04),
					_drop("Slimy Armor", 0.03),
				]),
				_make("Slime Mold", "medium", 65, 19, 6, 17, {}, [
					_drop("Slime Gel", 0.12),
					_drop("Slimy Blade", 0.03),
					_drop("Slimy Armor", 0.03),
				]),
			],
			"strong": [
				_make("Slime Giant", "strong", 140, 32, 18, 40, {}, [
					_drop("Slime Gel", 0.17),
					_drop("Slime Core", 0.08),
					_drop("Slimy Legs", 0.05),
					_drop("Slimy Helmet", 0.04),
				]),
				_make("Acid Slime", "strong", 160, 36, 20, 45, {"poison": 0.33}, [
					_drop("Slime Gel", 0.17),
					_drop("Slime Core", 0.09),
					_drop("Slimy Legs", 0.05),
					_drop("Slimy Helmet", 0.04),
				]),
				_make("King's Guard", "strong", 180, 40, 22, 50, {"poison": 0.33}, [
					_drop("Slime Gel", 0.17),
					_drop("Slime Core", 0.10),
					_drop("Slimy Legs", 0.06),
					_drop("Slimy Helmet", 0.05),
				]),
			],
			"elite": [
				_make("King Slime", "elite", 800, 70, 150, 400, {"poison": 0.33}, [
					_drop("Slime Gel", 0.90),
					_drop("Slime Core", 0.60),
					_drop("Royal Gel", 0.20),
					_drop("Slimy Shield", 0.20),
					_drop("Slimy Blade", 0.20),
					_drop("Slimy Armor", 0.20),
					_drop("Slimy Legs", 0.20),
					_drop("Slimy Helmet", 0.20),
					_drop("Slimy Boots", 0.15),
				]),
			],
		},
		"Sandling Dunes": {
			"weak": [
				_make("Hooded Sandling", "weak", 45, 16, 3, 10, {}, [
					_drop("Bone Dust", 0.08),
					_drop("Sandling Helmet", 0.03),
					_drop("Sandling Shield", 0.02),
				]),
				_make("Roaming Sandling", "weak", 50, 18, 3, 12, {}, [
					_drop("Bone Dust", 0.08),
					_drop("Sandling Helmet", 0.03),
					_drop("Sandling Shield", 0.02),
				]),
				_make("Dust Sandling", "weak", 40, 15, 2, 9, {}, [
					_drop("Bone Dust", 0.08),
					_drop("Sandling Helmet", 0.02),
					_drop("Sandling Shield", 0.01),
				]),
			],
			"medium": [
				_make("Horned Sandling", "medium", 90, 28, 8, 22, {}, [
					_drop("Bone Dust", 0.12),
					_drop("Sandling Blade", 0.04),
					_drop("Sandling Armor", 0.03),
				]),
				_make("Sand Brute", "medium", 100, 30, 9, 25, {}, [
					_drop("Bone Dust", 0.12),
					_drop("Sandling Blade", 0.04),
					_drop("Sandling Armor", 0.03),
				]),
				_make("Sandling Archer", "medium", 85, 26, 7, 20, {}, [
					_drop("Bone Dust", 0.12),
					_drop("Sandling Blade", 0.03),
					_drop("Sandling Armor", 0.03),
				]),
			],
			"strong": [
				_make("Sandling Warrior", "strong", 170, 42, 22, 55, {}, [
					_drop("Bone Dust", 0.18),
					_drop("Crystal Bone", 0.12),
					_drop("Sandling Legs", 0.03),
					_drop("Sandling Boots", 0.02),
				]),
				_make("Sandling Champion", "strong", 200, 48, 25, 65, {}, [
					_drop("Bone Dust", 0.18),
					_drop("Crystal Bone", 0.18),
					_drop("Sandling Legs", 0.04),
					_drop("Sandling Boots", 0.03),
				]),
				_make("Sand Golem", "strong", 220, 52, 28, 70, {}, [
					_drop("Bone Dust", 0.18),
					_drop("Crystal Bone", 0.22),
					_drop("Sandling Legs", 0.05),
					_drop("Sandling Boots", 0.05),
				]),
			],
			"elite": [
				_make("Mad Necromancer", "elite", 1200, 90, 300, 600, {}, [
					_drop("Bone Dust", 0.90),
					_drop("Crystal Bone", 0.60),
					_drop("Ancient Relic", 0.20),
					_drop("Sandling Helmet", 0.25),
					_drop("Sandling Armor", 0.25),
					_drop("Sandling Legs", 0.25),
					_drop("Sandling Boots", 0.25),
					_drop("Sandling Blade", 0.20),
					_drop("Sandling Shield", 0.20),
				]),
			],
		},
	}

func _make(monsterName: String, tier: String, hp: int, atk: int, 
		   goldMin: int, goldMax: int, 
		   statusEffects: Dictionary = {},
		   drops: Array[DropEntry] = []) -> MonsterData:
	var m = MonsterData.new()
	m.monsterName = monsterName
	m.tier = tier
	m.hp = hp
	m.atk = atk
	m.goldMin = goldMin
	m.goldMax = goldMax
	m.statusEffects = statusEffects
	m.dropTable = drops
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

func getMonsterByName(monsterName: String) -> MonsterData:
	for area in areaMonsters:
		for tier in areaMonsters[area]:
			for monster in areaMonsters[area][tier]:
				if monster.monsterName == monsterName:
					return monster
	return null

func getMonsterByAreaNameTier(monsterName: String, tier: String, area: String) -> MonsterData:
	for monster in areaMonsters[area][tier]:
		if monster.monsterName == monsterName:
			return monster
	return null
