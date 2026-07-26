extends Node

var recipes: Array[RecipeData] = []

func _ready() -> void:
	recipes = [
		_make("Berry Extract",      {"Red Berry": 1},                                    "Berry Extract",      "heal",      15),
		_make("Minor Health Potion",{"Wild Herb": 2},                                    "Minor Health Potion","heal",      20),
		_make("Health Potion",      {"Wild Herb": 3, "Red Berry": 2, "Frog Leg": 1},     "Health Potion",      "heal",      30),
		_make("Twilight Potion",    {"Gloomcap": 1, "Red Berry": 1, "Wild Herb": 1},     "Twilight Potion",    "heal",      70),
		_make("Strength Brew",      {"Wild Herb": 2, "Orc Tooth": 1},                    "Strength Brew",      "strength",  5),
		_make("Swiftness Tonic",    {"Creature Fang": 1, "Bloodroot": 2},                    "Swiftness Tonic",    "swiftness", 0),
		_make("Time Potion",        {"Bat Wing": 3, "Bloodroot": 1, "Red Berry": 1},     "Time Potion",        "time",      0),
		_make("Minor Battle Potion", {"Rat Fur": 2, "Wild Herb": 1},          "Minor Battle Potion", "battle", 3),
		_make("Battle Potion",       {"Slime Gel": 1, "Bloodroot": 2},         "Battle Potion",       "battle", 6),
		_make("Great Battle Potion", {"Orc Tooth": 2, "Bloodroot": 1, "Gloomcap": 1}, "Great Battle Potion", "battle", 10),
		_make("Minor Foraging Potion", {"Red Berry": 1, "Slime Gel": 1},                    "Minor Foraging Potion", "forage", 3),
		_make("Foraging Potion",       {"Wild Herb": 2, "Gloomcap": 1},                     "Foraging Potion",       "forage", 6),
		_make("Great Foraging Potion", {"Cyclops Eye": 1, "Bloodroot": 2, "Gloomcap": 1},   "Great Foraging Potion", "forage", 10),
		_make("Regeneration Potion",{"Slime Gel": 2, "Bloodroot": 1},                    "Regeneration Potion","regen",     5),
	]

func _make(recipeName: String, ingredients: Dictionary, resultItem: String, effectType: String, effectValue: int) -> RecipeData:
	var r = RecipeData.new()
	r.recipeName = recipeName
	r.ingredients = ingredients
	r.resultItem = resultItem
	r.effectType = effectType
	r.effectValue = effectValue
	return r

func getRecipeKey(ingredients: Dictionary) -> String:
	# Sort keys so {"Wild Herb":1, "Red Berry":1} == {"Red Berry":1, "Wild Herb":1}
	var keys = ingredients.keys()
	keys.sort()
	var parts = []
	for k in keys:
		parts.append("%s:%d" % [k, ingredients[k]])
	return "|".join(parts)

func findRecipe(ingredients: Dictionary) -> RecipeData:
	var attemptKey = getRecipeKey(ingredients)
	for recipe in recipes:
		if getRecipeKey(recipe.ingredients) == attemptKey:
			return recipe
	return null

func getDiscovered(discoveredNames: Array) -> Array[RecipeData]:
	var result: Array[RecipeData] = []
	for recipe in recipes:
		if discoveredNames.has(recipe.recipeName):
			result.append(recipe)
	return result
