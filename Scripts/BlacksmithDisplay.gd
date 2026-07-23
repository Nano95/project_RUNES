extends ColorRect
class_name BlacksmithDisplay

@export var craftTab: Button
@export var enhanceTab: Button
@export var recipesVBox: VBoxContainer
@export var infoPanel: Panel
@export var infoName: Label
@export var infoStat: Label
@export var infoIngredients: VBoxContainer
@export var actionButton: Button
@export var closeButton: Button
@export var enhanceEquipFlow: VBoxContainer
@export var enhancePanel: Panel
@export var enhanceName: Label
@export var enhancePip1: Panel
@export var enhancePip2: Panel
@export var enhancePip3: Panel
@export var enhanceInstructions: RichTextLabel
@export var enhanceDataList: VBoxContainer
@export var enhanceCost: RichTextLabel
@export var enhanceStatLabel: RichTextLabel
@export var blacksmithSystem: BlacksmithSystem
@export var equipmentSystem: EquipmentSystem
@export var inventorySystem: InventorySystem

var currentTab: String = "smelt"
var selectedRecipe: BlacksmithRecipe = null
var selectedEquip: Dictionary = {}


var main:MainNode

func _ready() -> void:
	main = Utils.get_main()
	GameEvents.backpackChanged.connect(onInventoryChanged)
	GameEvents.equipmentChanged.connect(onInventoryChanged)
	craftTab.pressed.connect(onCraftTabPressed)
	enhanceTab.pressed.connect(onEnhanceTabPressed)
	actionButton.pressed.connect(onActionPressed)
	closeButton.pressed.connect(onClose)
	hide()

func onClose() -> void:
	# put things back to how they were
	infoPanel.show() # crafts
	enhancePanel.hide()
	Utils.animate_modal_exit(self)

func open() -> void:
	
	if main.game_data.inArea:
		return
	currentTab = "smelt"
	selectedRecipe = null
	selectedEquip = {}
	refresh()
	Utils.animate_modal_entry(self)

func refresh() -> void:
	if currentTab == "smelt" or currentTab == "forge":
		refreshInfo()
		refreshRecipes()
		refreshActionButton()
	else:
		refreshEnhanceList()
		refreshEnhanceDetail()
		refreshActionButton()

func onInventoryChanged() -> void:
	if not visible:
		return
	print("onInventoryChanged fired")
	refresh()

# ── CRAFT TAB ─────────────────────────────────────────────
func onCraftTabPressed() -> void:
	currentTab = "smelt"
	selectedRecipe = null
	enhancePanel.hide()
	infoPanel.show() # crafts
	refresh()

func refreshRecipes() -> void:
	var children = recipesVBox.get_children()
	for i in range(0, children.size()):
		children[i].free()

	var smeltRecipes = BlacksmithRegistry.getAvailableRecipes("smelt")
	var forgeRecipes = BlacksmithRegistry.getAvailableRecipes("forge")

	if smeltRecipes.is_empty() and forgeRecipes.is_empty():
		var lbl = Label.new()
		lbl.text = "  No recipes available.\n  Gather ore and coal to begin."
		lbl.add_theme_color_override("font_color", Color("#888888"))
		lbl.autowrap_mode = TextServer.AUTOWRAP_WORD
		recipesVBox.add_child(lbl)
		return

	if not smeltRecipes.is_empty():
		var header = Label.new()
		header.text = "Smelting"
		header.add_theme_color_override("font_color", Color("#888888"))
		header.add_theme_font_size_override("font_size", 20)
		
		recipesVBox.add_child(header)
		for recipe in smeltRecipes:
			recipesVBox.add_child(_makeRecipeButton(recipe))

	if not forgeRecipes.is_empty():
		var header = Label.new()
		header.text = "Forging"
		header.add_theme_color_override("font_color", Color("#888888"))
		header.add_theme_font_size_override("font_size", 20)
		recipesVBox.add_child(header)
		for recipe in forgeRecipes:
			recipesVBox.add_child(_makeRecipeButton(recipe))

func _makeRecipeButton(recipe: BlacksmithRecipe) -> Button:
	var btn = Button.new()
	btn.text = "  " + recipe.recipeName + "  "
	btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	btn.pressed.connect(onRecipeSelected.bind(recipe))
	btn.custom_minimum_size = Vector2(150,50)
	btn.add_theme_font_size_override("font_size", 22)
	if selectedRecipe == recipe:
		btn.add_theme_color_override("font_color", Color("#c8880a"))
	return btn

func onRecipeSelected(recipe: BlacksmithRecipe) -> void:
	selectedRecipe = recipe
	refreshInfo()
	refreshActionButton()

func refreshInfo() -> void:
	var children = infoIngredients.get_children()
	for i in range(2, children.size()):
		children[i].free()

	if not selectedRecipe:
		infoName.text = "Select a recipe"
		infoStat.text = ""
		return

	
	infoName.text = "  " + selectedRecipe.resultItem

	# Stat info
	var def = ItemRegistry.getEquipmentDef(selectedRecipe.resultItem)
	if def and def.statMax > 0:
		infoStat.text = "  Result: %s +%d to +%d" % [def.statType.to_upper(), def.statMin, def.statMax]
	else:
		infoStat.text = "  Material"

	# Ingredients
	for mat in selectedRecipe.ingredients:
		var needed = selectedRecipe.ingredients[mat]
		var have = BlacksmithRegistry.countMaterial(mat)
		var row = HBoxContainer.new()
		var nameLabel = Label.new()
		nameLabel.text = " " + mat
		nameLabel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		nameLabel.add_theme_font_size_override("font_size", 20)
		var haveLabel = Label.new()
		haveLabel.text = "%d / %d  " % [have, needed]
		haveLabel.add_theme_font_size_override("font_size", 20)
		haveLabel.add_theme_color_override("font_color",
			Color("#27ae60") if have >= needed else Color("#c0392b")
		)
		row.add_child(nameLabel)
		row.add_child(haveLabel)
		infoIngredients.add_child(row)

# ── ENHANCE TAB ───────────────────────────────────────────
func onEnhanceTabPressed() -> void:
	currentTab = "enhance"
	selectedRecipe = null
	selectedEquip = {}
	enhanceInstructions.show()
	enhanceDataList.hide()
	enhancePanel.show()
	infoPanel.hide() # crafts
	refresh()

func refreshEnhanceList() -> void:
	for child in enhanceEquipFlow.get_children():
		child.queue_free()
	var hasItems = false

	for stack in main.game_data.backpack:
		if not stack.get("isEquipment", false):
			continue
		if stack.get("enhancement", 0) >= 3:
			continue
		hasItems = true
		var btn = Button.new()
		
		var enh = stack.get("enhancement", 0)
		var enhStr = " +%d" % enh if enh > 0 else ""
		btn.text = stack["name"] + enhStr
		btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		btn.custom_minimum_size = Vector2(150,50)
		btn.add_theme_font_size_override("font_size", 22)
		if selectedEquip.get("instanceId") == stack.get("instanceId"):
			btn.add_theme_color_override("font_color", Color("#c8880a"))
		btn.pressed.connect(onEquipSelected.bind(stack))
		enhanceEquipFlow.add_child(btn)

	if not hasItems:
		var lbl = Label.new()
		lbl.text = "No enhanceable items in backpack."
		lbl.add_theme_color_override("font_color", Color("#888888"))
		enhanceEquipFlow.add_child(lbl)

func onEquipSelected(instance: Dictionary) -> void:
	selectedEquip = instance
	refreshEnhanceList()
	refreshEnhanceDetail()
	refreshActionButton()

func refreshEnhanceDetail() -> void:
	if selectedEquip.is_empty():
		enhanceInstructions.show()
		enhanceDataList.hide()
		enhanceName.text = "  Select an item"
		enhanceCost.text = ""
		enhanceStatLabel.text = ""
		_updatePips(0)
		return

	enhanceInstructions.hide()
	enhanceDataList.show()
	var enh = selectedEquip.get("enhancement", 0)
	enhanceName.text = "  " + selectedEquip.get("name", "")
	_updatePips(enh)

	if enh >= 3:
		enhanceCost.text = "  Max enhancement reached."
		enhanceStatLabel.text = ""
		return

	var cost = equipmentSystem.getEnhancementCost(selectedEquip)
	var materialNeeded = cost["materials"].keys()[0]
	var materialQty = cost["materials"][materialNeeded]
	var haveMat = inventorySystem.countInBackpack(materialNeeded)
	var haveGold = main.game_data.savedGold >= cost["gold"]
	var hasMat = haveMat >= materialQty

	var goldColor = "#c8880a" if haveGold else "#c0392b"
	var matColor = "#27ae60" if hasMat else "#c0392b"

	enhanceCost.text = "[color=%s]  %dg[/color] + [color=%s]%dx %s[/color]" % [
		goldColor, cost["gold"], matColor, materialQty, materialNeeded
	]

	var statType = selectedEquip.get("statType", "")
	var current = selectedEquip.get("statBonus", 0) + enh
	enhanceStatLabel.bbcode_enabled = true
	enhanceStatLabel.text = "[color=#888888]  %s[/color] [color=#ffffff]+%d[/color] → [color=#27ae60]+%d[/color]" % [
		statType.to_upper(), current, current + 1
	]
func _updatePips(level: int) -> void:
	enhancePip1.modulate = Color("#c8880a") if level >= 1 else Color("#444444")
	enhancePip2.modulate = Color("#c8880a") if level >= 2 else Color("#444444")
	enhancePip3.modulate = Color("#c8880a") if level >= 3 else Color("#444444")

# ── ACTION BUTTON ─────────────────────────────────────────
func refreshActionButton() -> void:
	if currentTab == "enhance":
		actionButton.text = "Enhance"
		if selectedEquip.is_empty() or selectedEquip.get("enhancement", 0) >= 3:
			actionButton.disabled = true
			print("_ EMPTY, disabling")
			return
		actionButton.disabled = not equipmentSystem.canEnhance(selectedEquip)
		print("- canEnhance, ",  not equipmentSystem.canEnhance(selectedEquip))
	else:
		actionButton.text = "Craft"
		actionButton.disabled = selectedRecipe == null

func onActionPressed() -> void:
	if currentTab == "enhance":
		if selectedEquip.is_empty():
			return
		blacksmithSystem.enhance(selectedEquip)
		selectedEquip = {}
		refresh()
	else:
		if not selectedRecipe:
			return
		var success = blacksmithSystem.craft(selectedRecipe)
		if success:
			selectedRecipe = null
			refresh()
