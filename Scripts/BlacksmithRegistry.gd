extends Node

var recipes: Array[BlacksmithRecipe] = []
var main:MainNode
func _ready() -> void:
	main = Utils.get_main()
	recipes = [
		# Smelting
		_make("Copper Bar", "Copper Bar", {"Copper Ore": 3, "Coal": 1}, "smelt"),
		_make("Iron Bar",   "Iron Bar",   {"Iron Ore": 3,   "Coal": 1}, "smelt"),
		_make("Gold Bar",   "Gold Bar",   {"Gold Ore": 3,   "Coal": 2}, "smelt"),
		
		_make("Coal (Oak)",    "Coal", {"Oak Log": 2},   "smelt"),
		_make("Coal (Pine)",   "Coal", {"Pine Wood": 2}, "smelt"),
		_make("Coal (Timber)", "Coal", {"Dark Timber": 1}, "smelt"),
		
		# Forging
		_make("Copper Sword", "Copper Sword", {"Copper Bar": 2},                              "forge"),
		_make("Iron Sword",   "Iron Sword",   {"Iron Bar": 2},                                "forge"),
		_make("Iron Shield",  "Iron Shield",  {"Iron Bar": 1, "Copper Bar": 1},               "forge"),
		_make("Gold Helmet",  "Gold Helmet",  {"Gold Bar": 1, "Iron Bar": 1},                 "forge"),
		_make("Fang Spear",   "Fang Spear",   {"Giant Fang": 1, "Iron Bar": 3},               "forge"),
		_make("Orc Helmet",   "Orc Helmet",   {"Orc Tooth": 5, "Beast Skin": 3, "Iron Bar": 1}, "forge"),
	]

func _make(recipeName: String, resultItem: String, ingredients: Dictionary, category: String) -> BlacksmithRecipe:
	var r = BlacksmithRecipe.new()
	r.recipeName = recipeName
	r.resultItem = resultItem
	r.ingredients = ingredients
	r.category = category
	return r

func getAvailableRecipes(category: String) -> Array[BlacksmithRecipe]:
	var result: Array[BlacksmithRecipe] = []
	for recipe in recipes:
		if recipe.category != category:
			continue
		print("checking: ", recipe.recipeName, " can craft: ", canCraft(recipe))
		if canCraft(recipe):
			result.append(recipe)
	return result

func canCraft(recipe: BlacksmithRecipe) -> bool:
	for mat in recipe.ingredients:
		var needed = recipe.ingredients[mat]
		var have = countMaterial(mat)
		if have < needed:
			return false
	return true

func countMaterial(itemName: String) -> int:
	var count = 0
	for stack in Utils.get_main().game_data.backpack:
		if stack.get("name") == itemName:
			count += stack.get("qty", 0)
	return count
