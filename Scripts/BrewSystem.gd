extends Node
class_name BrewSystem

@export var inventorySystem: InventorySystem
var main:MainNode

func _ready() -> void:
	main = Utils.get_main()
	GameEvents.recipeDiscovered.connect(onRecipeDiscovered)
	GameEvents.potionUsed.connect(onPotionUsed)
	GameEvents.timePotionUsed.connect(onTimePotionUsed)

# ── BREWING ───────────────────────────────────────────────
func attemptBrew(ingredients: Dictionary) -> String:
	# Check player has all ingredients
	for itemName in ingredients:
		var needed = ingredients[itemName]
		if not inventorySystem.hasInBackpack(itemName) or \
		   inventorySystem.countInBackpack(itemName) < needed:
			GameEvents.eventLogged.emit(
				"You don't have enough %s." % itemName, "system", false
			)
			return "missing_ingredients"

	# Find matching recipe first before consuming
	var recipe = RecipeRegistry.findRecipe(ingredients)

	# Check weight BEFORE consuming
	var resultItem = ItemRegistry.getItem(recipe.resultItem)
	if resultItem:
		if main.game_data.currentWeight + resultItem.weight > main.game_data.getMaxWeight():
			GameEvents.eventLogged.emit(
				"Too heavy to carry %s!" % recipe.resultItem, "system", false
			)
			return "too_heavy"
		if main.game_data.backpack.size() >= main.game_data.backpackMax:
			GameEvents.eventLogged.emit(
				"Backpack full! Can't brew %s." % recipe.resultItem, "system", false
			)
			return "backpack_full"

	# Now safe to consume ingredients
	for itemName in ingredients:
		inventorySystem.removeFromBackpack(itemName, ingredients[itemName])

	# Add result to backpack
	inventorySystem.addToBackpack(recipe.resultItem, 1)

	# Discover recipe if new
	if not main.game_data.discoveredRecipes.has(recipe.recipeName):
		main.game_data.discoveredRecipes.append(recipe.recipeName)
		main.save_game()
		GameEvents.recipeDiscovered.emit(recipe.recipeName)
		GameEvents.eventLogged.emit(
			"New recipe discovered: %s!" % recipe.recipeName, "discover", false
		)
	else:
		GameEvents.eventLogged.emit(
			"Brewed %s." % recipe.resultItem, "gather", false
		)
	GameEvents.brewAttempted.emit(true, recipe.resultItem)
	return "success"

# ── RECIPE DISCOVERY ──────────────────────────────────────
func onRecipeDiscovered(recipeName: String) -> void:
	# Can be called from anywhere — loot drop, purchase, dungeon reward
	if not main.game_data.discoveredRecipes.has(recipeName):
		main.game_data.discoveredRecipes.append(recipeName)
		main.save_game()
		GameEvents.eventLogged.emit(
			"Recipe unlocked: %s!" % recipeName, "discover", false
		)

# ── POTION EFFECTS ────────────────────────────────────────
func onPotionUsed(itemName: String) -> void:
	# InventorySystem handles heal potions
	# Here we handle special effects
	match itemName:
		"Regen Potion":
			if main.game_data.regenCounter > 0:
				GameEvents.eventLogged.emit(
					"Already regenerating!", "system", false
				)
				return
			main.game_data.regenCounter = 5
			main.game_data.regenPerTick = 10
			GameEvents.eventLogged.emit(
				"Regen Potion consumed. Regenerating 10 HP per tick.", "gather", false
			)
		"Time Potion":
			GameEvents.timePotionUsed.emit()
		"Strength Brew":
			pass # TODO: implement effect
		"Swiftness Tonic":
			pass # TODO: implement effect
		"Battle Potion":
			pass # TODO: implement effect

func onTimePotionUsed() -> void:
	if main.game_data.inCombat:
		GameEvents.eventLogged.emit(
			"Can't use that during battle!", "system", false
		)
		return
	# Fast forward event count to next multiple of 10
	var current = main.game_data.eventCount
	@warning_ignore("integer_division")
	var nextCheckpoint = (int(current / 10) + 1) * 10
	var skipped = nextCheckpoint - current
	main.game_data.eventCount = nextCheckpoint
	GameEvents.eventLogged.emit(
		"Time warps. %d events pass in an instant." % skipped, "discover", false
	)
	GameEvents.checkpointReached.emit()
