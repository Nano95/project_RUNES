extends Node

var recipes: Array[BlacksmithRecipe] = []
var main:MainNode
func _ready() -> void:
	main = Utils.get_main()
	recipes = [
		# Smelting
		_make("Copper Bar", "Copper Bar", {"Copper Ore": 3, "Coal": 2}, "smelt"),
		_make("Iron Bar",   "Iron Bar",   {"Iron Ore": 3,   "Coal": 2}, "smelt"),
		_make("Gold Bar",   "Gold Bar",   {"Gold Ore": 3,   "Coal": 3}, "smelt"),
		
		# ORC THINGS
		_make("Orc Helmet",  "Orc Helmet",  {"King's Tusk": 1, "Copper Bar": 3},        "forge"),
		_make("Orc Armor",   "Orc Armor",   {"Orc General Crest": 2, "Copper Bar": 4},  "forge"),
		_make("Orc Legs",    "Orc Legs",    {"Orc Leather": 10, "Copper Bar": 3},       "forge"),
		_make("Orc Boots",   "Orc Boots",   {"Orc Leather": 10, "Copper Bar": 2},       "forge"),
		_make("Warchief Totem", "Warchief Totem", {"King's Tusk": 2, "Orc Leather": 5}, "forge"),
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
		#print("checking: ", recipe.recipeName, " can craft: ", canCraft(recipe))
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
