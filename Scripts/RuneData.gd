extends Resource
class_name RuneData

@export var name: String
@export var mini_name: String
@export var icon: Texture2D
@export var pattern: String   # "single", "plus", "aoe3", "heal", "buff", etc.
@export var activation: String = "grid"  # "grid", "instant"
@export var power: int = 0
@export var focus_cost: int = 1
@export var rune_type: String = "arcane" # arcane, electric, fire, ice, earth, heal
@export var buy_cost:int = 100
