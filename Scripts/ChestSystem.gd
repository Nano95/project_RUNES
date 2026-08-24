extends Node
class_name ChestSystem

@export var inventorySystem: InventorySystem
@export var equipmentSystem: EquipmentSystem
var main:MainNode

# Unlock costs in saved gold (never carried gold)
const UNLOCK_COSTS: Array[int] = [0, 500, 1500, 3000, 6000, 12000]

# Upgrade definitions per level
# Each entry: { label, goldCost, materials: { itemName: qty } }
const UPGRADE_TIERS: Array = [
	{
		"label": "Reinforced Chest",
		"goldCost": 200,
		"materials": { "Copper Bar": 2 }
	},
	{
		"label": "Studded Chest",
		"goldCost": 400,
		"materials": { "Copper Bar": 5, "Iron Bar": 1 }
	},
	{
		"label": "Iron-Bound Chest",
		"goldCost": 800,
		"materials": { "Iron Bar": 3, "Gold Bar": 1 }
	},
	{
		"label": "Reinforced Iron Chest",
		"goldCost": 1500,
		"materials": { "Gold Bar": 3 }
	},
	{
		"label": "Vault Chest",
		"goldCost": 3000,
		"materials": { "Gold Bar": 5 }
	},
]

func _ready() -> void:
	main = Utils.get_main()
	GameEvents.chestItemMoved.connect(onChestItemMoved)

func emitStorageSignals() -> void:
	GameEvents.backpackChanged.emit()
	GameEvents.chestChanged.emit()
	GameEvents.weightChanged.emit()

# ── CAPACITY ─────────────────────────────────────────────
func getCapacity(chest: ChestData) -> int:
	# Base 15 slots, +5 per upgrade level
	return 15 + (chest.upgradeLevel * 5)

func getChest(chestId: int) -> ChestData:
	
	for chest in main.game_data.chests:
		if chest.id == chestId:
			return chest
	return null

# ── UNLOCK ───────────────────────────────────────────────
func canUnlock(chestId: int) -> bool:
	
	var chest = getChest(chestId)
	if not chest or chest.unlocked:
		return false
	# Previous chest must be unlocked first
	if chestId > 1:
		var previous = getChest(chestId - 1)
		if not previous or not previous.unlocked:
			return false
	var cost = UNLOCK_COSTS[chestId - 1]
	return main.game_data.savedGold >= cost

func unlockChest(chestId: int) -> void:
	if not canUnlock(chestId):
		GameEvents.eventLogged.emit(
			"Cannot unlock chest %d." % chestId, "system", false
		)
		return
	
	var chest = getChest(chestId)
	var cost = UNLOCK_COSTS[chestId - 1]
	main.game_data.savedGold -= cost
	chest.unlocked = true
	main.save_game()
	GameEvents.eventLogged.emit(
		"Chest %d unlocked for %d gold!" % [chestId, cost], "town", false
	)
	GameEvents.chestUnlocked.emit(chestId)

# ── UPGRADE ──────────────────────────────────────────────
func getNextUpgrade(chest: ChestData) -> Dictionary:
	if chest.upgradeLevel >= UPGRADE_TIERS.size():
		return {}
	return UPGRADE_TIERS[chest.upgradeLevel]

func canUpgrade(chest: ChestData) -> bool:
	
	var upgrade = getNextUpgrade(chest)
	if upgrade.is_empty():
		return false
	if main.game_data.savedGold < upgrade["goldCost"]:
		return false
	# Check materials exist in any chest or backpack
	for matName in upgrade["materials"]:
		var needed = upgrade["materials"][matName]
		var have = countMaterialAnywhere(matName)
		if have < needed:
			return false
	return true

func upgradeChest(chest: ChestData) -> void:
	if not canUpgrade(chest):
		GameEvents.eventLogged.emit("Not enough resources to upgrade.", "system", false)
		return
	
	var upgrade = getNextUpgrade(chest)
	# Deduct gold
	main.game_data.savedGold -= upgrade["goldCost"]
	# Consume materials from backpack first, then chests
	for matName in upgrade["materials"]:
		var needed = upgrade["materials"][matName]
		needed = consumeFromBackpack(matName, needed)
		if needed > 0:
			consumeFromChests(matName, needed)
	chest.upgradeLevel += 1
	main.save_game()
	GameEvents.eventLogged.emit(
		"%s! Chest %d now holds %d items." % [
			upgrade["label"],
			chest.id,
			getCapacity(chest)
		], "town", false
	)
	GameEvents.chestUpgraded.emit(chest.id)

# ── MATERIAL HELPERS ──────────────────────────────────────
func countMaterialAnywhere(itemName: String) -> int:
	var count = inventorySystem.countInBackpack(itemName)
	for chest in main.game_data.chests:
		count += _countInChest(chest, itemName)
	return count

func consumeFromBackpack(itemName: String, qty: int) -> int:
	var have = inventorySystem.countInBackpack(itemName)
	var toConsume = min(have, qty)
	if toConsume > 0:
		inventorySystem.removeFromBackpack(itemName, toConsume)
	return qty - toConsume

func consumeFromChests(itemName: String, qty: int) -> void:
	var remaining = qty
	for chest in main.game_data.chests:
		if remaining <= 0:
			break
		var j = chest.items.size() - 1
		while j >= 0 and remaining > 0:
			if chest.items[j]["name"] == itemName:
				var toRemove = min(chest.items[j]["qty"], remaining)
				chest.items[j]["qty"] -= toRemove
				remaining -= toRemove
				if chest.items[j]["qty"] <= 0:
					chest.items.remove_at(j)
			j -= 1
	GameEvents.chestChanged.emit()

# ── ITEM MOVEMENT ─────────────────────────────────────────
func moveToChest(itemName: String, chestId: int, moveAll: bool = false, specificQty: int = 0) -> void:
	var chest = getChest(chestId)
	if not chest or not chest.unlocked:
		return

	var qty = 1
	if moveAll:
		qty = inventorySystem.countInBackpack(itemName)
	elif specificQty > 0:
		qty = specificQty

	if chest.items.size() >= getCapacity(chest):
		GameEvents.eventLogged.emit("Chest %d is full!" % chestId, "system", false)
		return

	# Find backpack stack
	var backpackIdx = -1
	for j in main.game_data.backpack.size():
		if main.game_data.backpack[j].get("name") == itemName:
			backpackIdx = j
			break

	if backpackIdx == -1:
		return

	var backpackStack = main.game_data.backpack[backpackIdx]
	var item = ItemRegistry.getItem(itemName)

	if backpackStack.get("isEquipment", false):
		# Equipment — move full instance
		main.game_data.backpack.remove_at(backpackIdx)
		if item:
			main.game_data.currentWeight = max(
				0.0, main.game_data.currentWeight - item.weight
			)
		chest.items.append(backpackStack)
	else:
		# Stackable — decrement or remove backpack stack
		var actualQty = min(qty, backpackStack.get("qty", 1))
		if backpackStack.get("qty", 1) <= actualQty:
			main.game_data.backpack.remove_at(backpackIdx)
		else:
			main.game_data.backpack[backpackIdx]["qty"] -= actualQty

		if item:
			main.game_data.currentWeight = max(
				0.0, main.game_data.currentWeight - (item.weight * actualQty)
			)

		# Merge into existing chest stack or create new
		var stackCap = ItemRegistry.getStackCap(itemName)
		var remaining = actualQty
		for chestStack in chest.items:
			if chestStack["name"] == itemName and chestStack.get("qty", 0) < stackCap:
				var space = stackCap - chestStack["qty"]
				var toAdd = min(space, remaining)
				chestStack["qty"] += toAdd
				remaining -= toAdd
				if remaining <= 0:
					break
		if remaining > 0:
			chest.items.append({"name": itemName, "qty": remaining})

	main.save_game()
	GameEvents.backpackChanged.emit()
	GameEvents.chestChanged.emit()

func moveToBackpackFromIndex(itemName: String, chestId: int, chestIndex: int, qty: int) -> void:
	var chest = getChest(chestId)
	if not chest or chestIndex < 0 or chestIndex >= chest.items.size():
		return

	var chestStack = chest.items[chestIndex]
	if chestStack.get("name") != itemName:
		return

	var item = ItemRegistry.getItem(itemName)
	if item:
		if main.game_data.currentWeight + (item.weight * qty) > main.game_data.maxWeight:
			GameEvents.eventLogged.emit("Backpack too heavy!", "system", false)
			Utils.spawnFloatingLabel(
				"Too heavy to carry!",
				Color("#c0392b"),
				main,
				true
			)
			return
	if main.game_data.backpack.size() >= main.game_data.backpackMax:
		GameEvents.eventLogged.emit(
			"Backpack full! %s cannot be moved to." % itemName, "system", false
		)
		Utils.spawnFloatingLabel(
			"Backpack is full",
			Color("#c0392b"),
			main,
			true
		)
		return
	if chestStack.get("isEquipment", false):
		chest.items.remove_at(chestIndex)
		main.game_data.backpack.append(chestStack)
		if item:
			main.game_data.currentWeight += item.weight
	else:
		var actualQty = min(qty, chestStack.get("qty", 1))
		if chestStack.get("qty", 1) <= actualQty:
			chest.items.remove_at(chestIndex)
		else:
			chest.items[chestIndex]["qty"] -= actualQty

		if item:
			main.game_data.currentWeight += item.weight * actualQty

		var stackCap = ItemRegistry.getStackCap(itemName)
		var remaining = actualQty
		for backpackStack in main.game_data.backpack:
			if backpackStack.get("name") == itemName and backpackStack.get("qty", 0) < stackCap:
				var space = stackCap - backpackStack["qty"]
				var toAdd = min(space, remaining)
				backpackStack["qty"] += toAdd
				remaining -= toAdd
				if remaining <= 0:
					break
		if remaining > 0:
			main.game_data.backpack.append({"name": itemName, "qty": remaining})

	main.save_game()
	call_deferred("emitStorageSignals")

func _countInChest(chest: ChestData, itemName: String) -> int:
	var count = 0
	for stack in chest.items:
		if (stack["name"] == itemName):
			count += stack["qty"]
	return count

func _chestItemCount(chest: ChestData) -> int:
	# Count total slots used (each stack = 1 slot)
	return chest.items.size()

func quickDeposit(chestId: int) -> void:
	var chest = getChest(chestId)
	if not chest or not chest.unlocked:
		return

	# Get unique item names already in chest
	var chestItems: Array[String] = []
	for stack in chest.items:
		if not chestItems.has(stack["name"]):
			chestItems.append(stack["name"])

	if chestItems.is_empty():
		GameEvents.eventLogged.emit(
			"Chest %d is empty — nothing to match." % chestId, "system", false
		)
		return

	var deposited = 0
	var toMove = main.game_data.backpack.duplicate()

	for stack in toMove:
		var itemName = stack.get("name", "")
		if not chestItems.has(itemName):
			continue
		if chest.items.size() >= getCapacity(chest):
			break

		var qty = stack.get("qty", 1)
		var item = ItemRegistry.getItem(itemName)

		# Update weight
		if item:
			main.game_data.currentWeight = max(
				0.0, main.game_data.currentWeight - (item.weight * qty)
			)

		# Remove from backpack directly
		var idx = main.game_data.backpack.find(stack)
		if idx != -1:
			main.game_data.backpack.remove_at(idx)

		# Add to chest — preserve full instance for equipment
		if stack.get("isEquipment", false):
			chest.items.append(stack)
		else:
			var stackCap = ItemRegistry.getStackCap(itemName)
			var added = false
			for chestStack in chest.items:
				if chestStack["name"] == itemName and chestStack.get("qty", 0) < stackCap:
					var space = stackCap - chestStack["qty"]
					var toAdd = min(space, qty)
					chestStack["qty"] += toAdd
					added = true
					break
			if not added:
				chest.items.append({"name": itemName, "qty": qty})

		deposited += qty

	if deposited > 0:
		main.save_game()
		GameEvents.backpackChanged.emit()
		GameEvents.chestChanged.emit()
		GameEvents.weightChanged.emit()
		GameEvents.eventLogged.emit(
			"Quick deposited %d stacks into Chest %d." % [deposited, chestId], "town", false
		)
	else:
		GameEvents.eventLogged.emit(
			"Nothing to deposit — no matching items found.", "system", false
		)

func depositAll(chestId: int) -> void:
	var chest = getChest(chestId)
	if not chest or not chest.unlocked:
		return
	var deposited = 0
	var toMove = main.game_data.backpack.duplicate()

	for stack in toMove:
		if chest.items.size() >= getCapacity(chest):
			break

		var itemName = stack.get("name", "")
		var qty = stack.get("qty", 1)
		var item = ItemRegistry.getItem(itemName)

		# Handle weight
		if item:
			main.game_data.currentWeight = max(
				0.0, main.game_data.currentWeight - (item.weight * qty)
			)

		# Remove from backpack directly
		var idx = main.game_data.backpack.find(stack)
		if idx != -1:
			main.game_data.backpack.remove_at(idx)

		# Add to chest — preserve full instance for equipment
		if stack.get("isEquipment", false):
			chest.items.append(stack)
		else:
			var added = false
			var stackCap = ItemRegistry.getStackCap(itemName)
			for chestStack in chest.items:
				if chestStack["name"] == itemName and chestStack.get("qty", 0) < stackCap:
					var space = stackCap - chestStack["qty"]
					var toAdd = min(space, qty)
					chestStack["qty"] += toAdd
					added = true
					break
			if not added:
				chest.items.append({"name": itemName, "qty": qty})

		deposited += qty

	if deposited > 0:
		main.save_game()
		GameEvents.backpackChanged.emit()
		GameEvents.chestChanged.emit()
		GameEvents.weightChanged.emit()
		GameEvents.eventLogged.emit(
			"Deposited %d stacks into Chest %d." % [deposited, chestId], "town", false
		)
	else:
		GameEvents.eventLogged.emit("Backpack is empty.", "system", false)

func onChestItemMoved(_chestId: int) -> void:
	
	main.save_game()
