extends Resource
class_name ItemData

@export var itemName: String = ""
@export var itemType: String = ""  # "equipment", "part", "forageable", "ore", "potion"
@export var stackable: bool = true
@export var weight: float = 1.0
@export var description: String = ""
@export var value: int = 0  # base gold value for future selling
