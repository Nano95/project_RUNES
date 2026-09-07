extends Node
class_name AreaSystem
var main

func _ready() -> void:
	GameEvents.areaEntered.connect(onAreaEntered)
	GameEvents.areaExited.connect(onAreaExited)
	GameEvents.playerDied.connect(onPlayerDied)
	main = Utils.get_main()
	main.set_background_colors(
		Vector3(0.40, 0.58, 0.82),   # soft butter
		Vector3(0.45, 0.63, 0.86)   # almost white yellow
	)
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
			"You deposit %d gold in town. Bank: %d." % [carried, main.game_data.savedGold],
			"town", false
		)
		GameEvents.goldDeposited.emit(carried)
	
	main.game_data.currentArea = ""
	main.game_data.inArea = false
	main.save_game()
	GameEvents.areaExited.emit()

func onAreaEntered(areaName: String) -> void:
	GameEvents.eventLogged.emit("You enter " + areaName + ".", "discover", false)

	if (areaName == "Town"):
		main.set_background_colors(Vector3(0.40, 0.58, 0.82), Vector3(0.45, 0.63, 0.86))
	elif (areaName == "Hunting Grounds"):
		main.set_background_colors(Vector3(0.60, 0.82, 0.60), Vector3(0.55, 0.78, 0.55))
	elif (areaName == "Slime Swamps"):
		main.set_background_colors(Vector3(0.25, 0.38, 0.20), Vector3(0.30, 0.43, 0.24))
	elif (areaName == "Sandling Dunes"):
		main.set_background_colors(
			Vector3(0.85, 0.72, 0.40),   # dark slate grey-green
			Vector3(0.88, 0.76, 0.46)    # muted pine
		)
	elif (areaName == "Forsaken Castle"):
		main.set_background_colors(
			Vector3(0.20, 0.16, 0.16),   # charcoal with warmth
			Vector3(0.58, 0.30, 0.30)    # soft pastel crimson
		)
	else:
		# Default
		main.set_background_colors(Vector3(0.40, 0.58, 0.82), Vector3(0.45, 0.63, 0.86))

func onAreaExited() -> void:
	GameEvents.eventLogged.emit("You return to town safely.", "town", false)
	main.game_data.activeStatusEffects = {}
	main.game_data.pendingLoot.clear() # For lost loot
	
	main.set_background_colors(Vector3(0.40, 0.58, 0.82), Vector3(0.45, 0.63, 0.86))
