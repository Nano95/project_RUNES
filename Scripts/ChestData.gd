extends Resource
class_name ChestData

@export var id: int = 0
@export var unlocked: bool = false
# Each entry is { "name": String, "qty": int }
@export var items: Array[Dictionary] = [{ "name": "Health Potion", "qty": 10 }]
@export var upgradeLevel: int = 0
