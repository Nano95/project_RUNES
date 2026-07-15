extends Node
class_name TickSystem

var main:MainNode
@export var combatSystem:CombatSystem
@export var gatherSystem:GatherSystem
var checkpointPending: bool = false
var eventsSinceLastCheckpoint: int = 0

var gatheringItem: String = ""
var gatheringTicksLeft: int = 0

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
	GameEvents.checkpointContinued.connect(onCheckpointContinued)
	GameEvents.combatWon.connect(onCombatResolved)
	GameEvents.combatFled.connect(onCombatResolved)
	GameEvents.playerDied.connect(onPlayerDied)
	GameEvents.areaExited.connect(onAreaExited)
	GameEvents.gatherStarted.connect(onGatherStarted)

func onTick() -> void:
	print("Tick", main.game_data.inArea, checkpointPending, main.game_data.inCombat)
	if (not main.game_data.inArea):
		if main.game_data.hp < main.game_data.maxHp:
			main.game_data.hp += 1
			GameEvents.hpChanged.emit()
		return
	if (checkpointPending):
		return
	if (main.game_data.inCombat):
		return
	# Handle active gathering
	if (gatheringTicksLeft > 0):
		gatheringTicksLeft -= 1
		if (gatheringTicksLeft == 0):
			GameEvents.eventLogged.emit(
				"Gathered %s." % gatheringItem, "loot", false
			)
			GameEvents.gatherCompleted.emit(gatheringItem)
			gatheringItem = ""
			# Check if a checkpoint was waiting for gathering to finish
			if (eventsSinceLastCheckpoint >= 10 and not main.game_data.inCombat):
				triggerCheckpoint()
		else:
			GameEvents.eventLogged.emit(
				"Gathering %s... (%d ticks left)" % [gatheringItem, gatheringTicksLeft], "gather", false
			)
			GameEvents.gatherTick.emit(gatheringItem, gatheringTicksLeft)
		return
	
	main.game_data.eventCount += 1
	eventsSinceLastCheckpoint += 1
	if (main.game_data.eventCount == 100):
		AreaRegistry.tryUnlockNext(main.game_data.currentArea)
	
	# If in combat, we dont need to go further
	if (main.game_data.inCombat):
		return
	
	# If an omen occurred (pending monster), 
	if (combatSystem.pendingStrongMonsterIn > 0):
		combatSystem.pendingStrongMonsterIn -= 1
		if (combatSystem.pendingStrongMonsterIn == 0):
			var monster = MonsterRegistry.rollMonster(main.game_data.currentArea, "strong")
			combatSystem.startCombat(monster)
			return
	
	# Regular events
	_roll_event()
	# Check checkpoint AFTER event resolves
	# but only if we didn't just start combat
	if eventsSinceLastCheckpoint >= 10 and not main.game_data.inCombat:
		triggerCheckpoint()

func onGatherStarted(itemName: String, ticks: int) -> void:
	gatheringItem = itemName
	gatheringTicksLeft = ticks

func onPlayerDied() -> void:
	checkpointPending = false
	eventsSinceLastCheckpoint = 0
	gatheringItem = ""
	gatheringTicksLeft = 0
	combatSystem.pendingStrongMonsterIn = 0

func onAreaExited() -> void:
	gatheringItem = ""
	gatheringTicksLeft = 0
	checkpointPending = false
	eventsSinceLastCheckpoint = 0
	combatSystem.pendingStrongMonsterIn = 0

# Takes in two dummy params because combatWon emits two arguments, but are not needed here
func onCombatResolved(_a = null, _b = null) -> void:
	# Combat finished — check if a checkpoint was waiting
	if checkpointPending:
		GameEvents.checkpointReached.emit()

func triggerCheckpoint() -> void:
	checkpointPending = true
	eventsSinceLastCheckpoint = 0
	GameEvents.checkpointReached.emit()

func onCheckpointContinued() -> void:
	checkpointPending = false

# TODO: Come up with better ones
func triggerTrap() -> void:
	var trap = randi() % 3
	if trap == 0:
		var dmg = randi_range(8, 16)
		main.game_data.hp = max(1, main.game_data.hp - dmg)
		main.save_game()
		GameEvents.eventLogged.emit("You step on a bear trap! Lost %d HP." % dmg, "combat")
		GameEvents.combatTick.emit(0, dmg, 0)
	elif trap == 1:
		var dmg = randi_range(4, 8)
		main.game_data.hp = max(1, main.game_data.hp - dmg)
		main.save_game()
		GameEvents.eventLogged.emit("A poison dart hits you! Lost %d HP." % dmg, "combat")
		GameEvents.combatTick.emit(0, dmg, 0)
	else:
		GameEvents.eventLogged.emit("You sense something wrong — and sidestep a pitfall.", "system")

func _roll_event() -> void:
	var roll = randf()

	if roll < 0.08:
		GameEvents.eventLogged.emit("...", "system", true)
		return

	if roll < 0.28:
		GameEvents.eventLogged.emit("All is quiet. Nothing stirs.", "system", true)
		return

	if roll < 0.52:
		combatSystem.trySpawnMonster(main.game_data.eventCount)
		return

	if roll < 0.64:
		gatherSystem.startOreGather()
		return

	if roll < 0.74:
		gatherSystem.startForage()
		return

	if roll < 0.82:
		gatherSystem.startWoodGather()
		return

	if roll < 0.87:
		GameEvents.eventLogged.emit("You find a health potion under a rock.", "loot", true)
		GameEvents.itemDropped.emit("Health Potion")
		return

	if roll < 0.91:
		GameEvents.eventLogged.emit("You discover a dungeon entrance.", "discover", true)
		return

	if roll < 0.95:
		GameEvents.eventLogged.emit("You step on a trap!", "combat", true)
		#triggerTrap()
		return

	GameEvents.eventLogged.emit("A cold wind passes through.", "system", true)
