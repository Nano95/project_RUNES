extends Node
class_name InventorySystem

var main:MainNode

func _ready() -> void:
	main = Utils.get_main()
	GameEvents.itemDropped.connect(onItemDropped)

func onItemDropped(itemName: String) -> void:
	addToInventory(itemName)

func addToInventory(itemName: String) -> bool:
	if main.game_data.inventory.size() >= main.game_data.inventoryMax:
		GameEvents.eventLogged.emit(
			"Inventory full! %s left behind." % itemName, "system"
		)
		return false
	main.game_data.inventory.append(itemName)
	main.save_game()
	GameEvents.inventoryChanged.emit()
	return true

func removeFromInventory(itemName: String) -> bool:
	var idx = main.game_data.inventory.find(itemName)
	if idx == -1:
		return false
	main.game_data.inventory.remove_at(idx)
	main.save_game()
	GameEvents.inventoryChanged.emit()
	return true

func addToChest(itemName: String) -> bool:
	if main.game_data.chest.size() >= main.game_data.chestMax:
		GameEvents.eventLogged.emit("Chest is full!", "system")
		return false
	main.game_data.chest.append(itemName)
	main.save_game()
	GameEvents.chestChanged.emit()
	return true

func removeFromChest(itemName: String) -> bool:
	var idx = main.game_data.chest.find(itemName)
	if idx == -1:
		return false
	main.game_data.chest.remove_at(idx)
	main.save_game()
	GameEvents.chestChanged.emit()
	return true

func moveToChest(itemName: String) -> void:
	if removeFromInventory(itemName):
		if not addToChest(itemName):
			addToInventory(itemName)

func moveToInventory(itemName: String) -> void:
	if removeFromChest(itemName):
		if not addToInventory(itemName):
			addToChest(itemName)

func storeAll() -> void:
	var toMove = main.game_data.inventory.duplicate()
	for itemName in toMove:
		moveToChest(itemName)

func hasItem(itemName: String) -> bool:
	return main.game_data.inventory.has(itemName)

func countItem(itemName: String) -> int:
	var count = 0
	for item in main.game_data.inventory:
		if item == itemName:
			count += 1
	return count
