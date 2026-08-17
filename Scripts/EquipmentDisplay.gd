extends Panel
class_name EquipmentDisplay

@export var equipmentSystem: EquipmentSystem
@export var itemModal: EquipmentItemModal
@export var statsPanel: RichTextLabel

# Slot buttons
@export var helmetBtn: Button
@export var weaponBtn: Button
@export var armorBtn: Button
@export var shieldBtn: Button
@export var legsBtn: Button
@export var bootsBtn: Button
@export var helmetTexture: TextureRect
@export var weaponTexture: TextureRect
@export var armorTexture: TextureRect
@export var shieldTexture: TextureRect
@export var legsTexture: TextureRect
@export var bootsTexture: TextureRect
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
	hide()
	#refresh()

func refresh() -> void:
	_updateSlot(helmetBtn, "helmet", helmetTexture)
	_updateSlot(weaponBtn, "weapon", weaponTexture)
	_updateSlot(armorBtn,  "armor",  armorTexture)
	_updateSlot(shieldBtn, "shield", shieldTexture)
	_updateSlot(legsBtn,   "legs",   legsTexture)
	_updateSlot(bootsBtn,  "boots",  bootsTexture)
	refreshStatsPanel()

func _updateSlot(btn: Button, slot: String, textureRect: TextureRect) -> void:
	var equipped = equipmentSystem.getEquippedSlot(slot)
	if not equipped or equipped.is_empty():
		btn.text = slot.capitalize() + "\n[empty]"
		btn.modulate = Color(1, 1, 1, 0.4)
		textureRect.texture = null
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
		@warning_ignore("static_called_on_instance")
		textureRect.texture = ItemRegistry.getSprite(equipped.get("name", ""))

func onSlotPressed(slot: String) -> void:
	Utils.animateButtonPress(helmetBtn if slot == "helmet" else \
							 weaponBtn if slot == "weapon" else \
							 armorBtn if slot == "armor" else \
							 shieldBtn if slot == "shield" else \
							 legsBtn if slot == "legs" else bootsBtn)
	itemModal.open(slot)

func refreshStatsPanel() -> void:
	var atk = equipmentSystem.getTotalAttack()
	var def = equipmentSystem.getTotalDefense()
	var maxHp = equipmentSystem.getMaxHp()
	var effects = equipmentSystem.getTotalEffects()

	var dodge = effects.get("dodge", 0.0)
	var poisonRes = effects.get("poisonResistance", 0.0)
	var burnRes = effects.get("burnResistance", 0.0)
	var checkpointHeal = effects.get("checkpointHeal", 0.0)

	var text = ""
	text += "[color=#ffffff]HP[/color] %d\n" % maxHp
	text += "[color=#e74c3c]ATK[/color] %d\n" % atk
	text += "[color=#3498db]DEF[/color] %d\n" % def
	text += "[color=#f1c40f]DODGE[/color] %d%%\n" % int(dodge * 100)
	text += "[color=#2ecc71]POISON RES[/color] %d%%\n" % int(poisonRes * 100)
	text += "[color=#e67e22]BURN RES[/color] %d%%\n" % int(burnRes * 100)
	text += "[color=#1abc9c]CHECKPOINT HEAL[/color] %d%%" % int(checkpointHeal * 100)

	statsPanel.bbcode_enabled = true
	statsPanel.text = text
