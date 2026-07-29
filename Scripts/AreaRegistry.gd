extends Node

var areas: Array[AreaData] = []

func _ready() -> void:
	areas = [
		_make("Hunting Grounds", 1),
		_make("Outskirts", 5),
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

func tryUnlockNext(currentAreaName: String) -> void:
	var main = Utils.get_main()
	var currentIndex = -1
	for i in areas.size():
		if areas[i].areaName == currentAreaName:
			currentIndex = i
			break

	if currentIndex == -1 or currentIndex + 1 >= areas.size():
		return
	
	var nextArea = areas[currentIndex + 1]
	if not main.game_data.unlockedAreas.has(nextArea.areaName):
		main.game_data.unlockedAreas.append(nextArea.areaName)
		main.save_game()
		GameEvents.areaUnlocked.emit(nextArea.areaName)
