extends Node

var areas: Array[AreaData] = []

func _ready() -> void:
	areas = [
		_make("Hunting Grounds", 1),
		_make("Slime Swamps", 5),
		_make("Darkwood Forest", 8),
		_make("Forsaken Keep", 12),
		_make("Stoneback Mines", 18),
		_make("Ashfield Ruins", 25),
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

func getNextLockedArea() -> AreaData:
	var main = Utils.get_main()
	for a in areas:
		if not main.game_data.unlockedAreas.has(a.areaName):
			return a
	return null
