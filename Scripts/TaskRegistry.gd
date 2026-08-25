extends Node

const TASKS: Array[Dictionary] = [
	# Hunting Grounds — Weak (150g)
	{ "id": "hg_orcling_40",     "area": "Hunting Grounds", "monster": "Orcling",      "target": 40, "reward": "gold",   "rewardValue": 150,  "desc": "Kill 40 Orclings" },
	{ "id": "hg_orcgrunt_40",    "area": "Hunting Grounds", "monster": "Orc Grunt",    "target": 40, "reward": "gold",   "rewardValue": 150,  "desc": "Kill 40 Orc Grunts" },
	{ "id": "hg_orcrunt_40",     "area": "Hunting Grounds", "monster": "Orc Runt",     "target": 40, "reward": "gold",   "rewardValue": 150,  "desc": "Kill 40 Orc Runts" },
	# Hunting Grounds — Medium (+2 weight)
	{ "id": "hg_orcwarrior_30",  "area": "Hunting Grounds", "monster": "Orc Warrior",  "target": 30, "reward": "weight", "rewardValue": 2,    "desc": "Kill 30 Orc Warriors" },
	{ "id": "hg_orcbrute_30",    "area": "Hunting Grounds", "monster": "Orc Brute",    "target": 30, "reward": "weight", "rewardValue": 2,    "desc": "Kill 30 Orc Brutes" },
	{ "id": "hg_orcraider_30",   "area": "Hunting Grounds", "monster": "Orc Raider",   "target": 30, "reward": "weight", "rewardValue": 2,    "desc": "Kill 30 Orc Raiders" },
	# Hunting Grounds — Hard (+2 HP)
	{ "id": "hg_mountedorc_20",  "area": "Hunting Grounds", "monster": "Mounted Orc",  "target": 20, "reward": "hp",     "rewardValue": 2,    "desc": "Kill 20 Mounted Orcs" },
	{ "id": "hg_orcgeneral_20",  "area": "Hunting Grounds", "monster": "Orc General",  "target": 20, "reward": "hp",     "rewardValue": 2,    "desc": "Kill 20 Orc Generals" },
	{ "id": "hg_orcwarlord_20",  "area": "Hunting Grounds", "monster": "Orc Warlord",  "target": 20, "reward": "hp",     "rewardValue": 2,    "desc": "Kill 20 Orc Warlords" },
	{ "id": "hg_orcking_1", "area": "Hunting Grounds", "monster": "Orc King", "target": 1, "reward": "allocation", "rewardValue": 1, "desc": "Defeat the Orc King" },
	
	# Hunting Grounds — Milestone
	{ "id": "hg_100events",      "area": "Hunting Grounds", "monster": "",             "target": 100, "reward": "allocation", "rewardValue": 3, "desc": "Reach Event 100 in Hunting Grounds" },
]
var main:MainNode
func _ready() -> void:
	main = Utils.get_main()

func getTasksForArea(area: String) -> Array[Dictionary]:
	return TASKS.filter(func(t): return t["area"] == area)

func getTask(id: String) -> Dictionary:
	for task in TASKS:
		if task["id"] == id:
			return task
	return {}

func getProgress(task: Dictionary) -> int:
	if (!main): main = Utils.get_main()
	if task["monster"] == "":
		# Event milestone
		return main.game_data.areaStats.get(task["area"], {}).get("bestRun", 0)
	return main.game_data.stats.get("kills", {}).get(task["monster"], 0)

func isCompleted(task: Dictionary) -> bool:
	return getProgress(task) >= task["target"]

func isClaimed(task: Dictionary) -> bool:
	return Utils.get_main().game_data.claimedTasks.has(task["id"])

func claimReward(task: Dictionary) -> void:
	if (!main): main = Utils.get_main()
	if isClaimed(task) or not isCompleted(task):
		return
	match task["reward"]:
		"gold":
			main.game_data.savedGold += task["rewardValue"]
			GameEvents.goldDeposited.emit(task["rewardValue"])
			GameEvents.eventLogged.emit(
				"Task complete! +%dg" % task["rewardValue"], "town", false
			)
		"weight":
			main.game_data.maxWeight += task["rewardValue"]
			GameEvents.eventLogged.emit(
				"Task complete! +%d max weight" % task["rewardValue"], "town", false
			)
		"hp":
			main.game_data.baseHp += task["rewardValue"]
			GameEvents.equipmentChanged.emit()  # recalculate maxHp
			GameEvents.eventLogged.emit(
				"Task complete! +%d base HP" % task["rewardValue"], "town", false
			)
		"allocation":
			main.game_data.availableAllocationPoints += task["rewardValue"]
			GameEvents.eventLogged.emit(
				"Task complete! +%d allocation points" % task["rewardValue"], "town", false
			)
	main.game_data.claimedTasks.append(task["id"])
	main.save_game()
