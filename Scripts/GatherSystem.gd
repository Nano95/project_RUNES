extends Node
class_name GatherSystem

const ORE_ITEMS = ["Copper Ore", "Iron Ore", "Coal"]
const WOOD_ITEMS = ["Oak Log", "Pine Wood", "Dark Timber"]
const FORAGE_TABLES: Dictionary = {
	"Hunting Grounds": [
		{ "max": 20,  "drops": [{"name": "Red Berry", "weight": 70}, {"name": "Wild Herb", "weight": 30}] },
		{ "max": 40,  "drops": [{"name": "Red Berry", "weight": 20}, {"name": "Wild Herb", "weight": 55}, {"name": "Bloodroot", "weight": 25}] },
		{ "max": 70,  "drops": [{"name": "Red Berry", "weight": 10}, {"name": "Wild Herb", "weight": 45}, {"name": "Bloodroot", "weight": 45}] },
		{ "max": 9999,"drops": [{"name": "Wild Herb", "weight": 40}, {"name": "Bloodroot", "weight": 60}] },
	],
	"Slime Swamps": [
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
	"Forsaken Keep": [
	{ "max": 20,   "drops": [{"name": "Bloodroot", "weight": 50}, {"name": "Gloomcap", "weight": 30}, {"name": "Deathbloom", "weight": 20}] },
	{ "max": 40,   "drops": [{"name": "Gloomcap", "weight": 20}, {"name": "Deathbloom", "weight": 50}, {"name": "Nightshade", "weight": 30}] },
	{ "max": 70,   "drops": [{"name": "Deathbloom", "weight": 25}, {"name": "Nightshade", "weight": 50}, {"name": "Voidleaf", "weight": 25}] },
	{ "max": 9999, "drops": [{"name": "Deathbloom", "weight": 33}, {"name": "Nightshade", "weight": 33}, {"name": "Voidleaf", "weight": 34}] },
],
}

var foragingPotionEventsLeft: int = 0
var main:MainNode

func _ready() -> void:
	main = Utils.get_main()
	GameEvents.gatherCompleted.connect(onGatherCompleted)
	GameEvents.potionUsed.connect(onPotionUsed)
	GameEvents.areaExited.connect(onAreaExited)
	GameEvents.playerDied.connect(onPlayerDied)

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
	if item == "":
		return
	
	var poisonChance = 0.15  # default
	if (item == "Nightshade"):
		poisonChance = 0.20
	
	if randf() < poisonChance:
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

func onPotionUsed(itemName: String) -> void:
	match itemName:
		"Minor Foraging Potion":
			foragingPotionEventsLeft += 3
			GameEvents.eventLogged.emit(
				"Minor Foraging Potion consumed. Forageables attracted for %d events." % foragingPotionEventsLeft,
				"gather", false
			)
		"Foraging Potion":
			foragingPotionEventsLeft += 6
			GameEvents.eventLogged.emit(
				"Foraging Potion consumed. Forageables attracted for %d events." % foragingPotionEventsLeft,
				"gather", false
			)
		"Great Foraging Potion":
			foragingPotionEventsLeft += 10
			GameEvents.eventLogged.emit(
				"Great Foraging Potion consumed. Forageables attracted for %d events." % foragingPotionEventsLeft,
				"gather", false
			)

func decrementForagingPotion() -> void:
	if foragingPotionEventsLeft <= 0:
		return
	foragingPotionEventsLeft -= 1
	if foragingPotionEventsLeft > 0:
		GameEvents.eventLogged.emit(
			"Foraging potion active — %d events remaining." % foragingPotionEventsLeft,
			"gather", false
		)
	else:
		GameEvents.eventLogged.emit("Foraging potion wore off.", "system", false)

func isForagingPotionActive() -> bool:
	return foragingPotionEventsLeft > 0

func onAreaExited() -> void:
	foragingPotionEventsLeft = 0

func onPlayerDied() -> void:
	foragingPotionEventsLeft = 0
