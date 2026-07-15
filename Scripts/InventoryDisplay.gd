extends Panel
class_name InventoryDisplay

@export var itemFlow: HFlowContainer
@export var weightLabel: Label
@export var spacesLabel: Label
@export var inventorySystem:InventorySystem

var main:MainNode
var longPressTimer: Timer
var longPressTarget: String = ""
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
	for child in itemFlow.get_children():
		child.queue_free()

	var stacked = inventorySystem.getStackedView(main.game_data.backpack)

	if stacked.is_empty():
		var emptyLabel = Label.new()
		emptyLabel.text = "Empty"
		emptyLabel.add_theme_color_override("font_color", Color("#888888"))
		itemFlow.add_child(emptyLabel)
		return

	for entry in stacked:
		var btn = Button.new()
		# Show qty / cap for stackable items
		if entry["stackable"] and entry["qty"] > 1:
			btn.text = "%s %d/%d" % [entry["name"], entry["qty"], entry["cap"]]
		else:
			btn.text = entry["name"]
		btn.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
		var color = getColorForType(entry["type"])
		btn.add_theme_color_override("font_color", color)
		if entry["type"] == "potion":
			btn.button_up.connect(onItemButtonUp.bind(entry["name"], entry["type"]))
		btn.button_down.connect(onItemButtonDown.bind(entry["name"]))
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
		"part":       return Color("#888888")
		"forageable": return Color("#27ae60")
		"ore":        return Color("#aaaaaa")
		"potion":     return Color("#8e44ad")
		_:            return Color("#cccccc")

func onItemSinglePressed(itemName: String, itemType: String) -> void:
	if (longPressTimer.time_left > 0):
		print("longPressTimer.time_left return")
		return
	if (itemType == "potion"):
		GameEvents.itemInspected.emit(itemName)
		GameEvents.potionUsed.emit(itemName)

func onItemButtonDown(itemName: String) -> void:
	longPressTarget = itemName
	longPressTimer.start()

func onItemButtonUp(itemName: String, itemType: String) -> void:
	if longPressTimer.is_stopped():
		# Timer already fired = long press, do nothing here
		return
	longPressTimer.stop()
	# Short tap
	if itemType == "potion":
		GameEvents.potionUsed.emit(itemName)

func onLongPress() -> void:
	if longPressTarget == "":
		return
	GameEvents.itemLongPressed.emit(longPressTarget)
	longPressTarget = ""
