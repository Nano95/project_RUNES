extends Node

@warning_ignore("unused_signal")
signal eventLogged(text: String, style: String)
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
signal inventoryChanged
@warning_ignore("unused_signal")
signal chestChanged

### COMBAT
@warning_ignore("unused_signal")
signal combatStarted(monster: MonsterData)
@warning_ignore("unused_signal")
signal combatTick(playerDmg: int, monsterDmg: int, monsterHpLeft: int)
@warning_ignore("unused_signal")
signal combatWon(xp: int, gold: int)
@warning_ignore("unused_signal")
signal combatFled
@warning_ignore("unused_signal")
signal playerDied
@warning_ignore("unused_signal")
signal fleeRequested
@warning_ignore("unused_signal")
signal itemDropped(itemName: String)
