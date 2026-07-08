extends Node
class_name TickSystem

var main:MainNode
@export var combatSystem:CombatSystem

const EVENT_WEIGHTS = {
	"nothing_a": 8,
	"nothing_b": 20,
	"monster":   24,
	"ore":       12,
	"forage":    10,
	"wood":      8,
	"potion":    5,
	"dungeon":   4,
	"trap":      4,
	"nothing_c": 5,
}

func _ready() -> void:
	main = Utils.get_main()
	GameEvents.tickFired.connect(onTick)

func onTick() -> void:
	if (not main.game_data.inArea):
		return
	main.game_data.eventCount += 1
	GameEvents.eventLogged.emit("Event #%d" % main.game_data.eventCount, "system")
	
	if (main.game_data.eventCount == 100):
		AreaRegistry.tryUnlockNext(main.game_data.currentArea)
	
	# If in combat, we dont need to go further
	if (main.game_data.inCombat):
		return
	
	# If an omen occurred (pending monster), 
	if combatSystem.pendingStrongMonster:
		combatSystem.pendingStrongMonster = false
		var main = Utils.getMain()
		var monster = MonsterRegistry.rollMonster(main.game_data.currentArea, "strong")
		combatSystem.startCombat(monster)
		return
	
	# Regular events
	_roll_event()

func _roll_event() -> void:
	var roll = randf()

	if roll < 0.08:
		GameEvents.eventLogged.emit("...", "system")
		return

	if roll < 0.28:
		GameEvents.eventLogged.emit("All is quiet. Nothing stirs.", "system")
		return

	if roll < 0.52:
		combatSystem.trySpawnMonster(main.game_data.eventCount)
		return

	if roll < 0.64:
		GameEvents.eventLogged.emit("You discover an ore vein.", "gather")
		return

	if roll < 0.74:
		GameEvents.eventLogged.emit("You forage something.", "gather")
		return

	if roll < 0.82:
		GameEvents.eventLogged.emit("A fallen tree. Gathering wood...", "gather")
		return

	if roll < 0.87:
		GameEvents.eventLogged.emit("You find a health potion under a rock.", "loot")
		return

	if roll < 0.91:
		GameEvents.eventLogged.emit("You discover a dungeon entrance.", "discover")
		return

	if roll < 0.95:
		GameEvents.eventLogged.emit("You step on a trap!", "combat")
		return

	GameEvents.eventLogged.emit("A cold wind passes through.", "system")
