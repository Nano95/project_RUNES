extends Resource
class_name LootItem

## WHEN ADDING AN ITEM THAT IS GOING TO BE LOOTED IN BATTLE
# MAKE SURE YOU ARE ADDING IT TO THE ItemsDatabase.gd script!
@export var id: String
@export var name: String
@export var description: String
@export var icon: Texture
