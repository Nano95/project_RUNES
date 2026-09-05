extends Node
class_name CombatSystem

const OMENS = [
	"You feel watched.",
	"A strong presence looms nearby.",
	"The air grows heavy. Something ancient stirs.",
	"The forest falls completely silent.",
	"A shadow passes overhead — nothing is there.",
]

const ELITE_OMENS = {
	"Hunting Grounds": "A war horn echoes in the distance...",
	"Slime Swamps": "The swamp goes eerily silent. Something massive approaches.",
}

const SUMMON_AREAS = {
	"Warchief Totem":    "Hunting Grounds",
	"Royal Totem":    "Slime Swamps",
	"Necromancer Totem": "Sandling Dunes",
}

const SUMMON_ELITES = {
	"Warchief Totem":    "Orc King",
	"Royal Totem":    "King Slime",
	"Necromancer Totem": "Mad Necromancer",
}
var pendingSummonedEliteName: String = ""
var summonedElitePending: bool = false
var summonedEliteName: String = ""

const STATUS_COUNTERS = {
	"poison": { "weak": 3, "medium": 5, "strong": 8, "elite": 12 },
	"burn":   { "weak": 4, "medium": 6, "strong": 10, "elite": 15 },
}

@export var equipmentSystem:EquipmentSystem
var battlePotionEventsLeft: int = 0
var pendingStrongMonsterIn: int = 0
var pendingMonsterTier: String = ""  # ← add this
var main:MainNode

func _ready() -> void:
	main = Utils.get_main()
	GameEvents.tickFired.connect(onTick)
	GameEvents.combatStarted.connect(onCombatStarted)
	GameEvents.fleeRequested.connect(onFleeRequested)
	GameEvents.potionUsed.connect(onPotionUsed)

func onTick() -> void:
	if not main.game_data.inArea:
		return
	if not main.game_data.inCombat:
		return
	tickCombat()

func startCombat(monster: MonsterData, weakened: bool = false) -> void:
	main.game_data.inCombat = true
	main.game_data.currentMonsterName = monster.monsterName
	main.game_data.currentMonsterTier = monster.tier
	main.game_data.currentMonsterHp = int(monster.hp * 0.5) if weakened else monster.hp
	main.game_data.currentMonsterAtk = monster.atk
	main.game_data.isFleeing = false
	main.game_data.fleeTicks = 0
	GameEvents.combatStarted.emit(monster, weakened)

func trySpawnMonster(eventCount: int) -> void:
	var tier = MonsterRegistry.rollTier(eventCount)
	if (tier == "strong" and eventCount <= 40):
		pendingStrongMonsterIn = 10
		pendingMonsterTier = "strong"
		GameEvents.eventLogged.emit(OMENS[randi() % OMENS.size()], "omen", true)
		return
	if (tier == "elite"):
		pendingStrongMonsterIn = 10
		pendingMonsterTier = "elite"
		var omen = ELITE_OMENS.get(
			main.game_data.currentArea, 
		    "Your instincts scream DANGER!"
		)
		GameEvents.eventLogged.emit(omen, "omen", true)
		return

	var monster = MonsterRegistry.rollMonster(main.game_data.currentArea, tier)
	
	# 10% chance of ambush or weakened
	if (randf() < 0.10):
		if (randf() < 0.50):
			# Ambush
			var ambushDmg = randi_range(5, 15)
			main.game_data.hp = max(1, main.game_data.hp - ambushDmg)
			main.save_game()
			GameEvents.hpChanged.emit()
			GameEvents.eventLogged.emit(
				"Ambush! A %s strikes before you can react! -%d HP" % [monster.monsterName, ambushDmg],
				"danger", false
			)
			startCombat(monster)
		else:
			# Weakened enemy
			GameEvents.eventLogged.emit(
				"A wounded %s stumbles toward you..." % monster.monsterName,
				"system", false
			)
			startCombat(monster, true)  # pass weakened flag
	else:
		startCombat(monster)

func onCombatStarted(monster: MonsterData, _weakened:bool=false) -> void:
	GameEvents.eventLogged.emit(
		"A %s appears! [%s]" % [monster.monsterName, monster.tier.to_upper()],
		"danger",
		true
	)

func tickCombat() -> void:
	var playerAtk = randi_range(4, 9) + equipmentSystem.getTotalAttack()
	main.game_data.currentMonsterHp -= playerAtk
	equipmentSystem.applyWeaponEffectOnHit()

	var finalAtk = 0
	var dodgeChance = equipmentSystem.getDodgeChance()
	var dodged = dodgeChance > 0.0 and randf() < dodgeChance

	if (not dodged):
		var rawMonsterAtk = randi_range(
			int(main.game_data.currentMonsterAtk * 0.7),
			main.game_data.currentMonsterAtk
		) + 5
		var reducedAtk = max(1, rawMonsterAtk - equipmentSystem.getTotalDefense())
		finalAtk = equipmentSystem.applyCursedShieldOnHit(reducedAtk)
		main.game_data.hp = max(0, main.game_data.hp - finalAtk)
		
		# Apply status effects on hit
		var monster = MonsterRegistry.getMonsterByAreaNameTier(
			main.game_data.currentMonsterName,
			main.game_data.currentMonsterTier,
			main.game_data.currentArea
		)
		if (monster):
			applyStatusEffects(monster)

	if main.game_data.isFleeing:
		main.game_data.fleeTicks -= 1
		if (dodged):
			GameEvents.eventLogged.emit(
				"You hit %s for %d while evading! Escaping in %d ticks..." % [
					main.game_data.currentMonsterName,
					playerAtk,
					main.game_data.fleeTicks
				], "combat", false
			)
		else:
			GameEvents.eventLogged.emit(
				"Fleeing... %s hits for %d dmg. Escaping in %d ticks..." % [
					main.game_data.currentMonsterName,
					finalAtk,
					main.game_data.fleeTicks
				], "combat", false
			)
		if (main.game_data.hp <= 0):
			die()
			return
		if (main.game_data.fleeTicks <= 0):
			flee()
			return
		GameEvents.combatTick.emit(playerAtk, finalAtk, main.game_data.currentMonsterHp)
		return

	if (dodged):
		GameEvents.eventLogged.emit(
			"You hit %s for %d while evading the attack!" % [
				main.game_data.currentMonsterName,
				playerAtk
			], "combat", false
		)
	else:
		GameEvents.eventLogged.emit(
			"You hit %s for %d. It strikes back for %d." % [
				main.game_data.currentMonsterName,
				playerAtk,
				finalAtk
			], "combat", false
		)

	if main.game_data.hp <= 0:
		die()
		return
	if main.game_data.currentMonsterHp <= 0:
		winCombat()
		return
	GameEvents.combatTick.emit(playerAtk, finalAtk, main.game_data.currentMonsterHp)

func winCombat() -> void:
	var monster = MonsterRegistry.getMonsterByAreaNameTier(
		main.game_data.currentMonsterName,
		main.game_data.currentMonsterTier, 
		main.game_data.currentArea
	)
	if not monster:
		clearCombat()
		return
	var monsterName = main.game_data.currentMonsterName
	var gold = randi_range(monster.goldMin, monster.goldMax)
	main.game_data.gold += gold
	main.game_data.stats["totalGoldEarned"] += gold
	main.game_data.sessionKills += 1
	GameEvents.eventLogged.emit(
		"%s defeated! +%d gold" % [
			monsterName,
			gold,
		], "loot", false
	)
	var drops = MonsterRegistry.rollDrops(monster)
	for drop in drops:
		GameEvents.itemDropped.emit(drop, "combat")
	
	main.game_data.stats["kills"][monsterName] = main.game_data.stats["kills"].get(monsterName, 0) + 1
	clearCombat()
	GameEvents.combatWon.emit(gold)
	main.save_game()

func flee() -> void:
	GameEvents.eventLogged.emit("You escaped!", "system", false)
	clearCombat()
	GameEvents.combatFled.emit()

func die() -> void:
	main.game_data.gold = 0
	main.game_data.backpack = []
	main.game_data.currentWeight = 0.0
	main.game_data.sessionKills = 0
	main.game_data.activeStatusEffects = {}
	main.game_data.regenCounter = 0
	main.game_data.regenPerTick = 0
	main.game_data.pendingLoot.clear()
	var area = main.game_data.currentArea
	if not main.game_data.areaStats.has(area):
		main.game_data.areaStats[area] = {"bestRun": 0, "deaths": 0}
	main.game_data.areaStats[area]["deaths"] += 1
	main.game_data.stats["deaths"] += 1  # global death count too
	clearCombat()
	GameEvents.eventLogged.emit("You have died. Your gold and inventory are lost.", "danger", false)
	GameEvents.playerDied.emit()

func clearCombat() -> void:
	main.game_data.inCombat = false
	main.game_data.currentMonsterName = ""
	main.game_data.currentMonsterTier = ""
	main.game_data.currentMonsterHp = 0
	main.game_data.currentMonsterAtk = 0
	main.game_data.isFleeing = false
	main.game_data.fleeTicks = 0

func onFleeRequested() -> void:
	if not main.game_data.inCombat or main.game_data.isFleeing:
		return
	main.game_data.isFleeing = true
	main.game_data.fleeTicks = 3
	GameEvents.eventLogged.emit("You attempt to flee...", "system", false)

func onPotionUsed(itemName: String) -> void:
	match itemName:
		"Minor Battle Potion":
			battlePotionEventsLeft += 3
			GameEvents.eventLogged.emit(
				"Minor Battle Potion consumed. Monsters attracted for %d events." % battlePotionEventsLeft,
				"danger", false
			)
		"Battle Potion":
			battlePotionEventsLeft += 6
			GameEvents.eventLogged.emit(
				"Battle Potion consumed. Monsters attracted for %d events." % battlePotionEventsLeft,
				"danger", false
			)
		"Great Battle Potion":
			battlePotionEventsLeft += 10
			GameEvents.eventLogged.emit(
				"Great Battle Potion consumed. Monsters attracted for %d events." % battlePotionEventsLeft,
				"danger", false
			)
		"Minor Antidote":
			applyAntidote(10)
		"Antidote":
			applyAntidote(20)
		"Large Antidote":
			applyAntidote(30)
		#"Warchief Totem", "Royal Totem" ,"Necromancer Totem": handled in inventorySystem
			#

func applyStatusEffects(monster: MonsterData) -> void:
	var totalEffects = equipmentSystem.getTotalEffects()
	for status in monster.statusEffects:
		var baseChance = monster.statusEffects[status]
		var resistance = totalEffects.get(status + "Resistance", 0.0)
		var finalChance = baseChance * (1.0 - resistance)
		print("status: %s base: %.2f resist: %.2f final: %.2f" % [
			status, baseChance, resistance, finalChance
		])
		if randf() < finalChance:
			applyStatus(status, monster.tier)

func applyStatus(status: String, tier: String) -> void:
	var counter = STATUS_COUNTERS[status].get(tier, 3)
	main.game_data.activeStatusEffects[status] = \
		main.game_data.activeStatusEffects.get(status, 0) + counter
	main.save_game()
	GameEvents.eventLogged.emit(
		"You have been %sed! +%d %s." % [status, counter, status], "danger", false
	)
	GameEvents.statusEffectApplied.emit(status, main.game_data.activeStatusEffects[status])

func applyAntidote(reduction: int) -> void:
	var current = main.game_data.activeStatusEffects.get("poison", 0)
	if current <= 0:
		GameEvents.eventLogged.emit(
			"You are not poisoned.", "system", false
		)
		return
	var newCounter = max(0, current - reduction)
	if newCounter <= 0:
		main.game_data.activeStatusEffects.erase("poison")
		GameEvents.eventLogged.emit(
			"Antidote consumed. Poison cleared!", "system", false
		)
		GameEvents.statusEffectCleared.emit("poison")
	else:
		main.game_data.activeStatusEffects["poison"] = newCounter
		GameEvents.eventLogged.emit(
			"Antidote consumed. Poison reduced to %d." % newCounter, "system", false
		)
		GameEvents.statusEffectApplied.emit("poison", newCounter)
	main.save_game()
	GameEvents.hpChanged.emit()

func _handleSummon(itemName: String) -> bool:
	print("=== _handleSummon called: ", itemName)
	print("pendingStrongMonsterIn: ", pendingStrongMonsterIn)
	print("summonedElitePending: ", summonedElitePending)
	var requiredArea = SUMMON_AREAS.get(itemName, "")
	if main.game_data.currentArea != requiredArea:
		GameEvents.eventLogged.emit(
			"This totem has no power here.", "system", false
		)
		return false

	if pendingStrongMonsterIn > 0 or summonedElitePending:
		GameEvents.eventLogged.emit(
			"Something is already coming...", "system", false
		)
		return false

	summonedElitePending = true
	summonedEliteName = SUMMON_ELITES.get(itemName, "")
	GameEvents.eventLogged.emit(
		"The ground trembles... something ancient stirs.", "danger", false
	)
	return true

func isBattlePotionActive() -> bool:
	return battlePotionEventsLeft > 0

func onAreaExited() -> void:
	battlePotionEventsLeft = 0
	summonedElitePending = false
	summonedEliteName = ""
	pendingSummonedEliteName = ""

func onPlayerDied() -> void:
	battlePotionEventsLeft = 0
	summonedElitePending = false
	summonedEliteName = ""
	pendingSummonedEliteName = ""
