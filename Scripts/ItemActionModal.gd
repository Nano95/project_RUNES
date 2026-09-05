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
		GameEvents.backpackChanged.emit()
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
	var enhancement = instance.get("enhancement", 0)
	var enh = " +%d" % enhancement if enhancement > 0 else ""
	var grade = instance.get("grade", "")
	var gradeStr = " [%s]" % grade if grade != "" else ""

	# Selected item
	itemNameLabel.text = "%s%s%s" % [instance.get("name", ""), gradeStr, enh]

	# Currently equipped in that slot
	var equipped = equipmentSystem.getEquippedSlot(slot)
	if not equipped or equipped.is_empty():
		equippedName.text = "Slot is empty"
		equippedNameStatValue.text = ""
		compareStats.bbcode_enabled = true
		compareStats.text = "[color=#888888]Nothing equipped[/color]"
		return

	var curGrade = equipped.get("grade", "")
	var curGradeStr = " [%s]" % curGrade if curGrade != "" else ""
	var curEnh = equipped.get("enhancement", 0)
	var curEnhStr = " +%d" % curEnh if curEnh > 0 else ""
	equippedName.text = "Equipped: %s%s%s" % [equipped.get("name", ""), curGradeStr, curEnhStr]

	# Build stat comparison
	compareStats.bbcode_enabled = true
	var text = ""

	# Primary stat comparison based on slot
	if slot == "weapon":
		var newAtk = instance.get("atkBonus", 0) + instance.get("gradeBonus", 0)
		var curAtk = equipped.get("atkBonus", 0) + equipped.get("gradeBonus", 0)
		text += _compareStatLine("ATK", curAtk, newAtk)
	elif slot == "shield":
		var newDef = instance.get("defBonus", 0) + instance.get("gradeBonus", 0)
		var curDef = equipped.get("defBonus", 0) + equipped.get("gradeBonus", 0)
		text += _compareStatLine("DEF", curDef, newDef)
	else:
		var newHp = instance.get("hpBonus", 0) + instance.get("gradeHpBonus", 0)
		var curHp = equipped.get("hpBonus", 0) + equipped.get("gradeHpBonus", 0)
		text += _compareStatLine("HP", curHp, newHp)

	# Dodge comparison for boots
	if slot == "boots":
		var newDodge = instance.get("effects", {}).get("dodge", 0.0)
		var curDodge = equipped.get("effects", {}).get("dodge", 0.0)
		text += _compareStatLineFloat("DODGE", curDodge * 100, newDodge * 100, "%")

	# Poison resistance comparison
	var newPR = instance.get("effects", {}).get("poisonResistance", 0.0)
	var curPR = equipped.get("effects", {}).get("poisonResistance", 0.0)
	if newPR > 0 or curPR > 0:
		text += _compareStatLineFloat("POISON RES", curPR * 100, newPR * 100, "%")

	compareStats.text = text
	equippedNameStatValue.text = ""

func _compareStatLine(label: String, current: int, incoming: int) -> String:
	var diff = incoming - current
	var diffColor = "#27ae60" if diff > 0 else "#e74c3c" if diff < 0 else "#888888"
	var diffStr = "+%d" % diff if diff > 0 else "%d" % diff if diff < 0 else "="
	return "[color=#888888]%s[/color]  %d → %d  [color=%s](%s)[/color]\n" % [
		label, current, incoming, diffColor, diffStr
	]

func _compareStatLineFloat(label: String, current: float, incoming: float, suffix: String) -> String:
	var diff = incoming - current
	var diffColor = "#27ae60" if diff > 0 else "#e74c3c" if diff < 0 else "#888888"
	var diffStr = "+%.1f%s" % [diff, suffix] if diff > 0 else "%.1f%s" % [diff, suffix] if diff < 0 else "="
	return "[color=#888888]%s[/color]  %.1f%s → %.1f%s  [color=%s](%s)[/color]\n" % [
		label, current, suffix, incoming, suffix, diffColor, diffStr
	]

func cancelPressed() -> void:
	onClose()
