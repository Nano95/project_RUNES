extends Node

var areas: Array[AreaData] = []

func _ready() -> void:
	areas = [
		_make("Outskirts", 1),
		_make("Whispering Woods", 1),
		_make("Goblin Warren", 3),
		_make("Stoneback Mines", 5),
		_make("Ashfield Ruins", 8),
	]

func _make(newName: String, minLevel: int) -> AreaData:
	var a = AreaData.new()
	a.areaName = newName
	a.minLevel = minLevel
	return a

func getArea(areaName: String) -> AreaData:
	for a in areas:
		if a.areaName == areaName:
			return a
	return null
