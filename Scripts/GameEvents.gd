extends Node

@warning_ignore("unused_signal")
signal eventLogged(text: String, style: String, show_number:bool)
@warning_ignore("unused_signal")
signal tickFired
@warning_ignore("unused_signal")
signal areaEntered(areaName: String)
@warning_ignore("unused_signal")
signal areaExited
@warning_ignore("unused_signal")
signal areaUnlocked(areaName: String)
@warning_ignore("unused_signal")
signal goldDeposited(amount: int)
@warning_ignore("unused_signal")
signal checkpointReached
@warning_ignore("unused_signal")
signal checkpointContinued
@warning_ignore("unused_signal")
signal weightChanged
@warning_ignore("unused_signal")
signal itemInspected(itemName: String)
@warning_ignore("unused_signal")
signal potionUsed(itemName: String)
@warning_ignore("unused_signal")
signal itemLongPressed(itemName: String, stackIndex: int)
@warning_ignore("unused_signal")
signal itemEquipped(itemName: String)
@warning_ignore("unused_signal")
signal gatherStarted(itemName: String, ticks: int)
@warning_ignore("unused_signal")
signal gatherTick(itemName: String, ticksLeft: int)
@warning_ignore("unused_signal")
signal gatherCompleted(itemName: String)
@warning_ignore("unused_signal")
signal chestUnlocked(chestId: int)
@warning_ignore("unused_signal")
signal chestUpgraded(chestId: int)
@warning_ignore("unused_signal")
signal chestItemMoved(chestId: int)
@warning_ignore("unused_signal")
signal chestChanged
@warning_ignore("unused_signal")
signal backpackChanged
@warning_ignore("unused_signal")
signal equipmentChanged
@warning_ignore("unused_signal")
signal cannotEquipError(error: String)

@warning_ignore("unused_signal")
signal hpChanged
@warning_ignore("unused_signal")
signal poisonApplied(dmgPerTick: int)
@warning_ignore("unused_signal")
signal stunApplied
@warning_ignore("unused_signal")
signal lifeStealApplied(pct: int)

@warning_ignore("unused_signal")
signal recipeDiscovered(recipeName: String)
@warning_ignore("unused_signal")
signal brewAttempted(success: bool, resultItem: String)
@warning_ignore("unused_signal")
signal timePotionUsed
@warning_ignore("unused_signal")
signal autoContinueToggled(enabled: bool)

### COMBAT
@warning_ignore("unused_signal")
signal combatStarted(monster: MonsterData, weakened: bool)
@warning_ignore("unused_signal")
signal combatTick(playerDmg: int, monsterDmg: int, monsterHpLeft: int)
@warning_ignore("unused_signal")
signal combatWon(gold: int)
@warning_ignore("unused_signal")
signal combatFled
@warning_ignore("unused_signal")
signal playerDied
@warning_ignore("unused_signal")
signal fleeRequested
@warning_ignore("unused_signal")
signal itemDropped(itemName: String)
@warning_ignore("unused_signal")
signal statusEffectApplied(status: String, counter: int)
@warning_ignore("unused_signal")
signal statusEffectTicked(status: String, counter: int, damage: int)
@warning_ignore("unused_signal")
signal statusEffectCleared(status: String)
