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
	cancelButton.pressed.connect(hide)
	hide()

func onItemLongPressed(itemName: String) -> void:
	currentItem = itemName
	itemNameLabel.text = itemName
	var itemType = ItemRegistry.getType(itemName)
	equipButton.visible = itemType == "equipment"
	show()

func onEquipPressed() -> void:
	GameEvents.itemEquipped.emit(currentItem)
	hide()

func onDropPressed() -> void:
	inventorySystem.removeFromInventory(currentItem)
	GameEvents.eventLogged.emit("Dropped %s." % currentItem, "system", false)
	hide()

func cancelPressed() -> void:
	hide()
