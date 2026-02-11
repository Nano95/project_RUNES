extends Resource
class_name RuneData

@export var name: String
@export var icon: Texture2D
@export var pattern: String   # "single", "plus", "aoe3", "heal", "buff", etc.
@export var activation: String = "grid"  # "grid", "instant"
@export var power: int = 0
