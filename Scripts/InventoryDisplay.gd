extends Panel
class_name InventoryDisplay

@export var itemFlow: HFlowContainer
@export var weightLabel: Label
@export var spacesLabel: Label
@export var inventorySystem:InventorySystem

var main:MainNode
var longPressTimer: Timer
var longPressTarget: String = ""
var isPressingDown: bool = false
const LONG_PRESS_DURATION: float = 0.5
var longPressQty: int = 0
var longPressStackIndex: int = -1

func _ready() -> void:
	main = Utils.get_main()
	GameEvents.backpackChanged.connect(refresh)
	GameEvents.weightChanged.connect(refreshWeight)

	longPressTimer = Timer.new()
	longPressTimer.one_shot = true
	longPressTimer.wait_time = LONG_PRESS_DURATION
	longPressTimer.timeout.connect(onLongPress)
	add_child(longPressTimer)

	refresh()
	refreshWeight()

func refresh() -> void:
	for child in itemFlow.get_children():
		child.free()

	if main.game_data.backpack.is_empty():
		var emptyLabel = Label.new()
		emptyLabel.text = "Empty"
		emptyLabel.add_theme_color_override("font_color", Color("#888888"))
		itemFlow.add_child.call_deferred(emptyLabel)
		return

	for i in main.game_data.backpack.size():
		var stack = main.game_data.backpack[i]
		var itemName = stack.get("name", "")
		var grade = stack.get("grade", "")
		var qty = stack.get("qty", 1)
		var item = ItemRegistry.getItem(itemName)
		if not item:
			continue

		var btn = Button.new()
		var cap = ItemRegistry.getStackCap(itemName)
		if item.stackable and qty > 1:
			btn.text = " %s %d/%d " % [itemName, qty, cap]
		else:
			if (grade):
				btn.text = " %s [%s] " % [itemName, grade]
			else:
				btn.text = " %s" % [itemName]

		btn.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
		var color = getColorForType(item.itemType)
		btn.add_theme_color_override("font_color", color)
		btn.add_theme_font_size_override("font_size", 22)
		btn.custom_minimum_size = Vector2(150, 60)

		# Bind stack index i so we always know which exact stack was pressed
		btn.button_down.connect(onItemButtonDown.bind(itemName, i))
		btn.button_up.connect(onItemButtonUp.bind(itemName, item.itemType))
		itemFlow.add_child(btn)

	spacesLabel.text = "(%d / %d)" % [main.game_data.backpack.size(), main.game_data.backpackMax]

func refreshWeight() -> void:
	weightLabel.text = "Weight: %.1f / %.1f" % [
		main.game_data.currentWeight,
		main.game_data.maxWeight
	]

func getColorForType(itemType: String) -> Color:
	match itemType:
		"equipment":  return Color("#e74c3c")
		"part":       return Color("82b6bfff")
		"forageable": return Color("#27ae60")
		"ore":        return Color("a5997eff")
		"potion":     return Color("#8e44ad")
		_:            return Color("#cccccc")

func onItemSinglePressed(itemName: String, itemType: String) -> void:
	if (longPressTimer.time_left > 0):
		return
	if (itemType == "potion"):
		GameEvents.itemInspected.emit(itemName)
		GameEvents.potionUsed.emit(itemName)

func onItemButtonDown(itemName: String, stackIndex: int) -> void:
	isPressingDown = true
	longPressTarget = itemName
	longPressStackIndex = stackIndex
	longPressTimer.start()

func onItemButtonUp(itemName: String, itemType: String) -> void:
	isPressingDown = false
	if not longPressTimer.is_stopped():
		longPressTimer.stop()
		# Was a short tap
		if itemType == "potion":
			call_deferred("emitPotionUsed", itemName)

func emitPotionUsed(itemName: String) -> void:
	GameEvents.potionUsed.emit(itemName)

func onLongPress() -> void:
	if not isPressingDown or longPressTarget == "":
		return
	
	var qty = 0
	if longPressStackIndex >= 0 and longPressStackIndex < main.game_data.backpack.size():
		qty = main.game_data.backpack[longPressStackIndex].get("qty", 1)
	isPressingDown = false
	GameEvents.itemLongPressed.emit(longPressTarget, qty, longPressStackIndex)
	longPressTarget = ""
	longPressStackIndex = -1
