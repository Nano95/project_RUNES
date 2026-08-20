extends Panel
class_name CollectionBinDisplay

@export var titleLabel: Label
@export var goldLabel: Label
@export var withdrawAllBtn: Button
@export var autoWithdrawCheckbox: CheckButton
@export var itemsFlow: HFlowContainer
@export var inventorySystem: InventorySystem

var main:MainNode
var isWithdrawing: bool = false

func _ready() -> void:
	main = Utils.get_main()
	GameEvents.expeditionCompleted.connect(onExpeditionCompleted)
	GameEvents.expeditionSynced.connect(refresh)
	withdrawAllBtn.pressed.connect(onWithdrawAllPressed)
	autoWithdrawCheckbox.set_pressed_no_signal(main.game_data.autoWithdrawExpedition)
	autoWithdrawCheckbox.toggled.connect(onAutoWithdrawToggled)

func refresh() -> void:
	if (!get_parent().visible): return
	refreshGold()
	refreshItems()
	# Auto withdraw only once, not recursively
	if main.game_data.autoWithdrawExpedition and \
	   not main.game_data.expeditionInventory.is_empty() and \
	   not isWithdrawing:
		onWithdrawAllPressed()

func refreshGold() -> void:
	var pending = main.game_data.pendingExpeditionGold
	if pending > 0:
		goldLabel.text = "%dg pending" % pending
		goldLabel.visible = true
	else:
		goldLabel.visible = false

func refreshItems() -> void:
	for child in itemsFlow.get_children():
		child.free()

	if main.game_data.expeditionInventory.is_empty() and \
	   main.game_data.pendingExpeditionGold <= 0:
		var lbl = Label.new()
		lbl.text = "Collection bin is empty."
		lbl.add_theme_color_override("font_color", Color("#888888"))
		itemsFlow.add_child(lbl)
		return

	for stack in main.game_data.expeditionInventory:
		var btn = Button.new()
		var qty = stack.get("qty", 1)
		var itemName = stack.get("name", "")
		btn.text = " %s x%d " % [itemName, qty] if qty > 1 else itemName
		btn.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
		btn.add_theme_font_size_override("font_size", 22)
		btn.custom_minimum_size = Vector2(150,50)
		var item = ItemRegistry.getItem(itemName)
		if (item):
			btn.add_theme_color_override("font_color", Utils.getColorForType(item.itemType))
		itemsFlow.add_child(btn)

func onWithdrawAllPressed() -> void:
	print_stack()
	if isWithdrawing:
		return
	isWithdrawing = true
	Utils.animateButtonPress(withdrawAllBtn)
	var remaining: Array[Dictionary] = []
	var anythingWithdrawn = false

	for stack in main.game_data.expeditionInventory:
		var itemName = stack.get("name", "")
		var qty = stack.get("qty", 1)
		var success = inventorySystem.addToBackpack(itemName, qty)
		if success:
			anythingWithdrawn = true
			var qtyStr = " x%d" % qty if qty > 1 else ""
			_logToExpedition("Withdrew: %s%s." % [itemName, qtyStr], "item")
		else:
			remaining.append(stack)
			# Check which reason
			var item = ItemRegistry.getItem(itemName)
			if item and main.game_data.currentWeight + (item.weight * qty) > main.game_data.maxWeight:
				_logToExpedition("%s left in bin — too heavy." % itemName)
			else:
				_logToExpedition("%s left in bin — backpack full." % itemName)

	# Gold
	#var goldCollected = main.game_data.pendingExpeditionGold
	# Commenting out for awareness, im letting _handleExpeditionComplete withdraw the money
	# automatically for convenienceas money does not weigh anything and should never be lost
	# so i want it to be automatic 
	#if goldCollected > 0:
		#main.game_data.savedGold += goldCollected
		#main.game_data.pendingExpeditionGold = 0
		#main.game_data.stats["totalGoldEarned"] += goldCollected
		#GameEvents.goldDeposited.emit(goldCollected)
		#_logToExpedition(
			#"Collected %dg. Bank total: %dg." % [goldCollected, main.game_data.savedGold], 
			#"gold"
		#)

	#if not anythingWithdrawn and remaining.is_empty() and goldCollected <= 0:
	if not anythingWithdrawn and remaining.is_empty():
		GameEvents.eventLogged.emit(
			"Collection bin is empty.", "system", false
		)

	main.game_data.expeditionInventory = remaining
	main.save_game()
	isWithdrawing = false
	refreshGold()
	refreshItems()

func _logToExpedition(message: String, type: String = "empty") -> void:
	GameEvents.expeditionEventFired.emit({
		"type": type,
		"title": message,
		"description": "",
		"damage": 0,
		"gold": 0,
		"item": "",
		"qty": 0,
		"dungeon": false,
		"showNumber": false 
	})

func onAutoWithdrawToggled(pressed: bool) -> void:
	main.game_data.autoWithdrawExpedition = pressed
	main.save_game()

func onExpeditionCompleted(_survived: bool) -> void:
	refresh()
