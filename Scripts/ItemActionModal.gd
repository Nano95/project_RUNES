extends ColorRect
class_name ItemActionModal

@export var itemNameLabel: Label
@export var equipButton: Button
@export var dropButton: Button
@export var cancelButton: Button

@export var inventorySystem:InventorySystem
var currentItem: String = ""

func _ready() -> void:
	GameEvents.itemLongPressed.connect(onItemLongPressed)
	equipButton.pressed.connect(onEquipPressed)
	dropButton.pressed.connect(onDropPressed)
	cancelButton.pressed.connect(onClose)
	hide()

func onClose() -> void:
	Utils.animate_modal_exit(self)

func onItemLongPressed(itemName: String) -> void:
	currentItem = itemName
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

func cancelPressed() -> void:
	onClose()
