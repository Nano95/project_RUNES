extends Node
class_name AreaSystem
var main

func _ready() -> void:
	GameEvents.areaEntered.connect(onAreaEntered)
	GameEvents.areaExited.connect(onAreaExited)
	main = Utils.get_main()

func enterArea(areaName: String) -> void:
	main.game_data.currentArea = areaName
	main.game_data.inArea = true
	main.game_data.eventCount = 0
	main.save_game()
	GameEvents.areaEntered.emit(areaName)

func exitArea() -> void:
	main.game_data.currentArea = ""
	main.game_data.inArea = false
	main.save_game()
	GameEvents.areaExited.emit()

func onAreaEntered(areaName: String) -> void:
	GameEvents.eventLogged.emit("You enter " + areaName + ".", "discover")

func onAreaExited() -> void:
	GameEvents.eventLogged.emit("You return to the safe zone.", "town")
