extends ColorRect
class_name ItemActionModal

@export var itemNameLabel: Label
@export var itemDescLabel: Label
@export var equipButton: Button
@export var dropButton: Button
@export var dropAllButton: Button
@export var cancelButton: Button
@export var eventLogPanel: Panel
@export var equipmentPanel: Panel

@export var compareContainer: VBoxContainer
@export var selectedEquipType: Label
@export var selectedEquipTypeValue: Label
@export var equippedName: Label
@export var equippedNameStatValue: Label
@export var compareStats: RichTextLabel

@export var inventorySystem:InventorySystem
@export var equipmentSystem: EquipmentSystem

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
	var equippable:bool = itemType == "equipment"
	dropAllButton.visible = !equippable
	itemDescLabel.visible = !equippable
	equipButton.visible = equippable
	compareContainer.visible = equippable
	if (equippable): showEquipmentComparison(main.game_data.backpack[stackIndex])
	else:
		var item = ItemRegistry.getItem(itemName)
		if item and item.description != "":
			itemDescLabel.visible = true
			itemDescLabel.text = item.description
		else:
			itemDescLabel.visible = false
	
	if (eventLogPanel.visible):
		global_position.y = eventLogPanel.global_position.y
	elif (equipmentPanel.visible):
		global_position.y = equipmentPanel.global_position.y

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

func showEquipmentComparison(instance: Dictionary) -> void:
	if not instance.get("isEquipment", false):
		compareContainer.visible = false
		return

	compareContainer.visible = true
	var slot = instance.get("slot", "")
	var statType = instance.get("statType", "none")
	var statBonus = instance.get("statBonus", 0)
	var enhancement = instance.get("enhancement", 0)
	var totalBonus = statBonus + enhancement
	var enh = " +%d" % enhancement if enhancement > 0 else ""
	var twoHanded = " [2H]" if instance.get("twoHanded", false) else ""

	# Selected item
	itemNameLabel.text = "%s%s%s" % [instance.get("name", ""), enh, twoHanded]
	if statType != "none":
		selectedEquipType.text = "Selected %s" % statType.to_upper()
		selectedEquipTypeValue.text = "+%d" % totalBonus
	else:
		selectedEquipType.text = instance.get("effectType", "")
		selectedEquipTypeValue.text = ""

	# Currently equipped in that slot
	var equipped = equipmentSystem.getEquippedSlot(slot)
	if not equipped or equipped.is_empty():
		equippedName.text = "Slot is empty"
		equippedNameStatValue.text = ""
		compareStats.bbcode_enabled = true
		compareStats.text = "[color=#888888]Nothing equipped[/color]"
	else:
		var curBonus = equipped.get("statBonus", 0) + equipped.get("enhancement", 0)
		var curEnh = " +%d" % equipped.get("enhancement", 0) if equipped.get("enhancement", 0) > 0 else ""
		equippedName.text = "Equipped: %s%s" % [equipped.get("name", ""), curEnh]
		equippedNameStatValue.text = "+%d" % curBonus

		if statType != "none":
			var diff = totalBonus - curBonus
			compareStats.bbcode_enabled = true
			if diff > 0:
				compareStats.text = "[color=#27ae60]▲ +%d %s[/color]" % [diff, statType.to_upper()]
			elif diff < 0:
				compareStats.text = "[color=#e74c3c]▼ %d %s[/color]" % [diff, statType.to_upper()]
			else:
				compareStats.text = "[color=#888888]= No change[/color]"
		else:
			compareStats.text = ""

func cancelPressed() -> void:
	onClose()
