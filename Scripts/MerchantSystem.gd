extends Node
class_name MerchantSystem

const STOCK: Array[Dictionary] = [
	# Potions
	{ "name": "Minor Health Potion", "category": "potion",    "cost": 17  },
	{ "name": "Minor Battle Potion", "category": "potion",    "cost": 20  },
	{ "name": "Minor Foraging Potion", "category": "potion",    "cost": 20  },
	{ "name": "Health Potion",     "category": "potion",    "cost": 30 }, # CHEAP FOR NOW
	{ "name": "Minor Antidote",     "category": "potion",    "cost": 25 },
	# Equipment
	{ "name": "T1 Map", "category": "equipment", "cost": 150 },
	{ "name": "T1 Survival Gear",    "category": "equipment", "cost": 200 },
	{ "name": "T2 Map",           "category": "equipment", "cost": 500 },
	{ "name": "T2 Survival Gear", "category": "equipment", "cost": 750 },
	{ "name": "Wooden Shield",      "category": "equipment", "cost": 0  },
	{ "name": "Crude Blade",        "category": "equipment", "cost": 0  },
	{ "name": "Leather Helmet",     "category": "equipment", "cost": 0 },
	{ "name": "Leather Armor",      "category": "equipment", "cost": 0 },
	{ "name": "Leather Legs",      "category": "equipment", "cost": 0 },
	{ "name": "Leather Boots",   "category": "equipment", "cost": 0 },
	{ "name": "Orc Helmet",         "category": "equipment", "cost": 0 },
	{ "name": "Orc Armor",          "category": "equipment", "cost": 0 },
	{ "name": "Orc Legs",           "category": "equipment", "cost": 0 },
	{ "name": "Orc Boots",          "category": "equipment", "cost": 0 },
	{ "name": "Orcish Axe",         "category": "equipment", "cost": 0 },
	{ "name": "Orc King Shield",    "category": "equipment", "cost": 0 },
	{ "name": "Slimy Helmet",       "category": "equipment", "cost": 0 },
	{ "name": "Slimy Armor",        "category": "equipment", "cost": 0 },
	{ "name": "Slimy Legs",         "category": "equipment", "cost": 0 },
	{ "name": "Slimy Boots",        "category": "equipment", "cost": 0 },
	{ "name": "Slimy Blade",        "category": "equipment", "cost": 0 },
	{ "name": "Slimy Shield",       "category": "equipment", "cost": 0 },
	{ "name": "Sandling Helmet",    "category": "equipment", "cost": 0 },
	{ "name": "Sandling Armor",     "category": "equipment", "cost": 0 },
	{ "name": "Sandling Legs",      "category": "equipment", "cost": 0 },
	{ "name": "Sandling Boots",     "category": "equipment", "cost": 0 },
	{ "name": "Sandling Blade",     "category": "equipment", "cost": 0 },
	{ "name": "Sandling Shield",    "category": "equipment", "cost": 0 },

	#{ "name": "Ring of Protection", "category": "equipment", "cost": 200 },
]

@export var inventorySystem: InventorySystem

func getStock(category: String) -> Array:
	return STOCK.filter(func(e): return e["category"] == category)

func canAfford(cost: int) -> bool:
	return Utils.get_main().game_data.savedGold >= cost

func buyItem(entry: Dictionary) -> bool:
	var main = Utils.get_main()
	if not canAfford(entry["cost"]):
		GameEvents.eventLogged.emit(
			"Not enough gold to buy %s." % entry["name"], "system", false
		)
		Utils.spawnFloatingLabel(
			"Not enough gold to buy %s." % entry["name"],
			Color("#c0392b"),
			main,
			true
		)
		return false

	var itemName = entry["name"]
	var def = ItemRegistry.getEquipmentDef(itemName)
	var success = false

	if def:
		var instance = ItemRegistry.rollEquipmentInstance(itemName)
		success = inventorySystem.addEquipmentToBackpack(instance)
	else:
		success = inventorySystem.addToBackpack(itemName, 1)

	if not success:
		return false

	main.game_data.savedGold -= entry["cost"]
	main.save_game()
	GameEvents.eventLogged.emit(
		"Purchased %s for %d gold." % [itemName, entry["cost"]], "town", false
	)
	return true
