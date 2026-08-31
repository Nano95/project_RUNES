extends ColorRect
class_name EquipmentItemModal

@export var equipmentSystem: EquipmentSystem
@export var equipmentDisplay: EquipmentDisplay
@export var itemListTitle: Label
@export var itemListHFlow: HFlowContainer
@export var itemInfoPanel: Panel
@export var itemInfoName: Label
@export var itemInfoStat: Label
@export var itemInfoDesc: Label
@export var equipUnequipBtn: Button
@export var closeModalBtn: Button

var main:MainNode
var selectedSlot: String = ""
var selectedInstance: Dictionary = {}

const SLOT_LABELS = {
	"helmet": "Helmets",
	"armor": "Armor",
	"legs": "Legs",
	"boots": "Boots",
	"weapon": "Weapons",
	"shield": "Shields",
}

func _ready() -> void:
	main = Utils.get_main()
	GameEvents.backpackChanged.connect(onInventoryChanged)
	GameEvents.equipmentChanged.connect(onEquipmentChanged)
	equipUnequipBtn.pressed.connect(onEquipUnequipPressed)
	closeModalBtn.pressed.connect(closeModal)
	itemInfoPanel.visible = false
	equipUnequipBtn.visible = false
	hide()

func open(slot: String) -> void:
	Utils.animate_modal_entry(self)
	selectedSlot = slot
	selectedInstance = {}
	itemListTitle.text = SLOT_LABELS.get(slot, slot.capitalize())
	itemInfoPanel.visible = false
	equipUnequipBtn.visible = false
	refreshItemList()

func closeModal() -> void:
	selectedInstance = {}
	selectedSlot = ""
	Utils.animate_modal_exit(self)

func onInventoryChanged() -> void:
	if not visible:
		return
	refreshItemList()

func onEquipmentChanged() -> void:
	if not visible:
		return
	refreshItemList()
	equipmentDisplay.refresh()

# ── ITEM LIST ─────────────────────────────────────────────
func refreshItemList() -> void:
	for child in itemListHFlow.get_children():
		child.free()

	var matches: Array = []
	# Add currently equipped item first if any
	var equipped = equipmentSystem.getEquippedSlot(selectedSlot)
	var isEquipped:bool = false
	if not equipped.is_empty():
		isEquipped = true
		matches.append(equipped)

	for stack in main.game_data.backpack:
		if not stack.get("isEquipment", false):
			continue
		if stack.get("slot", "") == selectedSlot:
			matches.append(stack)

	if matches.is_empty():
		var lbl = Label.new()
		lbl.text = "No %ss in backpack." % selectedSlot.capitalize()
		lbl.add_theme_color_override("font_color", Color("#888888"))
		itemListHFlow.add_child(lbl)
		return
	var count:int = 0 
	for instance in matches:
		var btn = Button.new()
		var grade = instance.get("grade", "")
		var gradeStr = " [%s]" % grade if grade != "" else ""
		var enh = instance.get("enhancement", 0)
		var enhStr = " +%d" % enh if enh > 0 else ""
		btn.add_theme_font_size_override("font_size", 24)
		btn.mouse_filter = Control.MOUSE_FILTER_PASS
		btn.text = "%s%s%s" % [instance.get("name", ""), gradeStr, enhStr]
		#btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		match grade:
			"SS": btn.add_theme_color_override("font_color", Color("fa0c81ff"))
			"S": btn.add_theme_color_override("font_color", Color("#FFD700"))
			"A": btn.add_theme_color_override("font_color", Color("#4fc3f7"))
			"B": btn.add_theme_color_override("font_color", Color("#aaaaaa"))
			_:   btn.add_theme_color_override("font_color", Color("#ffffff"))
		btn.pressed.connect(onItemSelected.bind(instance))
		
		if (isEquipped and count == 0):
			var style = StyleBoxFlat.new()
			style.bg_color = Color(0.1, 0.3, 0.1, 0.4)  # subtle green
			style.border_width_left = 2
			style.border_width_right = 2
			style.border_width_top = 3
			style.border_width_bottom = 2
			style.border_color = Color("#27ae60")
			style.corner_radius_top_left = 8
			style.corner_radius_top_right = 8
			style.corner_radius_bottom_left = 8
			style.corner_radius_bottom_right = 8
			style.content_margin_left = 10    # adjust to match your theme
			style.content_margin_right = 10
			style.content_margin_top = 12
			style.content_margin_bottom = 12
			style.border_color = Color("#27ae60")
			btn.add_theme_stylebox_override("normal", style) 
		itemListHFlow.add_child(btn)
		count += 1

# ── ITEM SELECTED ─────────────────────────────────────────
func onItemSelected(instance: Dictionary) -> void:
	selectedInstance = instance
	refreshInfoPanel()

func refreshInfoPanel() -> void:
	if selectedInstance.is_empty():
		itemInfoPanel.visible = false
		return

	var grade = selectedInstance.get("grade", "")
	var enh = selectedInstance.get("enhancement", 0)
	var enhStr = " +%d" % enh if enh > 0 else ""
	var gradeStr = " [%s]" % grade if grade != "" else ""

	itemInfoName.text = "%s%s%s" % [
		selectedInstance.get("name", ""),
		gradeStr,
		enhStr
	]

	match grade:
		"SS": itemInfoName.add_theme_color_override("font_color", Color("fa0c81ff"))
		"S": itemInfoName.add_theme_color_override("font_color", Color("#FFD700"))
		"A": itemInfoName.add_theme_color_override("font_color", Color("#4fc3f7"))
		"B": itemInfoName.add_theme_color_override("font_color", Color("#aaaaaa"))
		_:   itemInfoName.add_theme_color_override("font_color", Color("#ffffff"))

	itemInfoStat.text = _getStatSummary(selectedInstance)

	var itemDef = ItemRegistry.getItem(selectedInstance.get("name", ""))
	itemInfoDesc.text = itemDef.description if itemDef else ""

	var equipped = equipmentSystem.getEquippedSlot(selectedSlot)
	var isEquipped = not equipped.is_empty() and \
					 equipped.get("instanceId", "") == selectedInstance.get("instanceId", "")

	equipUnequipBtn.text = "Unequip" if isEquipped else "Equip"
	equipUnequipBtn.visible = true
	itemInfoPanel.visible = true

# ── EQUIP / UNEQUIP ───────────────────────────────────────
func onEquipUnequipPressed() -> void:
	if selectedInstance.is_empty():
		return

	var equipped = equipmentSystem.getEquippedSlot(selectedSlot)
	var isEquipped = not equipped.is_empty() and \
					 equipped.get("instanceId", "") == selectedInstance.get("instanceId", "")

	if isEquipped:
		equipmentSystem.unequipSlot(selectedSlot)
	else:
		equipmentSystem.equipItem(selectedInstance)

	selectedInstance = {}
	itemInfoPanel.visible = false
	equipUnequipBtn.visible = false

# ── HELPERS ───────────────────────────────────────────────
func _getStatSummary(instance: Dictionary) -> String:
	var parts = []
	var slot = instance.get("slot", "")
	var gradeBonus = instance.get("gradeBonus", 0)
	var hp = instance.get("hpBonus", 0) + (instance.get("gradeHpBonus", 0) if slot != "weapon" and slot != "shield" else 0)
	var atk = instance.get("atkBonus", 0) + (gradeBonus if slot == "weapon" else 0)
	var def = instance.get("defBonus", 0) + (gradeBonus if slot == "shield" else 0)
	var dodge = instance.get("effects", {}).get("dodge", 0.0)
	var poisonRes = instance.get("effects", {}).get("poisonResistance", 0.0)
	if hp > 0: parts.append("HP+%d" % hp)
	if atk > 0: parts.append("ATK+%d" % atk)
	if def > 0: parts.append("DEF+%d" % def)
	if dodge > 0: parts.append("DODGE+%.1f%%" % (dodge * 100))
	if poisonRes > 0: parts.append("POISON RES+%d%%" % int(poisonRes * 100))
	return "  ".join(parts)
