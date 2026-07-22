extends Resource
class_name BlacksmithRecipe

@export var recipeName: String = ""
@export var resultItem: String = ""
@export var ingredients: Dictionary = {}
@export var category: String = ""  # "smelt" or "forge"
