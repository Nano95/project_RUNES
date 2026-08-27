extends Node
class_name AreaSystem
var main

func _ready() -> void:
	GameEvents.areaEntered.connect(onAreaEntered)
	GameEvents.areaExited.connect(onAreaExited)
	GameEvents.playerDied.connect(onPlayerDied)
	main = Utils.get_main()
	main.set_background_colors(
		Vector3(0.92, 0.88, 0.65),   # soft butter
		Vector3(0.70, 0.65, 0.20)    # almost white yellow
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
		main.set_background_colors(Vector3(.297, .211, .09), Vector3(.355, .285, .133))
	elif (areaName == "Hunting Grounds"):
		main.set_background_colors(Vector3(.516, .691, .473), Vector3(.633, .793, .543))
	elif (areaName == "Slime Swamps"):
		main.set_background_colors(Vector3(.445, .488, .449), Vector3(.664, .723, .602))
	elif (areaName == "Darkwood Forest"):
		main.set_background_colors(
			Vector3(0.10, 0.12, 0.11),   # dark slate grey-green
			Vector3(0.16, 0.20, 0.15)    # muted pine
		)
	elif (areaName == "Forsaken Castle"):
		main.set_background_colors(
			Vector3(0.20, 0.16, 0.16),   # charcoal with warmth
			Vector3(0.58, 0.30, 0.30)    # soft pastel crimson
		)
	else:
		# Default
		main.set_background_colors(Vector3(.297, .211, .09), Vector3(.355, .285, .133))

func onAreaExited() -> void:
	GameEvents.eventLogged.emit("You return to town safely.", "town", false)
	main.game_data.activeStatusEffects = {}
	main.game_data.pendingLoot.clear() # For lost loot
	
	main.set_background_colors(
		Vector3(0.92, 0.88, 0.65),   # soft butter
		Vector3(0.70, 0.65, 0.20)    # almost white yellow
	)
