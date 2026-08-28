extends Node
class_name BazaarSystem

@export var inventorySystem: InventorySystem

var main:MainNode = null
var bazaarTimer: Timer
var isBazaarActive: bool = false

const BASE_HAGGLE_GREED: float = 0.40
const BASE_SHOPLIFT_CATCH: float = 0.50
const EVENT_WEIGHTS = [
	{ "event": "nothing",     "weight": 40 },
	{ "event": "customer",    "weight": 30 },
	{ "event": "bulk_buyer",  "weight": 10 },
	{ "event": "haggler",     "weight": 12 },
	{ "event": "shoplifter",  "weight": 8  },
]
const EVENT_WEIGHTS_TOTAL = 100

func _ready() -> void:
	main = Utils.get_main()
	bazaarTimer = Timer.new()
	bazaarTimer.wait_time = 1.0
	bazaarTimer.one_shot = false
	bazaarTimer.timeout.connect(onTick)
	add_child(bazaarTimer)

func getCustomerFrequency() -> float:
	var stand = main.game_data.equippedStand
	if stand.is_empty():
		return 1.0
	return 1.0 + stand.get("effects", {}).get("customerFrequency", 0.0)

func getShopliftCatchChance() -> float:
	var lock = main.game_data.equippedLock
	if lock.is_empty():
		return BASE_SHOPLIFT_CATCH
	return BASE_SHOPLIFT_CATCH + lock.get("effects", {}).get("catchChance", 0.0)

func getHaggleSkill() -> float:
	var scale = main.game_data.equippedScale
	if scale.is_empty():
		return 0.0
	return scale.get("effects", {}).get("haggleSkill", 0.0)

func startBazaar() -> void:
	if main.game_data.backpack.is_empty():
		GameEvents.eventLogged.emit(
			"Your backpack is empty. Nothing to sell!", "system", false
		)
		return
	isBazaarActive = true
	bazaarTimer.start()
	GameEvents.bazaarStarted.emit()
	GameEvents.eventLogged.emit(
		"You open your stall. Customers begin to gather...", "town", false
	)

func stopBazaar() -> void:
	isBazaarActive = false
	bazaarTimer.stop()
	GameEvents.bazaarStopped.emit()
	GameEvents.eventLogged.emit(
		"You close your stall for the day.", "town", false
	)

func onTick() -> void:
	if main.game_data.backpack.is_empty():
		stopBazaar()
		GameEvents.eventLogged.emit(
			"You've sold everything! Stall closed.", "town", false
		)
		return
	rollEvent()

func rollEvent() -> void:
	var roll = randi() % EVENT_WEIGHTS_TOTAL
	var cumulative = 0
	var eventName = "nothing"
	for entry in EVENT_WEIGHTS:
		cumulative += entry["weight"]
		if roll < cumulative:
			eventName = entry["event"]
			break

	match eventName:
		"nothing":
			GameEvents.eventLogged.emit(
				"A quiet moment at the stall...", "system", false
			)
		"customer":
			handleCustomer()
		"bulk_buyer":
			handleBulkBuyer()
		"haggler":
			handleHaggler()
		"shoplifter":
			handleShoplifter()

# ── CUSTOMER ──────────────────────────────────────────────
func handleCustomer() -> void:
	var item = getRandomBackpackItem()
	if not item:
		return
	var price = getItemPrice(item)
	sellItem(item, price)
	GameEvents.eventLogged.emit(
		"[color=#cc99ff]Customer[/color] buys %s for %dg." % [
			getItemDisplayName(item), price
		], "town", false
	)

# ── BULK BUYER ────────────────────────────────────────────
func handleBulkBuyer() -> void:
	# Find a stackable item with qty > 1
	var stackableItems = []
	for stack in main.game_data.backpack:
		if stack.get("isEquipment", false):
			continue
		var item = ItemRegistry.getItem(stack.get("name", ""))
		if not item:
			continue
		# Exclude potions and summons
		if item.itemType == "summon":
			continue
		if stack.get("qty", 1) > 1:
			stackableItems.append(stack)

	if stackableItems.is_empty():
		handleCustomer()  # fallback
		return

	var stack = stackableItems[randi() % stackableItems.size()]
	var itemName = stack.get("name", "")
	var totalQty = stack.get("qty", 1)
	var buyQty = randi_range(1, totalQty)
	var basePrice = getStackPrice(itemName, buyQty)
	var bulkMultiplier = randf_range(0.8, 1.4)
	var finalPrice = int(basePrice * bulkMultiplier)

	inventorySystem.removeFromBackpack(itemName, buyQty)
	main.game_data.savedGold += finalPrice
	main.game_data.stats["totalGoldEarned"] += finalPrice
	main.save_game()
	GameEvents.goldDeposited.emit(finalPrice)
	GameEvents.eventLogged.emit(
		"[color=#ffd700]Bulk Buyer[/color] takes %dx %s for %dg (%.1fx)!" % [
			buyQty, itemName, finalPrice, bulkMultiplier
		], "town", false
	)

# ── HAGGLER ───────────────────────────────────────────────
func handleHaggler() -> void:
	var item = getRandomBackpackItem()
	if not item:
		return

	var basePrice = getItemPrice(item)
	var haggleSkill = getHaggleSkill()
	var playerWins = randf() < haggleSkill
	var itemName = getItemDisplayName(item)

	var finalPrice: int
	var outcome: String

	if playerWins:
		finalPrice = int(basePrice * randf_range(1.1, 1.3))
		outcome = "[color=#ff4444]Haggler[/color] tries to lowball for %s, but you hold firm! +%dg" % [finalPrice, itemName]
	else:
		finalPrice = int(basePrice * randf_range(0.7, 0.9))
		outcome = "[color=#ff4444]Haggler[/color] talks you down to %dg for the %s." % [finalPrice, itemName]

	sellItem(item, finalPrice)
	GameEvents.eventLogged.emit(outcome, "town", false)

# ── SHOPLIFTER ────────────────────────────────────────────
func handleShoplifter() -> void:
	var item = getRandomBackpackItem()
	if not item:
		return

	var catchChance = getShopliftCatchChance()
	var caught = randf() < catchChance
	var itemName = getItemDisplayName(item)

	if caught:
		var bounty = randi_range(5, 20)
		main.game_data.savedGold += bounty
		main.game_data.stats["totalGoldEarned"] += bounty
		main.save_game()
		GameEvents.goldDeposited.emit(bounty)
		GameEvents.eventLogged.emit(
			"[color=#ff8800]Shoplifter[/color] caught! +%dg bounty. %s stays." % [
				bounty, itemName
			], "town", false
		)
	else:
		removeItemFromBackpack(item)
		GameEvents.eventLogged.emit(
			"[color=#ff8800]Shoplifter[/color] steals your %s!" % itemName, "danger", false
		)

# ── HELPERS ───────────────────────────────────────────────
func getRandomBackpackItem() -> Dictionary:
	if main.game_data.backpack.is_empty():
		return {}
	return main.game_data.backpack[randi() % main.game_data.backpack.size()]

func getItemPrice(item: Dictionary) -> int:
	var itemName = item.get("name", "")
	var itemDef = ItemRegistry.getItem(itemName)
	var basePrice = itemDef.value if itemDef else 10

	if item.get("isEquipment", false):
		match item.get("grade", ""):
			"SS": return int(basePrice * 4.0)
			"S": return int(basePrice * 2.0)
			"A": return int(basePrice * 1.6)
			"B": return int(basePrice * 1.3)
		return basePrice

	return basePrice

func getStackPrice(itemName: String, qty: int) -> int:
	var itemDef = ItemRegistry.getItem(itemName)
	var basePrice = itemDef.value if itemDef else 10
	return basePrice * qty

func sellItem(item: Dictionary, price: int) -> void:
	removeItemFromBackpack(item)
	main.game_data.savedGold += price
	main.game_data.stats["totalGoldEarned"] += price
	main.save_game()
	GameEvents.goldDeposited.emit(price)
	GameEvents.backpackChanged.emit()

func getItemDisplayName(item: Dictionary) -> String:
	var itemName = item.get("name", "")
	var grade = item.get("grade", "")
	var enh = item.get("enhancement", 0)
	var gradeStr = " [%s]" % grade if grade != "" else ""
	var enhStr = " +%d" % enh if enh > 0 else ""
	
	return "%s%s%s" % [itemName, gradeStr, enhStr]

func removeItemFromBackpack(item: Dictionary) -> void:
	if item.get("isEquipment", false):
		var idx = -1
		for i in main.game_data.backpack.size():
			if main.game_data.backpack[i].get("instanceId", "") == item.get("instanceId", ""):
				idx = i
				break
		if idx != -1:
			main.game_data.backpack.remove_at(idx)
	else:
		inventorySystem.removeFromBackpack(item.get("name", ""), 1)
	
	print(getItemDisplayName(item))
	main.game_data.currentWeight = max(
		0.0, main.game_data.currentWeight - ItemRegistry.getItem(item.get("name", "")).weight
	)
	main.save_game()
	GameEvents.backpackChanged.emit()  # ← add this
	GameEvents.weightChanged.emit()
