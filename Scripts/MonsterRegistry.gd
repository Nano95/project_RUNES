extends Node

var areaMonsters: Dictionary = {}

func _ready() -> void:
	areaMonsters = {
"Hunting Grounds": {
			"weak": [
				_make("Orcling", "weak", 15, 11, 1, 4, [
					_drop("Orc Leather", 0.08),
					_drop("Orc Helmet", 0.03),
				]),
				_make("Orc Grunt", "weak", 18, 12, 1, 5, [
					_drop("Orc Leather", 0.08),
					_drop("Orc Helmet", 0.03),
				]),
				_make("Orc Runt", "weak", 12, 10, 0, 3, [
					_drop("Orc Leather", 0.08),
					_drop("Orc Helmet", 0.02),
				]),
			],
			"medium": [
				_make("Orc Warrior", "medium", 45, 17, 5, 10, [
					_drop("Orc Leather", 0.11),
					_drop("Orc Legs", 0.04),
					_drop("Orcish Axe", 0.05),
					
				]),
				_make("Orc Brute", "medium", 55, 19, 6, 11, [
					_drop("Orc Leather", 0.11),
					_drop("Orc Legs", 0.04),
					_drop("Orcish Axe", 0.05),
				]),
				_make("Orc Raider", "medium", 50, 18, 5, 10, [
					_drop("Orc Leather", 0.11),
					_drop("Orc Legs", 0.03),
					_drop("Orcish Axe", 0.05),
				]),
			],
			"strong": [
				_make("Mounted Orc", "strong", 90, 27, 10, 15, [
					_drop("Orc Leather", 0.15),
					_drop("Orc Boots", 0.05),
					_drop("Orc Armor", 0.04),
				]),
				_make("Orc General", "strong", 110, 30, 12, 15, [
					_drop("Orc Leather", 0.15),
					_drop("Orc General Crest", 0.10),
					_drop("Orc Boots", 0.05),
					_drop("Orc Armor", 0.05),
				]),
				_make("Orc Warchief", "strong", 130, 30, 10, 15, [
					_drop("Orc Leather", 0.20),
					_drop("Orc General Crest", 0.15),
					_drop("Orc Boots", 0.06),
					_drop("Orc Armor", 0.05),
				]),
			],
			"elite": [
				_make("Orc King", "elite", 500, 50, 100, 200, [
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
	}

func _make(monsterName: String, tier: String, hp: int, atk: int, goldMin: int, goldMax: int, loot: Array[DropEntry] = []) -> MonsterData:
	var m = MonsterData.new()
	m.monsterName = monsterName
	m.tier = tier
	m.hp = hp
	m.atk = atk
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
