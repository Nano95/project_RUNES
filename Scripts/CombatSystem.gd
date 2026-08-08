extends Node
class_name CombatSystem

const OMENS = [
	"You feel watched.",
	"A strong presence looms nearby.",
	"The air grows heavy. Something ancient stirs.",
	"The forest falls completely silent.",
	"Your instincts scream danger.",
	"A shadow passes overhead — nothing is there.",
]

@export var equipmentSystem:EquipmentSystem
var battlePotionEventsLeft: int = 0
var pendingStrongMonsterIn: int = 0
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
	if tier == "strong" and eventCount <= 40:
		pendingStrongMonsterIn = 10
		GameEvents.eventLogged.emit(OMENS[randi() % OMENS.size()], "omen", true)
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
			], "gather", false
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
	var gold = randi_range(monster.goldMin, monster.goldMax)
	main.game_data.gold += gold
	main.game_data.sessionKills += 1
	GameEvents.eventLogged.emit(
		"%s defeated! +%d gold" % [
			main.game_data.currentMonsterName,
			gold,
		], "loot", false
	)
	var drops = MonsterRegistry.rollDrops(monster)
	for drop in drops:
		GameEvents.eventLogged.emit("Looted: %s." % drop, "loot", false)
		GameEvents.itemDropped.emit(drop)
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

func isBattlePotionActive() -> bool:
	return battlePotionEventsLeft > 0

func onAreaExited() -> void:
	battlePotionEventsLeft = 0

func onPlayerDied() -> void:
	battlePotionEventsLeft = 0
