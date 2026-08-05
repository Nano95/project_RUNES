extends ColorRect
class_name StorageDisplay

@export var backpackFlow: HFlowContainer
@export var backpackTitleCap: Label
@export var backpackWeightLabel: Label
@export var quickDeposit: Button
@export var depositAll: Button
@export var chestFlow: HFlowContainer
@export var chestCapacityLabel: Label
@export var chestNameLabel: Label
@export var chestGrid: HBoxContainer

@export var upgradeLabel: Label
@export var upgradeDetails: RichTextLabel
@export var buildButton: Button
@export var closeButton: Button
@export var chestSystem: ChestSystem
@export var inventorySystem: InventorySystem

var main:MainNode

var selectedChestId: int = 1
var longPressChestIndex: int = -1
var tapChestIndex: int = -1
var longPressTimer: Timer
var longPressTarget: String = ""
var longPressSource: String = ""  # "backpack" or "chest"
var longPressQty: int = 0
const LONG_PRESS_DURATION: float = 0.4

func _ready() -> void:
	main = Utils.get_main()
	GameEvents.backpackChanged.connect(refresh)
	GameEvents.chestChanged.connect(refresh)
	GameEvents.chestUnlocked.connect(onChestUnlocked)
	GameEvents.chestUpgraded.connect(onChestUpgraded)
	quickDeposit.pressed.connect(func():
		Utils.animateButtonPress(quickDeposit)
		chestSystem.quickDeposit(selectedChestId)
		call_deferred("refresh")
	)
	depositAll.pressed.connect(func():
		Utils.animateButtonPress(depositAll)
		chestSystem.depositAll(selectedChestId)
		call_deferred("refresh")
	)

	longPressTimer = Timer.new()
	longPressTimer.one_shot = true
	longPressTimer.wait_time = LONG_PRESS_DURATION
	longPressTimer.timeout.connect(onLongPress)
	add_child(longPressTimer)

	closeButton.pressed.connect(close)
	buildButton.pressed.connect(onBuildPressed)

	_buildChestGrid()
	hide()

func close() -> void:
	Utils.animate_modal_exit(self)

func open() -> void:
	# Only accessible in town
	if main.game_data.inArea:
		return
	selectedChestId = 1
	refresh()
	Utils.animate_modal_entry(self)

var isRefreshing: bool = false
func refresh() -> void:
	if isRefreshing:
		return
	isRefreshing = true
	refreshBackpack()
	refreshChest()
	refreshUpgradePanel()
	isRefreshing = false

# ── BACKPACK ─────────────────────────────────────────────
func refreshBackpack() -> void:
	for child in backpackFlow.get_children():
		child.queue_free()

	backpackWeightLabel.text = "%.1f / %.1f oz" % [
		main.game_data.currentWeight,
		main.game_data.maxWeight
	]
	
	var stacked = _getStacked(main.game_data.backpack)
	if stacked.is_empty():
		var lbl = Label.new()
		lbl.text = "Empty"
		lbl.add_theme_color_override("font_color", Color("#888888"))
		backpackFlow.add_child(lbl)
		return
	
	backpackTitleCap.text = "Backpack (%d / %d)" % [main.game_data.backpack.size(), main.game_data.backpackMax]
	for i in stacked.size():
		var btn = _makeItemButton(stacked[i], "backpack", i)
		backpackFlow.add_child(btn)

# ── CHEST ────────────────────────────────────────────────
func refreshChest() -> void:
	for child in chestFlow.get_children():
		child.queue_free()

	var chest = chestSystem.getChest(selectedChestId)
	if not chest or not chest.unlocked:
		chestNameLabel.text = "Chest %d (Locked)" % selectedChestId
		chestCapacityLabel.text = ""
		return

	var capacity = chestSystem.getCapacity(chest)
	chestNameLabel.text = "Chest %d" % selectedChestId
	chestCapacityLabel.text = "Chest %d (%d / %d)" % [selectedChestId, chest.items.size(), capacity]

	var stacked = _getStacked(chest.items)
	if stacked.is_empty():
		var lbl = Label.new()
		lbl.text = "Empty"
		lbl.add_theme_color_override("font_color", Color("#888888"))
		chestFlow.add_child(lbl)
		return

	for i in stacked.size():
		var btn = _makeItemButton(stacked[i], "chest", i)
		chestFlow.add_child(btn)

# ── UPGRADE PANEL ────────────────────────────────────────
func refreshUpgradePanel() -> void:
	var chest = chestSystem.getChest(selectedChestId)
	if not chest or not chest.unlocked:
		upgradeLabel.text = ""
		upgradeDetails.text = ""
		buildButton.visible = false
		return

	var upgrade = chestSystem.getNextUpgrade(chest)
	if upgrade.is_empty():
		upgradeLabel.text = "Max level reached"
		upgradeDetails.text = ""
		buildButton.visible = false
		return

	upgradeLabel.text = upgrade["label"] + " (+5 slots)"
	var details = "[color=#c8880a]%d gold[/color]" % upgrade["goldCost"]
	for matName in upgrade["materials"]:
		var qty = upgrade["materials"][matName]
		var have = chestSystem.countMaterialAnywhere(matName)
		var newColor = "#27ae60" if have >= qty else "#e74c3c"
		details += "\n[color=%s]%dx %s (%d owned)[/color]" % [newColor, qty, matName, have]
	upgradeDetails.bbcode_enabled = true
	upgradeDetails.text = details
	buildButton.visible = true
	buildButton.disabled = not chestSystem.canUpgrade(chest)

# ── CHEST GRID ───────────────────────────────────────────
func _buildChestGrid() -> void:
	for child in chestGrid.get_children():
		child.queue_free()

	for i in range(main.game_data.chests.size()):
		var chest = main.game_data.chests[i]
		var btn = Button.new()
		btn.text = "C%d" % chest.id
		if not chest.unlocked:
			var cost = ChestSystem.UNLOCK_COSTS[chest.id - 1]
			btn.text += "\n🔒\n %dg" % cost
		btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		btn.add_theme_font_size_override("font_size", 30)
		btn.pressed.connect(onChestSelected.bind(chest.id))
		chestGrid.add_child(btn)

func onChestSelected(chestId: int) -> void:
	var chest = chestSystem.getChest(chestId)
	if not chest:
		return
	if not chest.unlocked:
		# Try to unlock
		chestSystem.unlockChest(chestId)
		_buildChestGrid()
		return
	selectedChestId = chestId
	refresh()

func onChestUnlocked(_chestId: int) -> void:
	_buildChestGrid()
	refresh()

func onChestUpgraded(_chestId: int) -> void:
	refresh()

func onBuildPressed() -> void:
	Utils.animateButtonPress(buildButton)
	var chest = chestSystem.getChest(selectedChestId)
	if chest:
		chestSystem.upgradeChest(chest)

# ── ITEM BUTTONS ─────────────────────────────────────────
func _makeItemButton(entry: Dictionary, source: String, stackIndex: int) -> Button:
	var btn = Button.new()
	var cap = entry.get("cap", 1)
	if (entry["qty"] > 1):
		btn.text = " %s %d/%d " % [entry["name"], entry["qty"], cap]
	else:
		btn.text = " " + entry["name"] + " "
	btn.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	var newColor = getColorForType(entry["type"])
	btn.add_theme_color_override("font_color", newColor)
	btn.add_theme_font_size_override("font_size", 22)
	btn.custom_minimum_size = Vector2(150,50)
	btn.button_down.connect(onItemButtonDown.bind(entry["name"], source, stackIndex))
	btn.button_up.connect(onItemButtonUp.bind(entry["name"], source, stackIndex))
	return btn

func onItemButtonDown(itemName: String, source: String, stackIndex: int) -> void:
	longPressTarget = itemName
	longPressSource = source
	longPressChestIndex = stackIndex if source == "chest" else -1
	longPressTimer.start()
	# Capture qty from the specific stack
	if source == "chest":
		var chest = chestSystem.getChest(selectedChestId)
		if (chest and stackIndex >= 0 and stackIndex < chest.items.size()):
			longPressQty = chest.items[stackIndex].get("qty", 1)
		else:
			longPressQty = 1
	else:
		# Backpack — read from backpack stack
		if (stackIndex >= 0 and stackIndex < main.game_data.backpack.size()):
			longPressQty = main.game_data.backpack[stackIndex].get("qty", 1)
		else:
			longPressQty = 1

func onItemButtonUp(itemName: String, source: String, stackIndex: int) -> void:
	if longPressTimer.is_stopped():
		return
	longPressTimer.stop()
	# Single tap — move 1
	if source == "backpack":
		chestSystem.moveToChest(itemName, selectedChestId, false, 1)
	else:
		chestSystem.moveToBackpackFromIndex(itemName, selectedChestId, stackIndex, 1)

func onLongPress() -> void:
	if longPressTarget == "" or longPressQty <= 0:
		return
	if longPressSource == "backpack":
		chestSystem.moveToChest(longPressTarget, selectedChestId, false, longPressQty)
	else:
		chestSystem.moveToBackpackFromIndex(longPressTarget, selectedChestId, longPressChestIndex, longPressQty)

	longPressTarget = ""
	longPressQty = 0
	longPressSource = ""

# ── HELPERS ──────────────────────────────────────────────
func _getStacked(items: Array) -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	for stack in items:
		var itemName = stack.get("name", "")
		var item = ItemRegistry.getItem(itemName)
		if not item:
			push_warning("Unknown item in chest: %s" % itemName)
			GameEvents.eventLogged.emit(
				"Unknown item in chest: %s" % itemName, "system", false
			)
			continue
		
		if stack.get("type") == "equipment" or ItemRegistry.getEquipmentDef(stack.get("name", "")) != null:
			if not stack.has("isEquipment"):
				push_warning("Equipment missing instance data: %s" % stack.get("name"))
				GameEvents.eventLogged.emit(
					"Equipment missing instance data: %s" % stack.get("name"), "system", false
				)
				continue
		
		if stack.get("isEquipment", false):
			# Equipment — show as individual instance with full data
			result.append({
				"name": itemName,
				"qty": 1,
				"type": "equipment",
				"cap": 1,
				"isEquipment": true,
				"instanceId": stack.get("instanceId", ""),
				"statBonus": stack.get("statBonus", 0),
			})
		else:
			result.append({
				"name": itemName,
				"qty": stack.get("qty", 1),
				"type": item.itemType,
				"cap": ItemRegistry.getStackCap(itemName)
			})
	return result

func getColorForType(itemType: String) -> Color:
	match itemType:
		"equipment":  return Color("#e74c3c")
		"part":       return Color("82b6bfff")
		"forageable": return Color("#27ae60")
		"ore":        return Color("a5997eff")
		"potion":     return Color("#8e44ad")
		_:            return Color("#cccccc")
