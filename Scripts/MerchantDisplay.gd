extends ColorRect
class_name MerchantDisplay

@export var goldLabel: Label
@export var potionsTab: Button
@export var equipmentTab: Button
@export var itemsVBox: VBoxContainer
@export var detailName: Label
@export var detailDesc: RichTextLabel
@export var detailStat: RichTextLabel
@export var buyButton: Button
@export var closeButton: Button
@export var merchantSystem: MerchantSystem

var currentCategory: String = "potion"
var selectedEntry: Dictionary = {}
var main:MainNode

func _ready() -> void:
	main = Utils.get_main()
	potionsTab.pressed.connect(onPotionsTabPressed)
	equipmentTab.pressed.connect(onEquipmentTabPressed)
	buyButton.pressed.connect(onBuyPressed)
	closeButton.pressed.connect(hide)
	hide()

func open() -> void:
	
	if main.game_data.inArea:
		return
	currentCategory = "potion"
	selectedEntry = {}
	refresh()
	show()

func refresh() -> void:
	refreshGold()
	refreshItems()
	refreshDetail()
	refreshBuyButton()

func refreshGold() -> void:
	goldLabel.text = "%d gold" % main.game_data.savedGold

func refreshItems() -> void:
	for child in itemsVBox.get_children():
		child.queue_free()

	var stock = merchantSystem.getStock(currentCategory)

	for entry in stock:
		var btn = Button.new()
		btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		btn.custom_minimum_size = Vector2(0, 60.0)

		var hbox = HBoxContainer.new()
		hbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		hbox.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)

		# Name label — left
		var nameLabel = Label.new()
		nameLabel.text = " " + entry["name"]
		nameLabel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		nameLabel.add_theme_color_override("font_color",
			Color("#8e44ad") if currentCategory == "potion" else Color("#e74c3c")
		)
		nameLabel.add_theme_font_size_override("font_size", 24)
		hbox.add_child(nameLabel)

		# Info + price — right RichTextLabel
		var infoLabel = RichTextLabel.new()
		infoLabel.bbcode_enabled = true
		infoLabel.fit_content = true
		infoLabel.scroll_active = false
		infoLabel.size_flags_horizontal = Control.SIZE_SHRINK_END
		infoLabel.custom_minimum_size.x = 280
		infoLabel.add_theme_font_size_override("normal_font_size", 24)
		infoLabel.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
		infoLabel.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		infoLabel.mouse_filter = Control.MOUSE_FILTER_IGNORE

		var statText = _getStatText(entry["name"])
		var canAfford = merchantSystem.canAfford(entry["cost"])
		var goldColor = "#c8880a" if canAfford else "#c0392b"
		infoLabel.text = "%s  [color=%s]%dg [/color]" % [statText, goldColor, entry["cost"]]

		hbox.add_child(infoLabel)
		btn.add_child(hbox)
		btn.pressed.connect(onItemPressed.bind(entry))
		itemsVBox.add_child(btn)

func _getStatText(itemName: String) -> String:
	var item = ItemRegistry.getItem(itemName)
	if not item:
		return ""
	if item.itemType == "potion":
		var heal = _getPotionHeal(itemName)
		return "[color=#8e44ad]%d HP[/color]" % heal
	var def = ItemRegistry.getEquipmentDef(itemName)
	if def:
		var statLabel = def.statType.to_upper() if def.statType != "none" else ""
		if def.statMax > 0:
			return "[color=#888888]%s +%d~+%d[/color]" % [statLabel, def.statMin, def.statMax]
		elif def.effectType != "none":
			return "[color=#8e44ad]%s[/color]" % def.effectType
	return ""

func _getPotionHeal(itemName: String) -> int:
	match itemName:
		"Minor Health Potion": return 20
		"Health Potion":     return 30
	return 0

func refreshDetail() -> void:
	if selectedEntry.is_empty():
		detailName.text = "Select an item"
		detailDesc.text = ""
		detailStat.text = ""
		return

	var itemName = selectedEntry["name"]
	var item = ItemRegistry.getItem(itemName)
	detailName.text = itemName
	detailDesc.text = "[i]%s[/i]" % (item.description if item else "")

	var def = ItemRegistry.getEquipmentDef(itemName)
	if def and def.statMax > 0:
		detailStat.bbcode_enabled = true
		detailStat.text = "%s +%d to +%d — [color=#c8880a]%dg[/color]" % [
			def.statType.to_upper(), def.statMin, def.statMax, selectedEntry["cost"]
		]
	elif item and item.itemType == "potion":
		detailStat.bbcode_enabled = true
		detailStat.text = "%s — [color=#c8880a]%dg[/color]" % [
			item.description, selectedEntry["cost"]
		]
	else:
		detailStat.bbcode_enabled = true
		detailStat.text = "[color=#c8880a]%dg[/color]" % selectedEntry["cost"]

func refreshBuyButton() -> void:
	if selectedEntry.is_empty():
		buyButton.disabled = true
		buyButton.text = "Buy"
		return
	var canAfford = merchantSystem.canAfford(selectedEntry["cost"])
	buyButton.disabled = not canAfford
	buyButton.text = "Buy — %dg" % selectedEntry["cost"]

func onPotionsTabPressed() -> void:
	currentCategory = "potion"
	selectedEntry = {}
	refresh()

func onEquipmentTabPressed() -> void:
	currentCategory = "equipment"
	selectedEntry = {}
	refresh()

func onItemPressed(entry: Dictionary) -> void:
	selectedEntry = entry
	refreshDetail()
	refreshBuyButton()

func onBuyPressed() -> void:
	if selectedEntry.is_empty():
		return
	var success = merchantSystem.buyItem(selectedEntry)
	if success:
		selectedEntry = {}
		refresh()
