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

var pendingStrongMonster: bool = false
var main:MainNode

func _ready() -> void:
	main = Utils.get_main()
	GameEvents.tickFired.connect(onTick)
	GameEvents.combatStarted.connect(onCombatStarted)
	GameEvents.fleeRequested.connect(onFleeRequested)

func onTick() -> void:
	if not main.game_data.inArea:
		return
	if not main.game_data.inCombat:
		return
	tickCombat()

func startCombat(monster: MonsterData) -> void:
	main.game_data.inCombat = true
	main.game_data.currentMonsterName = monster.monsterName
	main.game_data.currentMonsterTier = monster.tier
	main.game_data.currentMonsterHp = monster.hp
	main.game_data.currentMonsterAtk = monster.atk
	main.game_data.isFleeing = false
	main.game_data.fleeTicks = 0
	GameEvents.combatStarted.emit(monster)

func trySpawnMonster(eventCount: int) -> void:
	var tier = MonsterRegistry.rollTier(eventCount)
	if tier == "strong" and eventCount <= 40:
		pendingStrongMonster = true
		GameEvents.eventLogged.emit(OMENS[randi() % OMENS.size()], "omen")
		return
	if (tier == "elite" and eventCount < 50):
		tier = "strong"
	var monster = MonsterRegistry.rollMonster(main.game_data.currentArea, tier)
	startCombat(monster)

func onCombatStarted(monster: MonsterData) -> void:
	GameEvents.eventLogged.emit(
		"A %s appears! [%s]" % [monster.monsterName, monster.tier.to_upper()],
        "danger"
	)

func tickCombat() -> void:
	var playerAtk = randi_range(5, 12) + int(main.game_data.level * 1.5)
	main.game_data.currentMonsterHp -= playerAtk
	var monsterAtk = randi_range(
		int(main.game_data.currentMonsterAtk * 0.7),
		main.game_data.currentMonsterAtk
	)
	main.game_data.hp = max(0, main.game_data.hp - monsterAtk)

	if main.game_data.isFleeing:
		main.game_data.fleeTicks -= 1
		GameEvents.eventLogged.emit(
			"Fleeing... %s hits for %d dmg. Escaping in %d ticks..." % [
				main.game_data.currentMonsterName,
				monsterAtk,
				main.game_data.fleeTicks
			], "combat"
		)
		if main.game_data.hp <= 0:
			die()
			return
		if main.game_data.fleeTicks <= 0:
			flee()
			return
		GameEvents.combatTick.emit(playerAtk, monsterAtk, main.game_data.currentMonsterHp)
		return

	GameEvents.eventLogged.emit(
		"You hit %s for %d. It strikes back for %d." % [
			main.game_data.currentMonsterName,
			playerAtk,
			monsterAtk
		], "combat"
	)

	if main.game_data.hp <= 0:
		die()
		return

	if main.game_data.currentMonsterHp <= 0:
		winCombat()
		return

	GameEvents.combatTick.emit(playerAtk, monsterAtk, main.game_data.currentMonsterHp)

func winCombat() -> void:
	var monster = MonsterRegistry.rollMonster(
		main.game_data.currentArea,
		main.game_data.currentMonsterTier
	)
	var gold = randi_range(monster.goldMin, monster.goldMax)
	main.game_data.gold += gold
	main.game_data.xp += monster.xp
	GameEvents.eventLogged.emit(
		"%s defeated! +%d gold, +%d XP." % [
			main.game_data.currentMonsterName,
			gold,
			monster.xp
		], "loot"
	)
	var drops = MonsterRegistry.rollDrops(monster)
	for drop in drops:
		GameEvents.eventLogged.emit("Looted: %s." % drop, "loot")
		GameEvents.itemDropped.emit(drop)
	clearCombat()
	GameEvents.combatWon.emit(gold, monster.xp)
	main.save_game()

func flee() -> void:
	GameEvents.eventLogged.emit("You escaped!", "system")
	clearCombat()
	GameEvents.combatFled.emit()

func die() -> void:
	main.game_data.gold = 0
	GameEvents.eventLogged.emit("You have died. Your gold and inventory are lost.", "danger")
	clearCombat()
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
	GameEvents.eventLogged.emit("You attempt to flee...", "system")
