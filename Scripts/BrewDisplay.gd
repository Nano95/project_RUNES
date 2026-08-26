extends ColorRect
class_name BrewDisplay

@export var recipesVBox: VBoxContainer
@export var infoName: Label
@export var infoDesc: RichTextLabel
@export var instructions: RichTextLabel
@export var ingredientsVBox: VBoxContainer
@export var brewButton: Button
@export var closeButton: Button
@export var inventorySystem: InventorySystem
@export var brewSystem: BrewSystem

var selectedRecipe: RecipeData = null

func _ready() -> void:
	GameEvents.backpackChanged.connect(onInventoryChanged)
	brewButton.pressed.connect(func():
		onBrewPressed()
		Utils.animateButtonPress(brewButton)
	)
	closeButton.pressed.connect(func():
		hide()
		Utils.animateButtonPress(closeButton)
	)
	hide()

func open() -> void:
	selectedRecipe = null
	refresh()
	show()

func refresh() -> void:
	refreshRecipes()
	refreshInfo()
	refreshBrewButton()

func onInventoryChanged() -> void:
	if not visible:
		return
	refresh()

# ── RECIPES ───────────────────────────────────────────────
func refreshRecipes() -> void:
	for child in recipesVBox.get_children():
		child.free()

	var available = getAvailableRecipes()

	if available.is_empty():
		var lbl = Label.new()
		lbl.text = "No recipes available.\nGather herbs to begin."
		lbl.add_theme_color_override("font_color", Color("#888888"))
		lbl.add_theme_font_size_override("font_size", 20)
		lbl.custom_minimum_size = Vector2(0, 250)
		lbl.autowrap_mode = TextServer.AUTOWRAP_WORD
		recipesVBox.add_child(lbl)
		return

	for recipe in available:
		var btn = Button.new()
		btn.text = recipe.recipeName
		btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		btn.mouse_filter = Control.MOUSE_FILTER_PASS
		if (selectedRecipe == recipe):
			btn.add_theme_color_override("font_color", Color("#8e44ad"))
		btn.pressed.connect(func():
			onRecipeSelected(recipe)
			Utils.animateButtonPress(btn)
		)
		btn.add_theme_font_size_override("font_size", 24)
		#btn.custom_minimum_size = Vector2(0, 60)
		recipesVBox.add_child(btn)

func getAvailableRecipes() -> Array[RecipeData]:
	var result: Array[RecipeData] = []
	for recipe in RecipeRegistry.recipes:
		if canBrew(recipe):
			result.append(recipe)
	return result

func canBrew(recipe: RecipeData) -> bool:
	for ingredient in recipe.ingredients:
		var needed = recipe.ingredients[ingredient]
		if inventorySystem.countInBackpack(ingredient) < needed:
			return false
	return true

func onRecipeSelected(recipe: RecipeData) -> void:
	selectedRecipe = recipe
	refreshInfo()
	refreshBrewButton()

# ── INFO PANEL ────────────────────────────────────────────
func refreshInfo() -> void:
	var children = ingredientsVBox.get_children()
	for i in range(2, children.size()):
		children[i].free()

	if not selectedRecipe:
		infoName.text = "Select a recipe"
		infoDesc.text = ""
		ingredientsVBox.hide()
		instructions.show()
		return
	ingredientsVBox.show()
	instructions.hide()
	
	infoName.text = "  " + selectedRecipe.recipeName

	# Description from ItemRegistry
	var item = ItemRegistry.getItem(selectedRecipe.resultItem)
	infoDesc.bbcode_enabled = true
	infoDesc.text = "[i]  %s[/i]" % (item.description if item else "")

	# Ingredients
	for ingredient in selectedRecipe.ingredients:
		var needed = selectedRecipe.ingredients[ingredient]
		var have = inventorySystem.countInBackpack(ingredient)
		var row = HBoxContainer.new()

		var nameLabel = Label.new()
		nameLabel.text = "  " + ingredient
		nameLabel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		nameLabel.add_theme_font_size_override("font_size", 20)

		var haveLabel = Label.new()
		haveLabel.text = "%d / %d" % [have, needed]
		haveLabel.add_theme_font_size_override("font_size", 20)
		haveLabel.add_theme_color_override("font_color",
			Color("#27ae60") if have >= needed else Color("#c0392b")
		)

		row.add_child(nameLabel)
		row.add_child(haveLabel)
		ingredientsVBox.add_child(row)

# ── BREW BUTTON ───────────────────────────────────────────
func refreshBrewButton() -> void:
	brewButton.disabled = selectedRecipe == null

func onBrewPressed() -> void:
	if not selectedRecipe:
		return
	brewSystem.attemptBrew(selectedRecipe.ingredients)
	Utils.spawnFloatingLabel(
		"+1 %s" % selectedRecipe["recipeName"],
		Color("#27ae60"),
		brewButton,
		false
	)
	refresh()
