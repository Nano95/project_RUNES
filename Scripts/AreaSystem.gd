extends Node
class_name AreaSystem
var main

func _ready() -> void:
	GameEvents.areaEntered.connect(onAreaEntered)
	GameEvents.areaExited.connect(onAreaExited)
	GameEvents.playerDied.connect(onPlayerDied)
	main = Utils.get_main()

func enterArea(areaName: String) -> void:
	main.game_data.currentArea = areaName
	main.game_data.inArea = true
	main.game_data.eventCount = 0
	main.save_game()
	GameEvents.areaEntered.emit(areaName)

func onPlayerDied() -> void:
	main.game_data.inArea = false
	main.game_data.currentArea = ""
	GameEvents.eventLogged.emit("You wake up in town.", "town", false)
	main.save_game()

func exitArea() -> void:
	var carried = main.game_data.gold
	if (carried > 0):
		main.game_data.savedGold += carried
		main.game_data.gold = 0
		GameEvents.eventLogged.emit(
			"You deposit %d gold in town. Total saved: %d." % [carried, main.game_data.savedGold],
			"town", false
		)
		GameEvents.goldDeposited.emit(carried)
	
	main.game_data.currentArea = ""
	main.game_data.inArea = false
	main.save_game()
	GameEvents.areaExited.emit()

func onAreaEntered(areaName: String) -> void:
	GameEvents.eventLogged.emit("You enter " + areaName + ".", "discover", false)

func onAreaExited() -> void:
	GameEvents.eventLogged.emit("You return to town safely.", "town", false)
