extends Node
class_name ChestSystem

@export var inventorySystem: InventorySystem
var main:MainNode

# Unlock costs in saved gold (never carried gold)
const UNLOCK_COSTS: Array[int] = [0, 500, 1500, 3000, 6000, 12000]

# Upgrade definitions per level
# Each entry: { label, goldCost, materials: { itemName: qty } }
const UPGRADE_TIERS: Array = [
	{
		"label": "Reinforced Chest",
		"goldCost": 200,
		"materials": { "Oak Log": 3 }
	},
	{
		"label": "Studded Chest",
		"goldCost": 400,
		"materials": { "Oak Log": 5 }
	},
	{
		"label": "Iron-Bound Chest",
		"goldCost": 800,
		"materials": { "Oak Log": 5, "Iron Ore": 2 }
	},
	{
		"label": "Reinforced Iron Chest",
		"goldCost": 1500,
		"materials": { "Dark Timber": 3, "Iron Ore": 4 }
	},
	{
		"label": "Vault Chest",
		"goldCost": 3000,
		"materials": { "Dark Timber": 5, "Iron Ore": 5, "Coal": 2 }
	},
]

func _ready() -> void:
	main = Utils.get_main()
	GameEvents.chestItemMoved.connect(onChestItemMoved)

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
func moveToChest(itemName: String, chestId: int, moveAll: bool = false) -> void:

	var chest = getChest(chestId)
	if not chest or not chest.unlocked:
		return

	var qty = 1
	if moveAll:
		qty = inventorySystem.countInBackpack(itemName)
	if qty <= 0:
		return

	var stackCap = ItemRegistry.getStackCap(itemName)

	for i in range(qty):
		if not inventorySystem.removeFromBackpack(itemName, 1):
			break

		# Try to add to an existing incomplete stack first
		var added = false
		for stack in chest.items:
			if stack["name"] == itemName and stack["qty"] < stackCap:
				stack["qty"] += 1
				added = true
				break

		# Only need a new slot if no existing stack had room
		if not added:
			if _chestItemCount(chest) >= getCapacity(chest):
				# No room for a new slot — put item back in backpack
				inventorySystem.addToBackpack(itemName, 1)
				GameEvents.eventLogged.emit(
					"Chest %d is full!" % chestId, "system", false
				)
				break
			chest.items.append({ "name": itemName, "qty": 1 })

	main.save_game()
	GameEvents.backpackChanged.emit()
	GameEvents.chestChanged.emit()

func moveToBackpack(itemName: String, chestId: int, moveAll: bool = false) -> void:
	var chest = getChest(chestId)
	if not chest:
		return

	var qty = 1
	if (moveAll):
		qty = _countInChest(chest, itemName)
	if qty <= 0:
		return

	for i in range(qty):
		var item = ItemRegistry.getItem(itemName)
		if (item):
			if main.game_data.currentWeight + item.weight > main.game_data.maxWeight:
				GameEvents.eventLogged.emit("Backpack too heavy!", "system", false)
				break
		# Remove from chest
		var removed = false
		var j = chest.items.size() - 1
		while j >= 0:
			if chest.items[j]["name"] == itemName:
				chest.items[j]["qty"] -= 1
				if chest.items[j]["qty"] <= 0:
					chest.items.remove_at(j)
				removed = true
				break
			j -= 1
		if not removed:
			break
		inventorySystem.addToBackpack(itemName, 1)

	main.save_game()
	GameEvents.chestChanged.emit()

func _countInChest(chest: ChestData, itemName: String) -> int:
	var count = 0
	for stack in chest.items:
		if (stack["name"] == itemName):
			count += stack["qty"]
	return count

func _chestItemCount(chest: ChestData) -> int:
	# Count total slots used (each stack = 1 slot)
	return chest.items.size()


func onChestItemMoved(_chestId: int) -> void:
	
	main.save_game()
