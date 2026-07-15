extends Node
class_name InventorySystem

var main:MainNode

func _ready() -> void:
	main = Utils.get_main()
	GameEvents.itemDropped.connect(onItemDropped)
	GameEvents.leveledUp.connect(onLeveledUp)
	GameEvents.potionUsed.connect(onPotionUsed)

func onItemDropped(itemName: String) -> void:
	addToBackpack(itemName)

func onLeveledUp() -> void:
	
	main.game_data.maxWeight += 5.0
	GameEvents.weightChanged.emit()

# ── BACKPACK ─────────────────────────────────────────────
func addToBackpack(itemName: String, qty: int = 1) -> bool:
	
	var item = ItemRegistry.getItem(itemName)
	if not item:
		return false

	var weightToAdd = item.weight * qty
	if (main.game_data.currentWeight + weightToAdd > main.game_data.maxWeight):
		GameEvents.eventLogged.emit(
			"Too heavy! %s left behind." % itemName, "system", false
		)
		return false

	var stackCap = ItemRegistry.getStackCap(itemName)
	var remaining = qty

	# Try to fill existing incomplete stacks first
	for stack in main.game_data.backpack:
		if remaining <= 0:
			break
		if stack["name"] == itemName and stack["qty"] < stackCap:
			var space = stackCap - stack["qty"]
			var toAdd = min(space, remaining)
			stack["qty"] += toAdd
			remaining -= toAdd

	# Create new stacks for remainder
	while remaining > 0:
		var newStackQty = min(remaining, stackCap)
		main.game_data.backpack.append({
			"name": itemName,
			"qty": newStackQty
		})
		remaining -= newStackQty

	main.game_data.currentWeight += weightToAdd
	main.save_game()
	GameEvents.backpackChanged.emit()
	GameEvents.weightChanged.emit()
	return true

func removeFromBackpack(itemName: String, qty: int = 1) -> bool:
	
	if countInBackpack(itemName) < qty:
		return false

	var item = ItemRegistry.getItem(itemName)
	var remaining = qty

	# Remove from stacks back to front
	var i = main.game_data.backpack.size() - 1
	while i >= 0 and remaining > 0:
		var stack = main.game_data.backpack[i]
		if stack["name"] == itemName:
			var toRemove = min(stack["qty"], remaining)
			stack["qty"] -= toRemove
			remaining -= toRemove
			if stack["qty"] <= 0:
				main.game_data.backpack.remove_at(i)
		i -= 1

	if item:
		main.game_data.currentWeight = max(
			0.0, main.game_data.currentWeight - (item.weight * qty)
		)

	main.save_game()
	GameEvents.backpackChanged.emit()
	GameEvents.weightChanged.emit()
	return true

func countInBackpack(itemName: String) -> int:
	
	var count = 0
	for stack in main.game_data.backpack:
		if stack["name"] == itemName:
			count += stack["qty"]
	return count

func hasInBackpack(itemName: String, qty: int = 1) -> bool:
	return countInBackpack(itemName) >= qty

func getBackpackSlotCount() -> int:
	
	return main.game_data.backpack.size()

# ── POTIONS ──────────────────────────────────────────────
func onPotionUsed(itemName: String) -> void:
	
	if main.game_data.hp >= main.game_data.maxHp:
		GameEvents.eventLogged.emit("Already at full HP.", "system", false)
		return
	if not hasInBackpack(itemName):
		return
	var healAmount = getPotionHeal(itemName)
	removeFromBackpack(itemName, 1)
	main.game_data.hp = min(main.game_data.maxHp, main.game_data.hp + healAmount)
	main.save_game()
	GameEvents.eventLogged.emit(
		"Used %s. Restored %d HP." % [itemName, healAmount], "gather", false
	)

func getPotionHeal(itemName: String) -> int:
	match itemName:
		"Berry Extract":      return 15
		"Minor Health Potion":  return 20
		"Health Potion":      return 30
		"Strong Heal Potion": return 50
		#"Herbal Elixir":      return 60
		"Twilight Potion":    return 70
	print("- POTION NOT FOUND: ", itemName)
	return 0

# ── SHARED HELPER ─────────────────────────────────────────
func getStackedView(items: Array) -> Array[Dictionary]:
	# items is already stacked as Array[Dictionary]
	# Just return it enriched with type info for display
	var result: Array[Dictionary] = []
	for stack in items:
		result.append({
			"name": stack["name"],
			"qty": stack["qty"],
			"type": ItemRegistry.getType(stack["name"]),
			"stackable": ItemRegistry.isStackable(stack["name"]),
			"cap": ItemRegistry.getStackCap(stack["name"])
		})
	return result
