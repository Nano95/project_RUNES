extends Node
class_name LevelSystem

var main:MainNode

func _ready() -> void:
	main = Utils.get_main()
	GameEvents.areaExited.connect(onAreaExited)
	GameEvents.playerDied.connect(onPlayerDied)
	GameEvents.combatWon.connect(combat_won)

func xpForNextLevel(level: int) -> int:
	return level * 70 + (level - 1) * 25

func onAreaExited() -> void:
	# Award return bonus based on how far they went
	var bonus = main.game_data.eventCount * 1 ## This should be adjusted so that it can be variable
	if (bonus > 0):
		main.game_data.xp += bonus
		GameEvents.eventLogged.emit(
			"Safe return bonus: +%d XP." % bonus, "discover", false
		)
	checkLevelUp()

func onPlayerDied() -> void:
	# No return bonus on death
	checkLevelUp()

func combat_won(_gold:int, _xp:int) -> void:
	checkLevelUp()

func checkLevelUp() -> void:
	var leveled = false
	# Loop in case multiple levels are gained at once
	while main.game_data.xp >= xpForNextLevel(main.game_data.level):
		main.game_data.xp -= xpForNextLevel(main.game_data.level)
		main.game_data.level += 1
		main.game_data.maxHp += 10
		main.game_data.hp = min(main.game_data.maxHp, main.game_data.hp + 10)
		main.game_data.maxWeight += 5.0
		leveled = true
		GameEvents.eventLogged.emit(
			"Level up! You are now level %d. Max HP and carry weight increased." % main.game_data.level,
			"discover", false
		)
		GameEvents.leveledUp.emit()

	if (leveled):
		main.save_game()
		GameEvents.hpChanged.emit()
