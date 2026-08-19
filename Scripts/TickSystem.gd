extends Node
class_name TickSystem

var main:MainNode
@export var combatSystem:CombatSystem
@export var gatherSystem:GatherSystem
@export var equipmentSystem:EquipmentSystem

var checkpointPending: bool = false
var checkpointPendingAfterCombat: bool = false

var gatheringItem: String = ""
var gatheringTicksLeft: int = 0
var goldPotionChance: float = .09
var currentArea: String = ""
var eventWeights: Array[Dictionary]
var eventWeightsTotal: int = 0

func _ready() -> void:
	main = Utils.get_main()
	GameEvents.tickFired.connect(onTick)
	GameEvents.checkpointContinued.connect(onCheckpointContinued)
	GameEvents.combatWon.connect(onCombatResolved)
	GameEvents.combatFled.connect(onCombatResolved)
	GameEvents.playerDied.connect(onPlayerDied)
	GameEvents.areaEntered.connect(onAreaEntered)
	GameEvents.areaExited.connect(onAreaExited)
	GameEvents.gatherStarted.connect(onGatherStarted)

func onTick() -> void:
	#print("Tick", main.game_data.inArea, checkpointPending, main.game_data.inCombat)
	if (not main.game_data.inArea):
		if (main.game_data.hp < equipmentSystem.cachedMaxHp):
			main.game_data.hp += 1
			GameEvents.hpChanged.emit()
		return
	if (checkpointPending):
		return
	if (main.game_data.inCombat):
		return
		
	# Tick status effects every event
	tickStatusEffects()

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

func onAreaEntered(area:String) -> void:
	currentArea = area
	buildEventTable()

func onAreaExited() -> void:
	gatheringItem = ""
	gatheringTicksLeft = 0
	checkpointPending = false
	combatSystem.pendingStrongMonsterIn = 0

# Takes in two dummy params because combatWon emits two arguments, but are not needed here
func onCombatResolved(_a = null) -> void:
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
	buildEventTable()
	checkpointPending = false

func rollWeightedEvent() -> String:
	if eventWeights.is_empty():
		buildEventTable()

	var roll = randi() % eventWeightsTotal # Calculated inside of builtEventTable once every checkpoint
	var cumulative = 0
	for entry in eventWeights:
		cumulative += entry["weight"]
		if roll < cumulative:
			return entry["event"]
	return "nothing_c"

func _roll_event() -> void:
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
	
	match rollWeightedEvent():
		"nothing_a":
			GameEvents.eventLogged.emit("...", "system", true)
		"nothing_b", "nothing_c":
			GameEvents.eventLogged.emit("All is quiet. Nothing stirs.", "system", true)
		"monster":
			combatSystem.trySpawnMonster(main.game_data.eventCount)
		"ore":
			gatherSystem.startOreGather()
		"forage":
			gatherSystem.startForage()
		"wood":
			gatherSystem.startWoodGather()
		"potion_gold":
			if randf() < 0.70:
				GameEvents.eventLogged.emit("You find a health potion tucked under a rock.", "loot", true)
				GameEvents.itemDropped.emit("Health Potion")
			else:
				var gold = getAreaGoldFind()
				main.game_data.gold += gold
				main.save_game()
				GameEvents.eventLogged.emit("You find a pouch of gold! +%d gold." % gold, "loot", true)
				GameEvents.hpChanged.emit()
		"dungeon":
			GameEvents.eventLogged.emit("You discover a dungeon entrance.", "discover", true)
		"trap":
			triggerTrap()
		_:
			GameEvents.eventLogged.emit("A cold wind passes through.", "system", true)

func getPotionGoldChance() -> int:
	var eventCount = main.game_data.eventCount
	if eventCount <= 30:
		return 9
	elif eventCount <= 60:
		return 6
	elif eventCount <= 100:
		return 3
	return 1

func getAreaGoldFind() -> int:
	match main.game_data.currentArea:
		"Hunting Grounds": return randi_range(30, 80)
		"Slime Swamps":       return randi_range(50, 120)
		"Darkwood Forest":  return randi_range(130, 180)
		"Forsaken Keep": return randi_range(170, 280) # gold find
		_:                 return randi_range(130, 180)

func tickStatusEffects() -> void:
	if main.game_data.activeStatusEffects.is_empty():
		return

	var toClear = []
	for status in main.game_data.activeStatusEffects:
		var counter = main.game_data.activeStatusEffects[status]
		if counter <= 0:
			toClear.append(status)
			continue

		# Calculate damage — cannot kill
		var damage = counter
		var newHp = max(1, main.game_data.hp - damage)
		
		# If would kill, clear poison instead
		if main.game_data.hp - damage <= 0:
			toClear.append(status)
			GameEvents.eventLogged.emit(
				"The %s wears off just in time..." % status, "danger", false
			)
		else:
			main.game_data.hp = newHp
			main.game_data.activeStatusEffects[status] = counter - 1
			if main.game_data.activeStatusEffects[status] <= 0:
				toClear.append(status)
			GameEvents.eventLogged.emit(
				"%s damage! -%d HP (%d remaining)" % [
					status.capitalize(),
					damage,
					main.game_data.activeStatusEffects[status]
				], "danger", false
			)
			GameEvents.statusEffectTicked.emit(status, main.game_data.activeStatusEffects[status], damage)
			GameEvents.hpChanged.emit()

	for status in toClear:
		main.game_data.activeStatusEffects.erase(status)
		if not toClear.is_empty():
			GameEvents.eventLogged.emit(
				"%s cleared." % status.capitalize(), "system", false
			)
			GameEvents.statusEffectCleared.emit(status)

	main.save_game()

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
		"Slime Swamps":        return randi_range(5, 15)
		"Darkwood Forest":  return randi_range(10, 22)
		"Forsaken Keep": return randi_range(18, 35)  # trap damage
		"Ashfield Ruins":   return randi_range(15, 30)
		"The Abyssal Depths": return randi_range(25, 45)
		_:                  return randi_range(2, 8)

func buildEventTable() -> void:
	goldPotionChance = getPotionGoldChance()
	
	match currentArea:
		"Hunting Grounds":
			eventWeights = [
				{ "event": "nothing_a",   "weight": 8  },
				{ "event": "nothing_b",   "weight": 15 },
				{ "event": "monster",     "weight": 23 },
				{ "event": "forage",      "weight": 20 },
				{ "event": "potion_gold", "weight": goldPotionChance },
				{ "event": "trap",        "weight": 4   },
				{ "event": "nothing_c",   "weight": 15 },
			]
		"Slime Swamps":
			eventWeights = [
				{ "event": "nothing_a",   "weight": 8  },
				{ "event": "nothing_b",   "weight": 16 },
				{ "event": "monster",     "weight": 24 },
				#{ "event": "ore",         "weight": 12 },
				{ "event": "forage",      "weight": 20 },
				#{ "event": "wood",        "weight": 6  },
				{ "event": "potion_gold", "weight": goldPotionChance },
				#{ "event": "dungeon",     "weight": 4  },
				{ "event": "trap",        "weight": 2  },
				{ "event": "nothing_c",   "weight": 10 },
			]
		"Darkwood Forest":
			eventWeights = [
				{ "event": "nothing_a",   "weight": 10 },
				{ "event": "nothing_b",   "weight": 18 },
				{ "event": "monster",     "weight": 28 },
				#{ "event": "ore",         "weight": 6  },
				{ "event": "forage",      "weight": 14 }, # more foraging in forest
				#{ "event": "wood",        "weight": 10 }, # more wood in forest
				{ "event": "potion_gold", "weight": goldPotionChance },
				#{ "event": "dungeon",     "weight": 4  },
				{ "event": "trap",        "weight": 8  },
				{ "event": "nothing_c",   "weight": 12 },
			]
		"Forsaken Keep":
			eventWeights = [
				{ "event": "nothing_a",   "weight": 10 },
				{ "event": "nothing_b",   "weight": 13 },
				{ "event": "monster",     "weight": 33 }, # heavily monster focused
				{ "event": "forage",      "weight": 6  }, # barely any foraging
				{ "event": "potion_gold", "weight": goldPotionChance },
				{ "event": "trap",        "weight": 16 }, # lots of traps
				{ "event": "nothing_c",   "weight": 20 }, # eerie silence
			]
		"Ashfield Ruins":
			eventWeights = [
				{ "event": "nothing_a",   "weight": 10 },
				{ "event": "nothing_b",   "weight": 15 },
				{ "event": "monster",     "weight": 35 },
				{ "event": "forage",      "weight": 5  },
				{ "event": "potion_gold", "weight": goldPotionChance },
				{ "event": "trap",        "weight": 10 },
				{ "event": "nothing_c",   "weight": 15 },
			]
		_: # default fallback
			eventWeights = [
				{ "event": "nothing_a",   "weight": 8  },
				{ "event": "nothing_b",   "weight": 20 },
				{ "event": "monster",     "weight": 24 },
				{ "event": "ore",         "weight": 12 },
				{ "event": "forage",      "weight": 10 },
				{ "event": "wood",        "weight": 8  },
				{ "event": "potion_gold", "weight": goldPotionChance },
				{ "event": "dungeon",     "weight": 4  },
				{ "event": "trap",        "weight": 4  },
				{ "event": "nothing_c",   "weight": 10 },
			]
	# Cache total
	eventWeightsTotal = 0
	for entry in eventWeights:
		eventWeightsTotal += entry["weight"]
