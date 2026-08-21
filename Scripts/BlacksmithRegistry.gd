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
		_make("Orc Helmet",  "Orc Helmet",  {"Orc Leather": 10, "Copper Bar": 1},        "forge"),
		_make("Orc Armor",   "Orc Armor",   {"Orc General Crest": 2, "Copper Bar": 4},  "forge"),
		_make("Orc Legs",    "Orc Legs",    {"Orc Leather": 10, "Copper Bar": 3},       "forge"),
		_make("Orc Boots",   "Orc Boots",   {"Orc Leather": 10, "Copper Bar": 2},       "forge"),
		_make("Orc King Shield",   "Orc King Shield",   {"King's Tusk": 1, "Iron Bar": 3},       "forge"),
		_make("Warchief Totem", "Warchief Totem", {"King's Tusk": 2, "Orc Leather": 5}, "forge"),

		# Slimy Set
		_make("Slimy Helmet", "Slimy Helmet", {"Slime Gel": 8,  "Iron Bar": 2},              "forge"),
		_make("Slimy Armor",  "Slimy Armor",  {"Slime Gel": 12, "Iron Bar": 3},              "forge"),
		_make("Slimy Legs",   "Slimy Legs",   {"Slime Gel": 10, "Iron Bar": 2},              "forge"),
		_make("Slimy Boots",  "Slimy Boots",  {"Slime Gel": 8,  "Iron Bar": 2},              "forge"),
		_make("Slimy Blade",  "Slimy Blade",  {"Slime Core": 1, "Iron Bar": 3},              "forge"),
		_make("Slimy Shield", "Slimy Shield", {"Slime Core": 1, "Slime Gel": 5, "Iron Bar": 2}, "forge"),

		_make("Sandling Helmet", "Sandling Helmet", {"Crystal Bone": 1, "Iron Bar": 3}, "forge"),
		_make("Sandling Armor",  "Sandling Armor",  {"Crystal Bone": 2, "Iron Bar": 4}, "forge"),
		_make("Sandling Legs",   "Sandling Legs",   {"Bone Dust": 10,   "Iron Bar": 3}, "forge"),
		_make("Sandling Boots",  "Sandling Boots",  {"Bone Dust": 8,    "Iron Bar": 2}, "forge"),
		_make("Sandling Blade",  "Sandling Blade",  {"Crystal Bone": 1, "Iron Bar": 3}, "forge"),
		_make("Sandling Shield", "Sandling Shield", {"Ancient Relic": 1,"Iron Bar": 2}, "forge"),
		_make("Necromancer Totem", "Necromancer Totem", {"Ancient Relic": 1, "Bone Dust": 10}, "forge"),
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
