extends Resource
class_name AreaData

@export var areaName: String = ""
@export var minLevel: int = 1
@export var unlockEventCount: int = 100  # events needed in previous area to unlock this
@export var isUnlocked: bool = false
