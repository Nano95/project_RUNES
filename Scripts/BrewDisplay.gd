extends ColorRect
class_name BrewDisplay

@export var backpackFlow: HFlowContainer
@export var backpackWeightLabel: Label
@export var backpackSlotLabel: Label
@export var slot1Container: HBoxContainer
@export var slot2Container: HBoxContainer  
@export var slot3Container: HBoxContainer
@export var brewButton: Button
@export var clearButton: Button
@export var closeButton: Button
@export var discoveredFlow: HFlowContainer
@export var brewSystem: BrewSystem
@export var inventorySystem: InventorySystem

# Current combination { "Wild Herb": 2, "Red Berry": 1 }
var currentCombo: Dictionary = {}

# Slot order for display
var slotOrder: Array[String] = []

var main:MainNode

func _ready() -> void:
	main = Utils.get_main()
	GameEvents.backpackChanged.connect(refresh)
	GameEvents.recipeDiscovered.connect(onRecipeDiscovered)
	GameEvents.brewAttempted.connect(onBrewAttempted)
	brewButton.pressed.connect(onBrewPressed)
	#clearButton.pressed.connect(onClearPressed)
	closeButton.pressed.connect(hide)
	hide()

func open() -> void:
	currentCombo = {}
	slotOrder = []
	refresh()
	show()

func refresh() -> void:
	refreshBackpack()
	refreshSlots()
	refreshDiscovered()
	brewButton.disabled = currentCombo.is_empty()

# ── BACKPACK PANEL ────────────────────────────────────────
func refreshBackpack() -> void:
	for child in backpackFlow.get_children():
		child.queue_free()

	backpackWeightLabel.text = "%.1f / %.1f kg" % [
		main.game_data.currentWeight,
		main.game_data.maxWeight
	]
	backpackSlotLabel.text = "%d slots used" % main.game_data.backpack.size()

	# Only show forageable and monster parts (brewable items)
	var stacked = inventorySystem.getStackedView(main.game_data.backpack)
	var brewable = stacked.filter(func(e): 
		return e["type"] == "forageable" or e["type"] == "part"
	)

	if brewable.is_empty():
		var lbl = Label.new()
		lbl.text = "No brewable ingredients"
		lbl.add_theme_color_override("font_color", Color("#888888"))
		backpackFlow.add_child(lbl)
		return

	for entry in brewable:
		var btn = Button.new()
		var inUse = currentCombo.get(entry["name"], 0)
		var available = entry["qty"] - inUse
		btn.text = "%s x%d" % [entry["name"], available]
		btn.disabled = available <= 0 or slotOrder.size() >= 3 and not currentCombo.has(entry["name"])
		btn.add_theme_color_override("font_color", Color("#27ae60"))
		btn.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
		btn.pressed.connect(onIngredientPressed.bind(entry["name"]))
		backpackFlow.add_child(btn)

# ── SLOT PANEL ────────────────────────────────────────────
func refreshSlots() -> void:
	_refreshSlot(slot1Container, 0)
	_refreshSlot(slot2Container, 1)
	_refreshSlot(slot3Container, 2)

func _refreshSlot(container: HBoxContainer, idx: int) -> void:
	for child in container.get_children():
		child.queue_free()

	if idx >= slotOrder.size():
		var lbl = Label.new()
		lbl.text = "[ empty ]"
		lbl.add_theme_color_override("font_color", Color("#444444"))
		lbl.add_theme_font_size_override("font_size", 22)
		container.add_child(lbl)
		return

	var itemName = slotOrder[idx]
	var qty = currentCombo.get(itemName, 0)

	var nameLabel = Label.new()
	nameLabel.text = itemName
	nameLabel.add_theme_color_override("font_color", Color("#27ae60"))
	nameLabel.add_theme_font_size_override("font_size", 26)
	nameLabel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	container.add_child(nameLabel)

	# Minus button
	var minusBtn = Button.new()
	minusBtn.text = "-"
	minusBtn.pressed.connect(onSlotMinus.bind(itemName))
	minusBtn.custom_minimum_size = Vector2(100, 0)
	minusBtn.add_theme_font_size_override("font_size", 26)
	container.add_child(minusBtn)

	# Qty label
	var qtyLabel = Label.new()
	qtyLabel.text = str(qty)
	qtyLabel.custom_minimum_size.x = 24
	qtyLabel.add_theme_font_size_override("font_size", 26)
	container.add_child(qtyLabel)

	# Remove button
	var removeBtn = Button.new()
	removeBtn.text = "✕"
	removeBtn.custom_minimum_size = Vector2(100, 0)
	removeBtn.add_theme_color_override("font_color", Color("#e74c3c"))
	removeBtn.pressed.connect(onSlotRemove.bind(itemName))
	removeBtn.add_theme_font_size_override("font_size", 26)
	container.add_child(removeBtn)

# ── DISCOVERED RECIPES ────────────────────────────────────
func refreshDiscovered() -> void:
	for child in discoveredFlow.get_children():
		child.queue_free()
	
	var discovered = RecipeRegistry.getDiscovered(main.game_data.discoveredRecipes)

	if discovered.is_empty():
		var lbl = Label.new()
		lbl.text = "No recipes discovered yet."
		lbl.add_theme_color_override("font_color", Color("#888888"))
		discoveredFlow.add_child(lbl)
		return

	for recipe in discovered:
		var btn = Button.new()
		# Build ingredient string
		var parts = []
		for ing in recipe.ingredients:
			parts.append("%s x%d" % [ing, recipe.ingredients[ing]])
		btn.text = "%s — %s" % [recipe.recipeName, " + ".join(parts)]
		btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		btn.add_theme_color_override("font_color", Color("#8e44ad"))
		btn.pressed.connect(onRecipeAutoFill.bind(recipe))
		discoveredFlow.add_child(btn)

# ── INTERACTIONS ──────────────────────────────────────────
func onIngredientPressed(itemName: String) -> void:
	if currentCombo.has(itemName):
		currentCombo[itemName] += 1
	else:
		if slotOrder.size() >= 3:
			return
		currentCombo[itemName] = 1
		slotOrder.append(itemName)
	refresh()

func onSlotMinus(itemName: String) -> void:
	if not currentCombo.has(itemName):
		return
	currentCombo[itemName] -= 1
	if currentCombo[itemName] <= 0:
		currentCombo.erase(itemName)
		slotOrder.erase(itemName)
	refresh()

func onSlotRemove(itemName: String) -> void:
	currentCombo.erase(itemName)
	slotOrder.erase(itemName)
	refresh()

func onRecipeAutoFill(recipe: RecipeData) -> void:
	# Check player has all ingredients
	var canFill = true
	for ingredient in recipe.ingredients:
		if inventorySystem.countInBackpack(ingredient) < recipe.ingredients[ingredient]:
			canFill = false
			break
	if not canFill:
		GameEvents.eventLogged.emit(
			"You don't have the ingredients for %s." % recipe.recipeName,
			"system", false
		)
		return
	currentCombo = recipe.ingredients.duplicate()
	slotOrder = Array(recipe.ingredients.keys(), TYPE_STRING, "", null)
	refresh()

func onBrewPressed() -> void:
	if currentCombo.is_empty():
		return
	brewSystem.attemptBrew(currentCombo)
	currentCombo = {}
	slotOrder = []
	refresh()

func onClearPressed() -> void:
	currentCombo = {}
	slotOrder = []
	refresh()

func onBrewAttempted(_success: bool, _resultItem: String) -> void:
	refresh()

func onRecipeDiscovered(_recipeName: String) -> void:
	refreshDiscovered()
