extends ColorRect
class_name EquipmentDisplay


@export var totalStatsLabel: Label
@export var helmetButton: Button
@export var armorButton: Button
@export var legsButton: Button
@export var bootsButton: Button
@export var weaponButton: Button
@export var shieldButton: Button
@export var ringButton: Button
@export var amuletButton: Button
@export var comparePanel: VBoxContainer
@export var instructions:RichTextLabel
@export var selectedNameLabel: Label
@export var selectedEquipType: Label
@export var selectedEquipTypeValue: Label
@export var equippedName: Label
@export var equippedNameStatValue: Label
@export var compareStats: RichTextLabel
@export var equipButton: Button
@export var closeButton: Button
@export var backpackFlow: HFlowContainer
@export var equipmentSystem: EquipmentSystem
@export var inventorySystem: InventorySystem

var main:MainNode
var selectedInstance: Dictionary = {}
var selectedSource: String = ""  # "backpack" or "slot"

func _ready() -> void:
	main = Utils.get_main()
	GameEvents.equipmentChanged.connect(refresh)
	GameEvents.backpackChanged.connect(refreshBackpack)

	helmetButton.pressed.connect(onSlotPressed.bind("helmet"))
	armorButton.pressed.connect(onSlotPressed.bind("armor"))
	legsButton.pressed.connect(onSlotPressed.bind("legs"))
	bootsButton.pressed.connect(onSlotPressed.bind("boots"))
	weaponButton.pressed.connect(onSlotPressed.bind("weapon"))
	shieldButton.pressed.connect(onSlotPressed.bind("shield"))
	ringButton.pressed.connect(onSlotPressed.bind("ring"))
	amuletButton.pressed.connect(onSlotPressed.bind("amulet"))
	equipButton.pressed.connect(onEquipButtonPressed)
	closeButton.pressed.connect(onClose)

	clearCompare()
	hide()

func onClose() -> void:
	Utils.animate_modal_exit(self)

func open() -> void:
	if main.game_data.inArea:
		return
	selectedInstance = {}
	selectedSource = ""
	clearCompare()
	refresh()
	Utils.animate_modal_entry(self)

func refresh() -> void:
	refreshSlots()
	refreshBackpack()
	refreshStats()

# ── SLOTS ─────────────────────────────────────────────────
func refreshSlots() -> void:
	_updateSlotButton(helmetButton, "helmet")
	_updateSlotButton(armorButton, "armor")
	_updateSlotButton(legsButton, "legs")
	_updateSlotButton(bootsButton, "boots")
	_updateSlotButton(weaponButton, "weapon")
	_updateSlotButton(shieldButton, "shield")
	_updateSlotButton(ringButton, "ring")
	_updateSlotButton(amuletButton, "amulet")

func _updateSlotButton(btn: Button, slot: String) -> void:
	var equipped = equipmentSystem.getEquippedSlot(slot)
	if not equipped or equipped.is_empty():
		btn.text = "[empty]"
		btn.modulate = Color(1, 1, 1, 0.4)
		btn.disabled = true
	else:
		var enh = equipped.get("enhancement", 0)
		var enhStr = " +%d" % enh if enh > 0 else ""
		btn.text = "%s%s" % [equipped["name"], enhStr]
		btn.modulate = Color(1, 1, 1, 1.0)
		btn.disabled = false

func onSlotPressed(slot: String) -> void:
	var equipped = equipmentSystem.getEquippedSlot(slot)
	if not equipped or equipped.is_empty():
		return
	selectedInstance = equipped
	selectedSource = "slot"
	updateCompare()

# ── BACKPACK ─────────────────────────────────────────────
func refreshBackpack() -> void:
	for child in backpackFlow.get_children():
		child.queue_free()

	var hasEquipment = false

	for stack in main.game_data.backpack:
		if not stack.get("isEquipment", false):
			continue
		hasEquipment = true
		var btn = Button.new()
		var enh = stack.get("enhancement", 0)
		var enhStr = " +%d" % enh if enh > 0 else ""
		var statBonus = stack.get("statBonus", 0)
		var statType = stack.get("statType", "none")
		var statStr = ""
		if statType != "none":
			statStr = " (%s +%d)" % [statType.to_upper(), statBonus]
		btn.text = " %s%s%s " % [stack["name"], enhStr, statStr]
		btn.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
		btn.add_theme_color_override("font_color", Color("#e74c3c"))
		btn.custom_minimum_size = Vector2(150,50)
		btn.pressed.connect(onBackpackItemPressed.bind(stack))
		backpackFlow.add_child(btn)

	if not hasEquipment:
		var lbl = Label.new()
		lbl.text = "No equipment in backpack"
		lbl.add_theme_color_override("font_color", Color("#888888"))
		backpackFlow.add_child(lbl)

func onBackpackItemPressed(instance: Dictionary) -> void:
	selectedInstance = instance
	selectedSource = "backpack"
	updateCompare()

# ── COMPARE PANEL ─────────────────────────────────────────
func updateCompare() -> void:
	if selectedInstance.is_empty():
		clearCompare()
		return
	instructions.visible = false
	comparePanel.visible = true
	var slot = selectedInstance.get("slot", "")
	var equipped = equipmentSystem.getEquippedSlot(slot)
	var statType = selectedInstance.get("statType", "none")
	var statBonus = selectedInstance.get("statBonus", 0)
	var enhancement = selectedInstance.get("enhancement", 0)
	var totalBonus = statBonus + enhancement
	var enh = " +%d" % enhancement if enhancement > 0 else ""

	# Selected name
	selectedNameLabel.text = "%s%s" % [selectedInstance.get("name", ""), enh]

	# Selected stat type and value
	if statType != "none":
		selectedEquipType.text = "Selected %s" % statType.to_upper()
		selectedEquipTypeValue.text = "+%d" % totalBonus
	else:
		selectedEquipType.text = formatEffect(selectedInstance)
		selectedEquipTypeValue.text = ""

	# Equipped comparison
	if not equipped or equipped.is_empty():
		equippedName.text = "Slot is empty"
		equippedNameStatValue.text = ""
		compareStats.text = ""
	else:
		var curBonus = equipped.get("statBonus", 0) + equipped.get("enhancement", 0)
		var curEnh = " +%d" % equipped.get("enhancement", 0) if equipped.get("enhancement", 0) > 0 else ""
		equippedName.text = "Equipped: %s%s" % [equipped.get("name", ""), curEnh]
		equippedNameStatValue.text = "+%d" % curBonus

		# Difference with color
		if statType != "none":
			var diff = totalBonus - curBonus
			if diff > 0:
				compareStats.text = "[right][color=#27ae60]▲ +%d %s[/color][/right]" % [diff, statType.to_upper()]
			elif diff < 0:
				compareStats.text = "[right][color=#e74c3c]▼ %d %s[/color][/right]" % [diff, statType.to_upper()]
			else:
				compareStats.text = "[right][color=#888888]No change[/color][/right]"
		else:
			compareStats.text = ""

	# Equip / Unequip button
	equipButton.visible = true
	if selectedSource == "backpack":
		equipButton.text = "Equip"
	else:
		equipButton.text = "Unequip"

func clearCompare() -> void:
	instructions.visible = true
	comparePanel.visible = false
	equipButton.visible = false

func onEquipButtonPressed() -> void:
	if selectedInstance.is_empty():
		return
	if selectedSource == "backpack":
		equipmentSystem.equipItem(selectedInstance)
	else:
		var slot = selectedInstance.get("slot", "")
		equipmentSystem.unequipSlot(slot)
	selectedInstance = {}
	selectedSource = ""
	clearCompare()
	refresh()

# ── STATS ─────────────────────────────────────────────────
func refreshStats() -> void:
	var atk = equipmentSystem.getTotalAttack()
	var def = equipmentSystem.getTotalDefense()
	totalStatsLabel.text = "ATK %d  |  DEF %d" % [atk, def]

# ── HELPERS ───────────────────────────────────────────────
func formatEffect(instance: Dictionary) -> String:
	match instance.get("effectType", "none"):
		"checkpoint_heal": return "Heals %d%% HP at checkpoint" % instance.get("effectValue", 0)
		"regen":           return "Regenerates %d HP per tick" % instance.get("effectValue", 0)
		"gold_bonus":      return "+%d%% gold find" % instance.get("effectValue", 0)
		"xp_bonus":        return "+%d%% XP gain" % instance.get("effectValue", 0)
		"cursed_block":    return "%d%% block or 2x damage" % instance.get("effectValue", 0)
		"poison":          return "Poisons enemy for %d dmg/tick" % instance.get("effectValue", 0)
		"lifesteal":       return "Steals %d%% of damage as HP" % instance.get("effectValue", 0)
		"stun":            return "Chance to stun enemy"
	return ""
