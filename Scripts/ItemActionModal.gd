extends ColorRect
class_name ItemActionModal

@export var itemNameLabel: Label
@export var equipButton: Button
@export var dropButton: Button
@export var dropAllButton: Button
@export var cancelButton: Button

@export var inventorySystem:InventorySystem
var currentItem: String = ""
var currentStackQty: int = 0
var currentStackIndex: int = -1
var main:MainNode

func _ready() -> void:
	main = Utils.get_main()
	GameEvents.itemLongPressed.connect(onItemLongPressed)
	equipButton.pressed.connect(onEquipPressed)
	dropButton.pressed.connect(onDropPressed)
	dropAllButton.pressed.connect(onDropAllPressed)
	cancelButton.pressed.connect(onClose)
	hide()

func onClose() -> void:
	Utils.animate_modal_exit(self)

func onItemLongPressed(itemName: String, qty: int, stackIndex: int) -> void:
	currentItem = itemName
	currentStackQty = qty
	currentStackIndex = stackIndex
	itemNameLabel.text = itemName
	var itemType = ItemRegistry.getType(itemName)
	equipButton.visible = itemType == "equipment"
	Utils.animate_modal_entry(self)

func onEquipPressed() -> void:
	GameEvents.itemEquipped.emit(currentItem)
	onClose()

func onDropPressed() -> void:
	inventorySystem.removeFromBackpack(currentItem)
	GameEvents.eventLogged.emit("Dropped %s." % currentItem, "system", false)
	onClose()

func onDropAllPressed() -> void:
	if currentItem == "" or currentStackIndex == -1:
		return
	
	# Verify stack still exists at that index
	if currentStackIndex >= main.game_data.backpack.size():
		onClose()
		return
	
	var stack = main.game_data.backpack[currentStackIndex]
	if stack.get("name") != currentItem:
		onClose()
		return

	var item = ItemRegistry.getItem(currentItem)
	if item and not item.stackable:
		# Equipment — remove single instance
		main.game_data.backpack.remove_at(currentStackIndex)
		var weight = item.weight
		main.game_data.currentWeight = max(0.0, main.game_data.currentWeight - weight)
		main.save_game()
		GameEvents.inventoryChanged.emit()
		GameEvents.eventLogged.emit("Dropped %s." % currentItem, "system", false)
		onClose()
		return

	# Remove this specific stack entirely
	var qty = stack.get("qty", 1)
	main.game_data.backpack.remove_at(currentStackIndex)
	var itemData = ItemRegistry.getItem(currentItem)
	if itemData:
		main.game_data.currentWeight = max(
			0.0, main.game_data.currentWeight - (itemData.weight * qty)
		)
	main.save_game()
	GameEvents.backpackChanged.emit()
	GameEvents.weightChanged.emit()
	GameEvents.eventLogged.emit(
		"Dropped %s x%d." % [currentItem, qty], "system", false
	)
	onClose()

func cancelPressed() -> void:
	onClose()
