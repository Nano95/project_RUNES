extends Node
class_name MerchantSystem

const STOCK: Array[Dictionary] = [
	# Potions
	{ "name": "Minor Health Potion", "category": "potion",    "cost": 20  },
	{ "name": "Minor Battle Potion", "category": "potion",    "cost": 20  },
	{ "name": "Minor Foraging Potion", "category": "potion",    "cost": 20  },
	{ "name": "Health Potion",     "category": "potion",    "cost": 10 }, # CHEAP FOR NOW
	# Equipment
	{ "name": "Wooden Shield",      "category": "equipment", "cost": 80  },
	{ "name": "Crude Blade",        "category": "equipment", "cost": 90  },
	{ "name": "Leather Helmet",     "category": "equipment", "cost": 120 },
	{ "name": "Leather Armor",      "category": "equipment", "cost": 150 },
	{ "name": "Reinforced Boots",   "category": "equipment", "cost": 100 },
	{ "name": "Ring of Protection", "category": "equipment", "cost": 200 },
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
		GameEvents.eventLogged.emit(
			"Can't carry %s — too heavy or no space." % itemName, "system", false
		)
		return false

	main.game_data.savedGold -= entry["cost"]
	main.save_game()
	GameEvents.eventLogged.emit(
		"Purchased %s for %d gold." % [itemName, entry["cost"]], "town", false
	)
	GameEvents.goldDeposited.emit(0)  # triggers gold display refresh
	return true
