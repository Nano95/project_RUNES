extends Node
class_name TickSystem

var main:MainNode
@export var combatSystem:CombatSystem
@export var gatherSystem:GatherSystem

var checkpointPending: bool = false
var checkpointPendingAfterCombat: bool = false

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
	#print("Tick", main.game_data.inArea, checkpointPending, main.game_data.inCombat)
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
		if (checkpointPending):
			return
			# pause gathering ticks during checkpoint
		gatheringTicksLeft -= 1
		if (gatheringTicksLeft == 0):
			GameEvents.eventLogged.emit(
				"Gathered %s." % gatheringItem, "loot", false
			)
			GameEvents.gatherCompleted.emit(gatheringItem)
			gatheringItem = ""
			# Check if a checkpoint was waiting for gathering to finish
			if (checkpointPendingAfterCombat):
				checkpointPendingAfterCombat = false
				triggerCheckpoint()
		else:
			GameEvents.eventLogged.emit(
				"Gathering %s... (%d ticks left)" % [gatheringItem, gatheringTicksLeft], "gather", false
			)
			GameEvents.gatherTick.emit(gatheringItem, gatheringTicksLeft)
		return
	
	main.game_data.eventCount += 1
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
	if (main.game_data.eventCount % 10 == 0):
		if (main.game_data.inCombat or gatheringTicksLeft > 0):
			# Defer checkpoint until combat/gathering resolves
			checkpointPendingAfterCombat = true
		else:
			triggerCheckpoint()

func onGatherStarted(itemName: String, ticks: int) -> void:
	gatheringItem = itemName
	gatheringTicksLeft = ticks

func onPlayerDied() -> void:
	checkpointPending = false
	gatheringItem = ""
	gatheringTicksLeft = 0
	combatSystem.pendingStrongMonsterIn = 0
	

func onAreaExited() -> void:
	gatheringItem = ""
	gatheringTicksLeft = 0
	checkpointPending = false
	combatSystem.pendingStrongMonsterIn = 0

# Takes in two dummy params because combatWon emits two arguments, but are not needed here
func onCombatResolved(_a = null, _b = null) -> void:
	# Decrement battle potion counter after each combat
	if (combatSystem.isBattlePotionActive()):
		combatSystem.battlePotionEventsLeft -= 1
		if (combatSystem.battlePotionEventsLeft > 0):
			GameEvents.eventLogged.emit(
				"Battle potion active — %d events remaining." % combatSystem.battlePotionEventsLeft,
				"danger", false
			)
		else:
			GameEvents.eventLogged.emit(
				"Battle potion wore off.", "system", false
			)
	# Combat finished — check if a checkpoint was waiting
	if (checkpointPendingAfterCombat):
		checkpointPendingAfterCombat = false
		triggerCheckpoint()
		return
	if (checkpointPending):
		GameEvents.checkpointReached.emit()

func triggerCheckpoint() -> void:
	checkpointPending = true
	GameEvents.checkpointReached.emit()

func onCheckpointContinued() -> void:
	checkpointPending = false

func _roll_event() -> void:
	var roll = randf()
	# Battle potion active — 90% monster chance
	if combatSystem.isBattlePotionActive():
		if randf() < 0.90:
			combatSystem.trySpawnMonster(main.game_data.eventCount)
		else:
			GameEvents.eventLogged.emit("The area feels tense...", "system", true)
		return
	
	# Foraging potion active — 90% forage chance
	if gatherSystem.isForagingPotionActive():
		if randf() < 0.90:
			gatherSystem.startForage()
		else:
			GameEvents.eventLogged.emit("The undergrowth rustles softly...", "gather", true)
		gatherSystem.decrementForagingPotion()
		return
	
	if roll < 0.29:
		GameEvents.eventLogged.emit("All is quiet. Nothing stirs.", "system", true)
		return

	if roll < 0.53:
		combatSystem.trySpawnMonster(main.game_data.eventCount)
		return

	if roll < 0.62:
		gatherSystem.startOreGather()
		return

	if roll < 0.76:
		gatherSystem.startForage()
		return

	if roll < 0.80:
		gatherSystem.startWoodGather()
		return

	if (roll < 0.87):
		if (randf() < 0.70):
			GameEvents.eventLogged.emit("You find a health potion tucked under a rock.", "loot", true)
			GameEvents.itemDropped.emit("Health Potion")
		else:
			var gold = getAreaGoldFind()
			main.game_data.gold += gold
			main.save_game()
			GameEvents.eventLogged.emit("You find a pouch of gold! +%d gold." % gold, "loot", true)
			GameEvents.hpChanged.emit()
		return

	if roll < 0.91:
		GameEvents.eventLogged.emit("You discover a dungeon entrance.", "discover", true)
		return

	if roll < 0.95:
		GameEvents.eventLogged.emit("You step on a trap!", "combat", true)
		triggerTrap()
		return

	GameEvents.eventLogged.emit("A cold wind passes through.", "system", true)

func getAreaGoldFind() -> int:
	match main.game_data.currentArea:
		"Hunting Grounds": return randi_range(30, 80)
		"Outskirts":       return randi_range(50, 120)
		_:                 return randi_range(130, 180)

func triggerTrap() -> void:
	var traps = [
		"You got a splinter climbing a tree for the 'views.'",
		"You tripped over a root and face planted.",
		"You got chased by a goose. The goose won.",
		"You kicked a rock out of frustration... the rock won.",
		"You accidentally poked yourself with your own sword.",
		"You sneezed so hard you pulled a muscle.",
		"You were stung by a bee. You learn you're allergic.",
		"A sudden gust of wind blew dirt in your eyes.",
		"You stopped to smell flowers and inhaled a bee.",
		"You tripped on flat ground. Ego demolished.",
	]

	# Add area-specific pet trap if we can find a weak monster
	var weakMonster = getAreaWeakCreature(main.game_data.currentArea)
	if weakMonster != "":
		traps.append("You tried to pet a %s. It disagreed." % weakMonster)

	var message = traps[randi() % traps.size()]
	var dmg = getAreaTrapDamage(main.game_data.currentArea)
	main.game_data.hp = max(1, main.game_data.hp - dmg)
	main.save_game()
	GameEvents.eventLogged.emit(
		"%s -%d HP." % [message, dmg], "combat", true
	)
	GameEvents.hpChanged.emit()

func getAreaWeakCreature(area: String) -> String:
	if not MonsterRegistry.areaMonsters.has(area):
		return ""
	var weakList = MonsterRegistry.areaMonsters[area]["weak"] as Array
	if weakList.is_empty():
		return ""
	var monster = weakList[randi() % weakList.size()] as MonsterData
	return monster.monsterName

func getAreaTrapDamage(area: String) -> int:
	match area:
		"Hunting Grounds":  return randi_range(2, 8)
		"Outskirts":        return randi_range(5, 15)
		"Darkwood Forest":  return randi_range(10, 22)
		"Ashfield Ruins":   return randi_range(15, 30)
		"The Abyssal Depths": return randi_range(25, 45)
		_:                  return randi_range(2, 8)
