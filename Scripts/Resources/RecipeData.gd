extends Resource
class_name RecipeData

@export var recipeName: String = ""
# { "Wild Herb": 2, "Red Berry": 1 } etc
@export var ingredients: Dictionary = {}
@export var resultItem: String = ""
@export var effectType: String = ""  # "heal", "strength", "swiftness", "regen", "time", "battle"
@export var effectValue: int = 0     # HP amount or effect power, 0 if TBD
