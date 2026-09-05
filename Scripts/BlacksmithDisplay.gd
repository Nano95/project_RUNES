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
@export var enhancePip4: Panel
@export var enhancePip5: Panel
@export var enhancePip6: Panel
@export var enhancePip7: Panel
@export var enhancePip8: Panel
@export var enhancePip9: Panel
@export var enhancePip10: Panel
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
	craftTab.pressed.connect(func():
		onCraftTabPressed()
		Utils.animateButtonPress(craftTab)
	)
	enhanceTab.pressed.connect(func():
		onEnhanceTabPressed()
		Utils.animateButtonPress(enhanceTab)
	)
	actionButton.pressed.connect(func():
		onActionPressed()
		Utils.animateButtonPress(actionButton)
	)
	closeButton.pressed.connect(func():
		onClose()
		Utils.animateButtonPress(closeButton)
	)
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
	btn.pressed.connect(func():
		onRecipeSelected(recipe)
		Utils.animateButtonPress(btn)
	)
	btn.mouse_filter = Control.MOUSE_FILTER_PASS
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
	if def:
		var statParts = []
		if def.hpBonus > 0:
			statParts.append("HP +%d" % def.hpBonus)
		if def.atkBonus > 0:
			statParts.append("ATK +%d" % def.atkBonus)
		if def.defBonus > 0:
			statParts.append("DEF +%d" % def.defBonus)
		for effect in def.effects:
			var val = def.effects[effect]
			match effect:
				"dodge":            statParts.append("DODGE +%d%%" % int(val * 100))
				"poisonResistance": statParts.append("POISON RES +%d%%" % int(val * 100))
		if statParts.is_empty():
			infoStat.text = "  Material"
		else:
			infoStat.text = "  Result: %s" % "  ".join(statParts)
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
		if stack.get("enhancement", 0) >= equipmentSystem.MAX_ENHANCEMENT:
			continue
		hasItems = true
		var btn = Button.new()
		
		var grade = stack.get("grade", "")
		var gradeStr = " [%s]" % grade if grade != "" else ""
		var enh = stack.get("enhancement", 0)
		var enhStr = " +%d" % enh if enh > 0 else ""
		btn.text = " %s%s%s " % [stack["name"], gradeStr, enhStr]
		btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		btn.custom_minimum_size = Vector2(150,50)
		btn.add_theme_font_size_override("font_size", 22)
		if selectedEquip.get("instanceId") == stack.get("instanceId"):
			btn.add_theme_color_override("font_color", Color("#c8880a"))
		btn.pressed.connect(func():
			onEquipSelected(stack)
			Utils.animateButtonPress(btn)
		)
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
		enhanceName.text = "Select an item to see information here"
		enhanceCost.text = ""
		enhanceStatLabel.text = ""
		_updatePips(0)
		return


	enhanceInstructions.hide()
	enhanceDataList.show()
	var enh = selectedEquip.get("enhancement", 0)
	enhanceName.text = selectedEquip.get("name", "")
	_updatePips(enh)

	if (enh >= equipmentSystem.MAX_ENHANCEMENT):
		enhanceCost.bbcode_enabled = true
		enhanceCost.text = "[color=#888888]Max enhancement reached.[/color]"
		enhanceStatLabel.text = ""
		return

	var cost = equipmentSystem.ENHANCEMENT_TABLE[enh]
	var haveMat = inventorySystem.countInBackpack(cost["material"])
	var haveGold = main.game_data.savedGold >= cost["gold"]
	var hasMat = haveMat >= cost["qty"]
	var destroyChance = cost["destroyChance"]

	var goldColor = "#c8880a" if haveGold else "#c0392b"
	var matColor = "#27ae60" if hasMat else "#c0392b"

	enhanceCost.bbcode_enabled = true
	enhanceCost.text = "+%d → [color=%s]%dg[/color] + [color=%s]%dx %s[/color]" % [
		enh + 1, goldColor, cost["gold"], matColor, cost["qty"], cost["material"]
	]

	# Destroy chance warning
	var destroyColor = "#888888" if destroyChance == 0.0 else \
					   "#f56552" if destroyChance < 0.15 else "#b6291a"
	var destroyText = "Safe" if destroyChance == 0.0 else \
					  "Destroy chance: %d%%" % int(destroyChance * 100)
	enhanceCost.text += "\n[color=%s]%s[/color]" % [destroyColor, destroyText]

	var statType = selectedEquip.get("slot", "")
	var statLabel = ""
	var current = 0
	var nextBonus = cost["statBonus"]

	if statType == "weapon":
		statLabel = "ATK"
		current = selectedEquip.get("atkBonus", 0) + selectedEquip.get("gradeBonus", 0)
	elif statType == "shield":
		statLabel = "DEF"
		current = selectedEquip.get("defBonus", 0) + selectedEquip.get("gradeBonus", 0)
	elif statType == "boots":
		statLabel = "DODGE"
		var currentDodge = selectedEquip.get("effects", {}).get("dodge", 0.0) * 100
		var nextDodge = currentDodge + 0.5
		enhanceStatLabel.bbcode_enabled = true
		enhanceStatLabel.text = "[color=#888888]%s[/color] [color=#ffffff]%.1f%%[/color] → [color=#27ae60]%.1f%%[/color]" % [
			statLabel, currentDodge, nextDodge
		]
		return
	else:
		statLabel = "HP"
		current = selectedEquip.get("hpBonus", 0) + selectedEquip.get("gradeHpBonus", 0)

	enhanceStatLabel.bbcode_enabled = true
	enhanceStatLabel.text = "[color=#888888]%s[/color] [color=#ffffff]%d[/color] → [color=#27ae60]%d[/color]" % [
		statLabel, current, current + nextBonus
	]

func _updatePips(level: int) -> void:
	var pips = [enhancePip1, enhancePip2, enhancePip3, enhancePip4, enhancePip5,
				enhancePip6, enhancePip7, enhancePip8, enhancePip9, enhancePip10]
	for i in pips.size():
		if pips[i]:
			pips[i].modulate = Color("f6ee56ff") if i < level else Color("5b5b5bff")

# ── ACTION BUTTON ─────────────────────────────────────────
func refreshActionButton() -> void:
	if (currentTab == "enhance"):
		actionButton.text = "Enhance"
		if selectedEquip.is_empty() or selectedEquip.get("enhancement", 0) >= equipmentSystem.MAX_ENHANCEMENT:
			actionButton.disabled = true
			return
		actionButton.disabled = not equipmentSystem.canEnhance(selectedEquip)
	else:
		actionButton.text = "Craft"
		actionButton.disabled = selectedRecipe == null

func onActionPressed() -> void:
	if (currentTab == "enhance"):
		if selectedEquip.is_empty():
			return
		var result = equipmentSystem.enhanceItem(selectedEquip)
		match result["result"]:
			"success":
				selectedEquip = result["instance"]
				refresh()
			"destroyed":
				selectedEquip = {}
				refresh()
			"maxed":
				GameEvents.eventLogged.emit(
					"This item is already at max enhancement.", "system", false
				)
			"error":
				GameEvents.eventLogged.emit(
					"Enhancement failed — item not found in backpack.", "system", false
				)
	else:
		if not selectedRecipe:
			return
		var success = blacksmithSystem.craft(selectedRecipe)
		if success:
			selectedRecipe = null
			refresh()
