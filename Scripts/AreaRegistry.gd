extends Node

var areas: Array[AreaData] = []

func _ready() -> void:
	areas = [
		_make("Hunting Grounds", 1),
		_make("Slime Swamps", 5),
		_make("Sandling Dunes", 15),
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

func getUnlockedAreas() -> Array[String]:
	var unlocked = ["Hunting Grounds"]  # always unlocked
	var map = Utils.get_main().game_data.equippedExpeditionMap
	if map.is_empty():
		return unlocked
	var unlocksArea = map.get("effects", {}).get("unlocksArea", "")
	match unlocksArea:
		"Slime Swamps":
			unlocked.append("Slime Swamps")
		"Sandling Dunes":
			unlocked.append("Slime Swamps")
			unlocked.append("Sandling Dunes")
	return unlocked
