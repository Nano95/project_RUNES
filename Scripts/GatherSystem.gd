extends Node
class_name GatherSystem

const ORE_ITEMS = ["Copper Ore", "Iron Ore", "Coal", "Tin Ore"]
const WOOD_ITEMS = ["Oak Log", "Pine Wood", "Dark Timber"]
const FORAGE_ITEMS = ["Wild Herb", "Red Berry", "Bloodroot", "Gloomcap"]
const POISONOUS_CHANCE: float = 0.15

var main:MainNode
func _ready() -> void:
	main = Utils.get_main()
	GameEvents.gatherCompleted.connect(onGatherCompleted)

func startOreGather() -> void:
	var item = ORE_ITEMS[randi() % ORE_ITEMS.size()]
	var ticks = randi_range(2, 4)
	GameEvents.eventLogged.emit("You discover an ore vein. Mining %s..." % item, "gather", true)
	GameEvents.gatherStarted.emit(item, ticks)

func startWoodGather() -> void:
	var item = WOOD_ITEMS[randi() % WOOD_ITEMS.size()]
	var ticks = randi_range(2, 3)
	GameEvents.eventLogged.emit("A fallen tree. Gathering %s..." % item, "gather", true)
	GameEvents.gatherStarted.emit(item, ticks)

func startForage() -> void:
	var item = FORAGE_ITEMS[randi() % FORAGE_ITEMS.size()]
	if randf() < POISONOUS_CHANCE:
		var dmg = randi_range(3, 8)
		main.game_data.hp = max(1, main.game_data.hp - dmg)
		main.save_game()
		GameEvents.eventLogged.emit(
			"You eat a %s. It was poisonous! Lost %d HP." % [item, dmg], "combat", true
		)
		GameEvents.combatTick.emit(0, dmg, 0)
	else:
		GameEvents.eventLogged.emit("You forage a %s." % item, "gather", true)
		GameEvents.gatherStarted.emit(item, 1)

func onGatherCompleted(itemName: String) -> void:
	GameEvents.itemDropped.emit(itemName)
