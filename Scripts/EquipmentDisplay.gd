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
@export var helmetGradeLabel: Label
@export var weaponGradeLabel: Label
@export var armorGradeLabel: Label
@export var shieldGradeLabel: Label
@export var legsGradeLabel: Label
@export var bootsGradeLabel: Label
var main:MainNode

const OUTLINE_COLORS = {
	0:  null,                    # no outline
	1:  Color("#4fc3f7"),        # light blue
	2:  Color("4facf7ff"),
	3:  Color("4f9cf7ff"),
	4:  Color("4f75f7ff"),
	5:  Color("6d59b6ff"),        # purple
	6:  Color("#9b59b6"),
	7:  Color("e900e2ff"),
	8:  Color("fc0d61ff"),        # pink
	9:  Color("ff6e1fff"),        # red
	10: Color("#FFD700"),        # gold
}

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
	_updateSlot(helmetBtn, "helmet", helmetTexture, helmetGradeLabel)
	_updateSlot(weaponBtn, "weapon", weaponTexture, weaponGradeLabel)
	_updateSlot(armorBtn,  "armor",  armorTexture, armorGradeLabel)
	_updateSlot(shieldBtn, "shield", shieldTexture, shieldGradeLabel)
	_updateSlot(legsBtn,   "legs",   legsTexture, legsGradeLabel)
	_updateSlot(bootsBtn,  "boots",  bootsTexture, bootsGradeLabel)
	refreshStatsPanel()

func _updateSlot(_btn: Button, slot: String, textureRect: TextureRect, gradeLabel: Label) -> void:
	var equipped = equipmentSystem.getEquippedSlot(slot)
	if not equipped or equipped.is_empty():
		textureRect.texture = null
		_updateGradeBadge(gradeLabel, {})
	else:
		@warning_ignore("static_called_on_instance")
		textureRect.texture = ItemRegistry.getSprite(equipped.get("name", ""))
		_updateGradeBadge(gradeLabel, equipped)
		_applyEnhancementOutline(textureRect, equipped)

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

func _applyEnhancementOutline(textureRect: TextureRect, instance: Dictionary) -> void:
	var enh = instance.get("enhancement", 0)
	var color = OUTLINE_COLORS.get(enh, null)
	
	var mat = textureRect.material as ShaderMaterial
	if not mat:
		return
	
	if color == null or enh == 0:
		mat.set_shader_parameter("enabled", false)
	else:
		mat.set_shader_parameter("enabled", true)
		mat.set_shader_parameter("outline_color", color)

func _updateGradeBadge(gradeLabel: Label, instance: Dictionary) -> void:
	var grade = instance.get("grade", "")
	if grade == "":
		gradeLabel.visible = false
		return
	gradeLabel.visible = true
	gradeLabel.text = "[%s]" % grade
	match grade:
		"SS": gradeLabel.self_modulate = Color("#FFD700")
		"S":  gradeLabel.self_modulate = Color("#fc0d61ff")
		"A":  gradeLabel.self_modulate = Color("#9b59b6")
		"B":  gradeLabel.self_modulate = Color("#4f9cf7ff")
		_:    gradeLabel.self_modulate = Color("#ffffff")
