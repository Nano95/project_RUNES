extends Node

var areaMonsters: Dictionary = {}

func _ready() -> void:
	areaMonsters = {
		"Hunting Grounds": {
			"weak": [
				_make("Giant Rat", "weak", 15, 4, 6, 1, 5, [
					_drop("Rat Tail", 0.45),
					_drop("Rat Fur", 0.25),
					_drop("Rat Tooth", 0.10),
				]),
				_make("Green Slime", "weak", 12, 3, 5, 1, 4, [
					_drop("Slime Gel", 0.45),
					_drop("Slime Chunk", 0.25),
				]),
				_make("Cave Bat", "weak", 10, 4, 6, 0, 3, [
					_drop("Bat Wing", 0.45),
					_drop("Bat Fang", 0.25),
				]),
			],
			"medium": [
				_make("Orc Scout", "medium", 35, 10, 20, 5, 14, [
					_drop("Orc Tooth", 0.45),
					_drop("Orc Leather", 0.25),
					_drop("Crude Blade", 0.10),
					_drop("Orc Scout Badge", 0.03),
				]),
				_make("Wild Wolf", "medium", 30, 9, 18, 4, 12, [
					_drop("Wolf Pelt", 0.45),
					_drop("Wolf Claw", 0.25),
					_drop("Wolf Fang", 0.10),
				]),
				_make("Bog Frog", "medium", 28, 8, 16, 3, 10, [
					_drop("Frog Leg", 0.45),
					_drop("Bog Slime", 0.25),
					_drop("Frog Eye", 0.10),
				]),
			],
			"strong": [
				_make("Rotworm", "strong", 65, 18, 45, 12, 28, [
					_drop("Worm Meat", 0.45),
					_drop("Rotworm Shell", 0.25),
					_drop("Worm Head", 0.10),
					_drop("Rotworm Trophy", 0.03),
				]),
				_make("Orc Warrior", "strong", 70, 20, 50, 14, 30, [
					_drop("Orc Tooth", 0.45),
					_drop("Orcish Axe", 0.25),
					_drop("Orc Armor Scrap", 0.10),
					_drop("Warrior Crest", 0.03),
				]),
				_make("War Wolf", "strong", 60, 22, 48, 12, 26, [
					_drop("Wolf Pelt", 0.45),
					_drop("War Wolf Claw", 0.25),
					_drop("Alpha Fang", 0.10),
					_drop("War Wolf Heart", 0.03),
				]),
			],
			"elite": [
				_make("King Slime", "elite", 300, 35, 200, 80, 150, [
					_drop("Slime Gel", 0.90),
					_drop("Slime Crown Fragment", 0.45),
					_drop("Royal Slime Core", 0.10),
					_drop("King's Ooze", 0.03),
				]),
			],
		},

		"Outskirts": {
			"weak": [
				_make("Orc Scout", "weak", 35, 8, 15, 4, 10, [
					_drop("Orc Tooth", 0.45),
					_drop("Orc Leather", 0.25),
					_drop("Crude Blade", 0.10),
				]),
				_make("Wild Wolf", "weak", 30, 7, 14, 3, 9, [
					_drop("Wolf Pelt", 0.45),
					_drop("Wolf Claw", 0.25),
				]),
				_make("Bog Frog", "weak", 28, 6, 12, 2, 8, [
					_drop("Frog Leg", 0.45),
					_drop("Bog Slime", 0.25),
				]),
			],
			"medium": [
				_make("Cyclops", "medium", 80, 22, 40, 15, 30, [
					_drop("Cyclops Toe", 0.45),
					_drop("Giant Club", 0.25),
					_drop("Cyclops Eye", 0.10),
					_drop("Cyclops Trophy", 0.03),
				]),
				_make("Bandit", "medium", 60, 18, 35, 12, 25, [
					_drop("Bandit Hood", 0.45),
					_drop("Stolen Goods", 0.25),
					_drop("Bandit Blade", 0.10),
					_drop("Bandit Crest", 0.03),
				]),
				_make("Rotworm", "medium", 65, 16, 32, 10, 22, [
					_drop("Worm Meat", 0.45),
					_drop("Rotworm Shell", 0.25),
					_drop("Worm Head", 0.10),
				]),
			],
			"strong": [
				_make("Orc Shaman", "strong", 100, 28, 70, 25, 50, [
					_drop("Shaman Staff", 0.25),
					_drop("Orc Talisman", 0.10),
					_drop("Hex Rune", 0.03),
					_drop("Shaman Heart", 0.01),
				]),
				_make("War Wolf", "strong", 90, 30, 65, 22, 45, [
					_drop("War Wolf Claw", 0.45),
					_drop("Alpha Fang", 0.25),
					_drop("War Wolf Pelt", 0.10),
					_drop("War Wolf Heart", 0.03),
				]),
				_make("Stone Troll", "strong", 120, 26, 75, 28, 55, [
					_drop("Troll Hide", 0.45),
					_drop("Stone Club", 0.25),
					_drop("Troll Wart", 0.10),
					_drop("Troll Trophy", 0.03),
				]),
			],
			"elite": [
				_make("Bandit King", "elite", 450, 50, 350, 150, 280, [
					_drop("Bandit Hood", 0.90),
					_drop("Bandit Crest", 0.45),
					_drop("King's Ransom", 0.10),
					_drop("Bandit King Crown", 0.03),
				]),
			],
		},

		"Darkwood Forest": {
			"weak": [
				_make("Rotworm", "weak", 65, 12, 20, 8, 16, [
					_drop("Worm Meat", 0.45),
					_drop("Rotworm Shell", 0.25),
				]),
				_make("Stone Troll", "weak", 120, 18, 25, 10, 20, [
					_drop("Troll Hide", 0.45),
					_drop("Stone Club", 0.25),
				]),
				_make("Bandit", "weak", 60, 14, 22, 8, 18, [
					_drop("Bandit Hood", 0.45),
					_drop("Stolen Goods", 0.25),
				]),
			],
			"medium": [
				_make("Dark Druid", "medium", 110, 30, 80, 30, 60, [
					_drop("Druid Staff", 0.25),
					_drop("Dark Rune", 0.10),
					_drop("Druid Cloak", 0.10),
					_drop("Corrupted Seed", 0.03),
				]),
				_make("Werewolf", "medium", 130, 35, 85, 28, 55, [
					_drop("Werewolf Claw", 0.45),
					_drop("Werewolf Pelt", 0.25),
					_drop("Werewolf Fang", 0.10),
					_drop("Moon Stone", 0.03),
				]),
				_make("Giant Spider", "medium", 100, 28, 75, 25, 50, [
					_drop("Spider Silk", 0.45),
					_drop("Spider Fang", 0.25),
					_drop("Venom Gland", 0.10),
					_drop("Spider Eye Cluster", 0.03),
				]),
			],
			"strong": [
				_make("Elder Druid", "strong", 180, 45, 130, 50, 90, [
					_drop("Druid Staff", 0.45),
					_drop("Elder Rune", 0.10),
					_drop("Nature Crown", 0.03),
					_drop("Heart of the Wood", 0.01),
				]),
				_make("Vampire", "strong", 160, 48, 120, 45, 85, [
					_drop("Vampire Fang", 0.45),
					_drop("Blood Vial", 0.25),
					_drop("Vampire Cape", 0.10),
					_drop("Crimson Ring", 0.03),
				]),
				_make("Poison Golem", "strong", 200, 40, 125, 48, 88, [
					_drop("Golem Core", 0.25),
					_drop("Poison Stone", 0.10),
					_drop("Toxic Shard", 0.03),
					_drop("Venom Heart", 0.01),
				]),
			],
			"elite": [
				_make("The Rotfather", "elite", 650, 70, 500, 200, 400, [
					_drop("Druid Staff", 0.90),
					_drop("Werewolf Claw", 0.90),
					_drop("Rotwood Bark", 0.45),
					_drop("Rotfather Eye", 0.10),
					_drop("Heart of Rot", 0.03),
				]),
			],
		},

		"Ashfield Ruins": {
			"weak": [
				_make("Skeleton", "weak", 80, 20, 35, 12, 24, [
					_drop("Bone", 0.45),
					_drop("Skull", 0.25),
					_drop("Rusty Sword", 0.10),
				]),
				_make("Zombie", "weak", 90, 18, 32, 10, 22, [
					_drop("Rotten Flesh", 0.45),
					_drop("Zombie Hand", 0.25),
					_drop("Brain Matter", 0.10),
				]),
				_make("Ghost", "weak", 70, 22, 38, 14, 26, [
					_drop("Ectoplasm", 0.45),
					_drop("Soul Shard", 0.25),
					_drop("Ghost Veil", 0.10),
				]),
			],
			"medium": [
				_make("Vampire", "medium", 160, 38, 90, 35, 65, [
					_drop("Vampire Fang", 0.45),
					_drop("Blood Vial", 0.25),
					_drop("Vampire Cape", 0.10),
					_drop("Crimson Ring", 0.03),
				]),
				_make("Dark Knight", "medium", 180, 42, 95, 38, 70, [
					_drop("Dark Knight Helm", 0.25),
					_drop("Shadow Steel", 0.10),
					_drop("Cursed Shield", 0.10),
					_drop("Knight Soul", 0.03),
				]),
				_make("Bone Golem", "medium", 200, 38, 88, 32, 62, [
					_drop("Golem Bone", 0.45),
					_drop("Golem Core", 0.25),
					_drop("Ancient Marrow", 0.10),
					_drop("Bone Rune", 0.03),
				]),
			],
			"strong": [
				_make("Lich", "strong", 280, 60, 180, 70, 130, [
					_drop("Lich Dust", 0.45),
					_drop("Lich Robe", 0.25),
					_drop("Lich Staff", 0.10),
					_drop("Soul Gem", 0.03),
					_drop("Lich Crown", 0.01),
				]),
				_make("Death Knight", "strong", 300, 65, 190, 75, 140, [
					_drop("Dark Knight Helm", 0.45),
					_drop("Death Blade", 0.25),
					_drop("Shadow Armor", 0.10),
					_drop("Death Seal", 0.03),
				]),
				_make("Shadow Beast", "strong", 260, 70, 185, 68, 128, [
					_drop("Shadow Essence", 0.45),
					_drop("Dark Claw", 0.25),
					_drop("Void Shard", 0.10),
					_drop("Shadow Heart", 0.03),
				]),
			],
			"elite": [
				_make("The Ashen King", "elite", 900, 95, 750, 350, 600, [
					_drop("Lich Dust", 0.90),
					_drop("Dark Knight Helm", 0.90),
					_drop("Ashen Crown Fragment", 0.45),
					_drop("Ashen King Robe", 0.10),
					_drop("Crown of Ash", 0.03),
				]),
			],
		},

		"The Abyssal Depths": {
			"weak": [
				_make("Vampire", "weak", 160, 30, 50, 20, 40, [
					_drop("Vampire Fang", 0.45),
					_drop("Blood Vial", 0.25),
				]),
				_make("Bone Golem", "weak", 200, 28, 45, 18, 36, [
					_drop("Golem Bone", 0.45),
					_drop("Golem Core", 0.25),
				]),
				_make("Shadow Beast", "weak", 260, 35, 55, 22, 44, [
					_drop("Shadow Essence", 0.45),
					_drop("Dark Claw", 0.25),
				]),
			],
			"medium": [
				_make("Demon Scout", "medium", 320, 75, 200, 80, 150, [
					_drop("Demon Hide", 0.45),
					_drop("Demon Claw", 0.25),
					_drop("Infernal Shard", 0.10),
					_drop("Demon Eye", 0.03),
				]),
				_make("Abyssal Crawler", "medium", 300, 70, 190, 75, 140, [
					_drop("Crawler Shell", 0.45),
					_drop("Abyssal Acid", 0.25),
					_drop("Crawler Fang", 0.10),
					_drop("Void Residue", 0.03),
				]),
				_make("Mind Flayer", "medium", 280, 80, 210, 85, 160, [
					_drop("Flayer Tentacle", 0.45),
					_drop("Psychic Crystal", 0.25),
					_drop("Mind Shard", 0.10),
					_drop("Flayer Brain", 0.03),
				]),
			],
			"strong": [
				_make("Pit Demon", "strong", 500, 110, 350, 150, 280, [
					_drop("Demon Heart", 0.45),
					_drop("Demon Hide", 0.25),
					_drop("Infernal Core", 0.10),
					_drop("Pit Lord Seal", 0.03),
					_drop("Demon Soul", 0.01),
				]),
				_make("Void Walker", "strong", 480, 115, 360, 155, 290, [
					_drop("Void Shard", 0.45),
					_drop("Void Essence", 0.25),
					_drop("Walker Rune", 0.10),
					_drop("Abyssal Heart", 0.03),
				]),
				_make("Abyssal Horror", "strong", 520, 120, 370, 160, 300, [
					_drop("Horror Flesh", 0.45),
					_drop("Abyssal Shard", 0.25),
					_drop("Horror Eye", 0.10),
					_drop("Horror Core", 0.03),
					_drop("Void Crown", 0.01),
				]),
			],
			"elite": [
				_make("The Void Sovereign", "elite", 1500, 160, 1500, 800, 1500, [
					_drop("Demon Heart", 0.90),
					_drop("Abyssal Shard", 0.90),
					_drop("Void Sigil Fragment", 0.45),
					_drop("Sovereign Scale", 0.10),
					_drop("Crown of the Void", 0.03),
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
	
	# These do not add up to 100. The remainder is going to be the elite chance
	if (eventCount <= 15):
		weakChance = 95; mediumChance = 5; strongChance = 0 # No elite chance
	elif (eventCount <= 40):
		weakChance = 80; mediumChance = 15; strongChance = 4 # 1% elite chance...
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
