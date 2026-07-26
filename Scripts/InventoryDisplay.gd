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
	print(" -- refresh bp happening")
	for child in itemFlow.get_children():
		child.queue_free()

	var stacked = inventorySystem.getStackedView(main.game_data.backpack)

	if stacked.is_empty():
		var emptyLabel = Label.new()
		emptyLabel.text = "Empty"
		emptyLabel.add_theme_color_override("font_color", Color("#888888"))
		itemFlow.add_child.call_deferred(emptyLabel)
		itemFlow.add_child(emptyLabel)
		return

	for entry in stacked:
		var btn = Button.new()
		# Show qty / cap for stackable items
		if entry["stackable"] and entry["qty"] > 1:
			btn.text = " %s %d/%d " % [entry["name"], entry["qty"], entry["cap"]]
		else:
			btn.text = " " + entry["name"] + " "
		btn.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
		var color = getColorForType(entry["type"])
		btn.add_theme_color_override("font_color", color)
		btn.add_theme_font_size_override("font_size", 22)
		btn.custom_minimum_size = Vector2(150,60)
		btn.button_down.connect(onItemButtonDown.bind(entry["name"]))
		btn.button_up.connect(onItemButtonUp.bind(entry["name"], entry["type"]))
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

func onItemButtonDown(itemName: String) -> void:
	isPressingDown = true
	longPressTarget = itemName
	longPressTimer.start()

func onItemButtonUp(itemName: String, itemType: String) -> void:
	isPressingDown = false
	if not longPressTimer.is_stopped():
		longPressTimer.stop()
		# Was a short tap
		if itemType == "potion":
			call_deferred("emitPotionUsed", itemName)

func onLongPress() -> void:
	if not isPressingDown or longPressTarget == "":
		return
	isPressingDown = false
	GameEvents.itemLongPressed.emit(longPressTarget)
	longPressTarget = ""
