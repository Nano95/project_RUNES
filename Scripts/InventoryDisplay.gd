extends Panel
class_name InventoryDisplay

@export var itemFlow: HFlowContainer
@export var weightLabel: Label
@export var spacesLabel: Label
@export var inventorySystem: InventorySystem

var main: MainNode
var buttonMap: Dictionary = {}  # itemName -> Button for stackables, instanceId -> Button for equipment

# Long press
var longPressTimer: Timer
var longPressTarget: String = ""
var longPressStackIndex: int = -1
var longPressQty: int = 0
var isPressingDown: bool = false
const LONG_PRESS_DURATION: float = 0.5
var longPressInstanceId: String = ""

func _ready() -> void:
	main = Utils.get_main()

	# Targeted signals — no more backpackChanged
	#GameEvents.backpackChanged.connect(refresh)
	GameEvents.itemStackUpdated.connect(onItemStackUpdated)
	GameEvents.itemStackAdded.connect(onItemStackAdded)
	GameEvents.itemStackRemoved.connect(onItemStackRemoved)
	GameEvents.equipmentAdded.connect(onEquipmentAdded)
	GameEvents.equipmentRemoved.connect(onEquipmentRemoved)
	GameEvents.weightChanged.connect(refreshWeight)

	longPressTimer = Timer.new()
	longPressTimer.one_shot = true
	longPressTimer.wait_time = LONG_PRESS_DURATION
	longPressTimer.timeout.connect(onLongPress)
	add_child(longPressTimer)

	refreshWeight()

# ── INITIAL BUILD ─────────────────────────────────────────
func buildInventory() -> void:
	for child in itemFlow.get_children():
		child.free()
	buttonMap.clear()

	if main.game_data.backpack.is_empty():
		_showEmptyLabel()
		return

	for i in main.game_data.backpack.size():
		var stack = main.game_data.backpack[i]
		var btn = _makeButton(stack, i)
		if btn:
			itemFlow.add_child(btn)
			var key = stack.get("instanceId", "") if stack.get("isEquipment", false) else stack.get("name", "")
			buttonMap[key] = btn

	_updateSpacesLabel()
	refreshWeight()

# ── TARGETED UPDATES ──────────────────────────────────────
func onItemStackUpdated(itemName: String, newQty: int) -> void:
	var btn = buttonMap.get(itemName)
	if not btn or not is_instance_valid(btn):
		return
	var previousQty = btn.get_meta("itemQty", 0)
	var cap = ItemRegistry.getStackCap(itemName)
	btn.text = " %s %d/%d " % [itemName, newQty, cap] if newQty > 1 else " %s " % itemName
	btn.set_meta("itemQty", newQty)
	# Update stack index meta to match current backpack
	_syncStackIndex(itemName, btn)
	
	# Only spawn label if qty increased
	if newQty > previousQty:
		var globalPos = btn.global_position + btn.size / 2
		Utils.spawnFloatingLabelAtPos("+1", Color("#27ae60"), globalPos, false)
	_updateSpacesLabel()

func onItemStackAdded(itemName: String, qty: int) -> void:
	# Remove empty label if present
	_clearEmptyLabel()
	var btn = _makeButtonFromName(itemName, qty)
	itemFlow.add_child(btn)
	buttonMap[itemName] = btn
	_updateSpacesLabel()
	# Floating label after layout
	await get_tree().process_frame
	if is_instance_valid(btn):
		var globalPos = btn.global_position + btn.size / 2
		Utils.spawnFloatingLabelAtPos("+%d" % qty, Color("#27ae60"), globalPos, false)

func onItemStackRemoved(itemName: String) -> void:
	var btn = buttonMap.get(itemName)
	if btn and is_instance_valid(btn):
		btn.queue_free()
	buttonMap.erase(itemName)
	_updateSpacesLabel()
	if buttonMap.is_empty():
		_showEmptyLabel()
	else:
		_syncAllStackIndices()  # ← resync all after removal

func onEquipmentAdded(instance: Dictionary) -> void:
	_clearEmptyLabel()
	var btn = _makeEquipmentButton(instance, main.game_data.backpack.size() - 1)
	itemFlow.add_child(btn)
	var id = instance.get("instanceId", "")
	buttonMap[id] = btn
	_updateSpacesLabel()
	await get_tree().process_frame
	if is_instance_valid(btn):
		var globalPos = btn.global_position + btn.size / 2
		Utils.spawnFloatingLabelAtPos("+1", Color("#27ae60"), globalPos, false)

func onEquipmentRemoved(instanceId: String) -> void:
	var btn = buttonMap.get(instanceId)
	if btn and is_instance_valid(btn):
		btn.free()
	buttonMap.erase(instanceId)
	_updateSpacesLabel()
	if buttonMap.is_empty():
		_showEmptyLabel()
	else:
		_syncAllStackIndices()  # ← resync all after removal

# ── BUTTON BUILDERS ───────────────────────────────────────
func _makeButton(stack: Dictionary, stackIndex: int) -> Button:
	if stack.get("isEquipment", false):
		return _makeEquipmentButton(stack, stackIndex)
	else:
		var itemName = stack.get("name", "")
		var qty = stack.get("qty", 1)
		return _makeStackButtonWithIndex(itemName, qty, stackIndex)

func _makeStackButtonWithIndex(itemName: String, qty: int, stackIndex: int) -> Button:
	var btn = Button.new()
	var item = ItemRegistry.getItem(itemName)
	if not item:
		return btn
	var cap = ItemRegistry.getStackCap(itemName)
	btn.text = " %s %d/%d " % [itemName, qty, cap] if qty > 1 else " %s " % itemName
	btn.set_meta("itemName", itemName)
	btn.set_meta("itemQty", qty)
	btn.set_meta("stackIndex", stackIndex)
	btn.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	btn.add_theme_color_override("font_color", Utils.getColorForType(item.itemType))
	btn.add_theme_font_size_override("font_size", 22)
	btn.button_down.connect(onItemButtonDown.bind(itemName, btn))
	btn.button_up.connect(onItemButtonUp.bind(itemName, item.itemType))
	return btn

func _makeButtonFromName(itemName: String, qty: int) -> Button:
	# Find stack index in backpack
	var stackIndex = -1
	for i in main.game_data.backpack.size():
		if main.game_data.backpack[i].get("name") == itemName:
			stackIndex = i
			break
	return _makeStackButtonWithIndex(itemName, qty, stackIndex)

func _makeEquipmentButton(instance: Dictionary, stackIndex: int) -> Button:
	var btn = Button.new()
	var itemName = instance.get("name", "")
	var grade = instance.get("grade", "")
	var gradeStr = " [%s]" % grade if grade != "" else ""
	var enh = instance.get("enhancement", 0)
	var enhStr = " +%d" % enh if enh > 0 else ""
	btn.text = " %s%s%s " % [itemName, gradeStr, enhStr]
	btn.set_meta("stackIndex", stackIndex)
	btn.set_meta("instanceId", instance.get("instanceId", ""))
	btn.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	btn.add_theme_color_override("font_color", Utils.getColorForType("equipment"))
	btn.add_theme_font_size_override("font_size", 22)
	btn.button_down.connect(func(): onItemButtonDown(itemName, btn))
	btn.button_up.connect(func(): onItemButtonUp(itemName, "equipment"))
	return btn

# ── LONG PRESS ────────────────────────────────────────────
func onItemButtonDown(itemName: String, btn: Button) -> void:
	isPressingDown = true
	longPressTarget = itemName
	longPressStackIndex = btn.get_meta("stackIndex", -1)  # always current
	longPressInstanceId = btn.get_meta("instanceId", "")
	if longPressStackIndex >= 0 and longPressStackIndex < main.game_data.backpack.size():
		longPressQty = main.game_data.backpack[longPressStackIndex].get("qty", 1)
	longPressTimer.start()

func onItemButtonUp(itemName: String, itemType: String) -> void:
	isPressingDown = false
	if not longPressTimer.is_stopped():
		longPressTimer.stop()
		if itemType == "potion" or itemType == "summon":
			call_deferred("emitPotionUsed", itemName)

func emitPotionUsed(itemName: String) -> void:
	GameEvents.potionUsed.emit(itemName)

func onLongPress() -> void:
	if not isPressingDown or longPressTarget == "":
		return
	isPressingDown = false
	GameEvents.itemLongPressed.emit(longPressTarget, longPressQty, longPressStackIndex, longPressInstanceId)
	longPressTarget = ""
	longPressStackIndex = -1
	longPressInstanceId = ""

# ── HELPERS ───────────────────────────────────────────────
func _syncStackIndex(itemName: String, btn: Button) -> void:
	for i in main.game_data.backpack.size():
		if main.game_data.backpack[i].get("name") == itemName:
			btn.set_meta("stackIndex", i)
			return

func _showEmptyLabel() -> void:
	if itemFlow.get_child_count() == 0:
		var lbl = Label.new()
		lbl.text = "Empty"
		lbl.add_theme_color_override("font_color", Color("#888888"))
		lbl.set_meta("isEmpty", true)
		itemFlow.add_child(lbl)

func _clearEmptyLabel() -> void:
	for child in itemFlow.get_children():
		if child.get_meta("isEmpty", false):
			child.free()
			return

func _updateSpacesLabel() -> void:
	if spacesLabel:
		spacesLabel.text = "(%d / %d)" % [main.game_data.backpack.size(), main.game_data.backpackMax]

func refreshWeight() -> void:
	if weightLabel:
		weightLabel.text = "Weight: %.1f / %.1f" % [
			main.game_data.currentWeight,
			main.game_data.getMaxWeight()
		]

func _syncAllStackIndices() -> void:
	for i in main.game_data.backpack.size():
		var stack = main.game_data.backpack[i]
		var key = stack.get("instanceId", "") if stack.get("isEquipment", false) else stack.get("name", "")
		var btn = buttonMap.get(key)
		if btn and is_instance_valid(btn):
			btn.set_meta("stackIndex", i)
