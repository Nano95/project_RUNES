extends Node
class_name GatherSystem

const ORE_ITEMS = ["Copper Ore", "Iron Ore", "Coal", "Tin Ore"]
const WOOD_ITEMS = ["Oak Log", "Pine Wood", "Dark Timber"]
const FORAGE_TABLES: Dictionary = {
	"Hunting Grounds": [
		{ "max": 20,  "drops": [{"name": "Red Berry", "weight": 70}, {"name": "Wild Herb", "weight": 30}] },
		{ "max": 40,  "drops": [{"name": "Red Berry", "weight": 20}, {"name": "Wild Herb", "weight": 55}, {"name": "Bloodroot", "weight": 25}] },
		{ "max": 70,  "drops": [{"name": "Red Berry", "weight": 10}, {"name": "Wild Herb", "weight": 45}, {"name": "Bloodroot", "weight": 45}] },
		{ "max": 9999,"drops": [{"name": "Wild Herb", "weight": 40}, {"name": "Bloodroot", "weight": 60}] },
	],
	"Outskirts": [
		{ "max": 20,  "drops": [{"name": "Red Berry", "weight": 30}, {"name": "Wild Herb", "weight": 50}, {"name": "Bloodroot", "weight": 20}] },
		{ "max": 40,  "drops": [{"name": "Red Berry", "weight": 10}, {"name": "Wild Herb", "weight": 55}, {"name": "Bloodroot", "weight": 30}, {"name": "Gloomcap", "weight": 5}] },
		{ "max": 70,  "drops": [{"name": "Red Berry", "weight": 5},  {"name": "Wild Herb", "weight": 40}, {"name": "Bloodroot", "weight": 40}, {"name": "Gloomcap", "weight": 15}] },
		{ "max": 9999,"drops": [{"name": "Wild Herb", "weight": 20}, {"name": "Bloodroot", "weight": 50}, {"name": "Gloomcap", "weight": 30}] },
	],
	"Darkwood Forest": [
		{ "max": 20,  "drops": [{"name": "Wild Herb", "weight": 30}, {"name": "Bloodroot", "weight": 50}, {"name": "Gloomcap", "weight": 20}] },
		{ "max": 40,  "drops": [{"name": "Wild Herb", "weight": 10}, {"name": "Bloodroot", "weight": 55}, {"name": "Gloomcap", "weight": 35}] },
		{ "max": 70,  "drops": [{"name": "Bloodroot", "weight": 50}, {"name": "Gloomcap", "weight": 50}] },
		{ "max": 9999,"drops": [{"name": "Bloodroot", "weight": 20}, {"name": "Gloomcap", "weight": 80}] },
	],
}
const POISONOUS_CHANCE: float = 0.1

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
	var item = rollForageable()
	if (item == ""):
		return
	if (randf() < POISONOUS_CHANCE):
		var dmg = randi_range(3, 8)
		main.game_data.hp = max(1, main.game_data.hp - dmg)
		main.save_game()
		GameEvents.eventLogged.emit(
			"You forage a %s. It was poisonous! Lost %d HP." % [item, dmg], "combat", true
		)
		GameEvents.hpChanged.emit()
	else:
		GameEvents.eventLogged.emit("You forage a %s." % item, "gather", true)
		GameEvents.gatherStarted.emit(item, 1)

func rollForageable() -> String:
	var area = main.game_data.currentArea
	var eventCount = main.game_data.eventCount

	if not FORAGE_TABLES.has(area):
		# Fallback for areas not yet defined
		return ["Wild Herb", "Red Berry", "Bloodroot"][randi() % 3]

	var table = FORAGE_TABLES[area]
	var drops: Array = []

	# Find the right event bracket
	for bracket in table:
		if eventCount <= bracket["max"]:
			drops = bracket["drops"]
			break

	if (drops.is_empty()):
		return ""

	# Weighted random pick
	var totalWeight = 0
	for entry in drops:
		totalWeight += entry["weight"]

	var roll = randi() % totalWeight
	var cumulative = 0
	for entry in drops:
		cumulative += entry["weight"]
		if roll < cumulative:
			return entry["name"]

	return drops[drops.size() - 1]["name"]

func onGatherCompleted(itemName: String) -> void:
	GameEvents.itemDropped.emit(itemName)
