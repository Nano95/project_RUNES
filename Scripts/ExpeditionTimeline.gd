# ExpeditionTimeline.gd
extends Node
class_name ExpeditionTimeline

func generateTimeline(duration: int, area: String) -> Array[Dictionary]:
	var timeline: Array[Dictionary] = []
	var hp = 50  # simulate HP as we generate
	
	for i in range(duration):
		if hp <= 0:
			timeline.append(_passedOutEvent())
			break
		var event = _rollEvent(area, hp)
		hp = max(0, hp - event.get("damage", 0))
		event["hpAfter"] = hp
		timeline.append(event)
	
	return timeline

func _rollEvent(area: String, _currentHp: int) -> Dictionary:
	var roll = randi() % 100
	if roll < 15:
		return _emptyEvent()
	elif roll < 25:
		return _goldEvent()
	elif roll < 70:
		return _itemEvent(area)
	elif roll < 85:
		return _monsterEvent(area)
	elif roll < 95:
		return _trapEvent(area)
	else:
		return _dungeonEvent()

func _emptyEvent() -> Dictionary:
	var messages = [
		"A quiet stretch of road.",
		"Nothing but birdsong.",
		"The path is clear.",
	]
	return {
		"type": "empty",
		"title": messages[randi() % messages.size()],
		"description": "",
		"damage": 0,
		"gold": 0,
		"item": "",
		"dungeon": false
	}

func _goldEvent() -> Dictionary:
	var gold = randi_range(10, 30)
	return {
		"type": "gold",
		"title": "Found some gold!",
		"description": "You spot a small pouch of coins on the ground.",
		"damage": 0,
		"gold": gold,
		"item": "",
		"dungeon": false
	}

func _itemEvent(area: String) -> Dictionary:
	var item = _rollLoot(area)
	var qty = _rollItemQty(item)
	var title = "Found: %s" % item if qty == 1 else "Found: %s x%d" % [item, qty]
	return {
		"type": "item",
		"title": title,
		"description": "You come across %s during your expedition." % item,
		"damage": 0,
		"gold": 0,
		"item": item,
		"qty": qty,
		"dungeon": false
	}

func _rollItemQty(itemName: String) -> int:
	var itemDef = ItemRegistry.getItem(itemName)
	if not itemDef:
		return 1
	# Equipment always 1
	if itemDef.itemType == "equipment":
		return 1
	# High value items always 1
	if itemDef.value >= 40:
		return 1
	# Common items get 1-5
	return randi_range(1, 5)

func _monsterEvent(area: String) -> Dictionary:
	var monsters = EXPEDITION_MONSTERS.get(area, ["Unknown Beast"])
	var monsterName = monsters[randi() % monsters.size()]
	var twist = randf()
	var damage = 0
	var title = ""
	var desc = ""

	# coin flip outcome
	var playerWins = randf() > 0.5

	if playerWins:
		if twist > 0.85:
			damage = randi_range(1, 4)
			title = "Narrow Victory: %s" % monsterName
			desc = "You defeat the %s but take %d chip damage." % [monsterName, damage]
		else:
			title = "Flawless: %s" % monsterName
			desc = "You read the %s perfectly and take it down without a scratch." % monsterName
	else:
		damage = randi_range(4, 12)
		title = "Forced to Retreat: %s" % monsterName
		desc = "The %s overpowers you. You escape taking %d damage." % [monsterName, damage]

	return {
		"type": "monster",
		"title": title,
		"description": desc,
		"damage": damage,
		"gold": 0,
		"item": "",
		"dungeon": false
	}

func _trapEvent(area: String) -> Dictionary:
	var traps = TRAP_DATABASE.get(area, [{"name": "A hidden hazard.", "damage": 3}])
	var trap = traps[randi() % traps.size()]

	# 15% avoidance chance
	if randf() < 0.15:
		return {
			"type": "trap",
			"title": "Danger Avoided!",
			"description": "Your instincts kick in and you sidestep the hazard.",
			"damage": 0,
			"gold": 0,
			"item": "",
			"dungeon": false
		}

	return {
		"type": "trap",
		"title": "Watch Out!",
		"description": "%s You lost %d HP." % [trap["name"], trap["damage"]],
		"damage": trap["damage"],
		"gold": 0,
		"item": "",
		"dungeon": false
	}

func _dungeonEvent() -> Dictionary:
	return {
		"type": "dungeon",
		"title": "Dungeon Discovered!",
		"description": "You stumble upon a hidden dungeon entrance. Mark it for later.",
		"damage": 0,
		"gold": 0,
		"item": "",
		"dungeon": true
	}

func _passedOutEvent() -> Dictionary:
	return {
		"type": "empty",
		"title": "Passed Out on the Trail",
		"description": "A kind stranger finds you and brings you somewhere safe.",
		"damage": 0,
		"gold": 0,
		"item": "",
		"dungeon": false
	}

func _rollLoot(area: String) -> String:
	var table = EXPEDITION_LOOT.get(area, [])
	if table.is_empty():
		return ""
	var total = 0
	for entry in table:
		total += entry["weight"]
	var roll = randi() % total
	var cumulative = 0
	for entry in table:
		cumulative += entry["weight"]
		if roll < cumulative:
			return entry["name"]
	return ""

const EXPEDITION_MONSTERS = {
	"Hunting Grounds": ["Orcling", "Orc Grunt", "Orc Runt", "Orc Warrior", "Orc Brute"],
	"Slime Swamps":    ["Small Slime", "Green Slime", "Blue Slime", "Bog Slime", "Toxic Slime"],
}

const TRAP_DATABASE = {
	"Hunting Grounds": [
		{"name": "An orc snare catches your ankle.", "damage": 4},
		{"name": "You stumble into a spike pit.", "damage": 8},
		{"name": "A tripwire triggers a volley of arrows.", "damage": 6},
		{"name": "You stepped on something sharp.", "damage": 2},
		{"name": "A wolf trap snaps shut nearby.", "damage": 5},
		{"name": "You noticed the trap and stepped aside.", "damage": 0},
	],
	"Slime Swamps": [
		{"name": "You sink into a pool of acid slime.", "damage": 7},
		{"name": "Toxic spores fill the air.", "damage": 4},
		{"name": "You slip on slick moss into murky water.", "damage": 3},
		{"name": "A hidden bog swallows your leg.", "damage": 5},
		{"name": "You brushed a venomous swamp plant.", "damage": 6},
		{"name": "You spotted the danger and backed away.", "damage": 0},
	],
}

const EXPEDITION_LOOT = {
	"Hunting Grounds": [
		{"name": "Orc Leather",       "weight": 40},
		{"name": "Copper Ore",        "weight": 30},
		{"name": "Coal",              "weight": 20},
		{"name": "Wild Herb",         "weight": 15},
		{"name": "Red Berry",         "weight": 15},
		{"name": "Bloodroot",         "weight": 10},
		{"name": "Orc General Crest", "weight": 3},
		{"name": "King's Tusk",       "weight": 1},
	],
	"Slime Swamps": [
		{"name": "Slime Gel",         "weight": 45},
		{"name": "Copper Ore",          "weight": 30},
		{"name": "Iron Ore",          "weight": 30},
		{"name": "Coal",              "weight": 20},
		{"name": "Red Berry",         "weight": 10},
		{"name": "Wild Herb",         "weight": 20},
		{"name": "Bloodroot",         "weight": 15},
		{"name": "Slime Core",        "weight": 10},
		{"name": "Royal Gel",         "weight": 2},
	],
}
