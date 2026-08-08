extends Panel
class_name EquipmentDisplay

@export var equipmentSystem: EquipmentSystem
@export var itemModal: EquipmentItemModal

# Slot buttons
@export var helmetBtn: Button
@export var weaponBtn: Button
@export var armorBtn: Button
@export var shieldBtn: Button
@export var legsBtn: Button
@export var bootsBtn: Button
var main:MainNode

func _ready() -> void:
	main = Utils.get_main()
	GameEvents.equipmentChanged.connect(refresh)

	helmetBtn.pressed.connect(onSlotPressed.bind("helmet"))
	weaponBtn.pressed.connect(onSlotPressed.bind("weapon"))
	armorBtn.pressed.connect(onSlotPressed.bind("armor"))
	shieldBtn.pressed.connect(onSlotPressed.bind("shield"))
	legsBtn.pressed.connect(onSlotPressed.bind("legs"))
	bootsBtn.pressed.connect(onSlotPressed.bind("boots"))
	call_deferred("refresh")
	#refresh()

func refresh() -> void:
	_updateSlot(helmetBtn, "helmet")
	_updateSlot(weaponBtn, "weapon")
	_updateSlot(armorBtn, "armor")
	_updateSlot(shieldBtn, "shield")
	_updateSlot(legsBtn, "legs")
	_updateSlot(bootsBtn, "boots")

func _updateSlot(btn: Button, slot: String) -> void:
	var equipped = equipmentSystem.getEquippedSlot(slot)
	if not equipped or equipped.is_empty():
		btn.text = slot.capitalize() + "\n[empty]"
		btn.modulate = Color(1, 1, 1, 0.4)
	else:
		var grade = equipped.get("grade", "")
		var gradeStr = " [%s]" % grade if grade != "" else ""
		var enh = equipped.get("enhancement", 0)
		var enhStr = " +%d" % enh if enh > 0 else ""
		btn.text = "%s\n%s%s%s" % [
			slot.capitalize(),
			equipped.get("name", ""),
			gradeStr,
			enhStr
		]
		btn.modulate = Color(1, 1, 1, 1.0)

func onSlotPressed(slot: String) -> void:
	Utils.animateButtonPress(helmetBtn if slot == "helmet" else \
							 weaponBtn if slot == "weapon" else \
							 armorBtn if slot == "armor" else \
							 shieldBtn if slot == "shield" else \
							 legsBtn if slot == "legs" else bootsBtn)
	itemModal.open(slot)
	
