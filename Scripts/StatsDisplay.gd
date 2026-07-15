extends Control
class_name StatsDisplay

var main:MainNode
@export var hpValue: Label
@export var xpValue: Label
@export var lvValue: Label
@export var hpBar: ProgressBar
@export var xpBar: ProgressBar
@export var goldLabel: Label
@export var goldValue: Label
@export var areaValue: Label
@export var eventValue: Label

func _ready() -> void:
	main = Utils.get_main()
	GameEvents.eventLogged.connect(onEventLogged)
	GameEvents.areaEntered.connect(onAreaEntered)
	GameEvents.areaExited.connect(onAreaExited)
	GameEvents.playerDied.connect(onPlayerDied)
	GameEvents.goldDeposited.connect(onGoldDeposited)
	GameEvents.hpChanged.connect(updateHp)
	
	refresh()
	goldLabel.text = "Saved Gold"
	goldValue.text = str(main.game_data.savedGold)

func onPlayerDied() -> void:
	var gd = main.game_data
	@warning_ignore("integer_division")
	main.game_data.hp = int(main.game_data.maxHp * .2)
	hpValue.text = "%d / %d" % [gd.hp, gd.maxHp]
	hpBar.max_value = gd.maxHp
	hpBar.value = gd.hp

func refresh() -> void:
	var gd = main.game_data

	# HP
	updateHp()

	# XP
	var xpNeeded = xpForNextLevel()
	lvValue.text = "Lvl: %d" % gd.level
	xpValue.text = "%d / %d" % [gd.xp, xpNeeded]
	xpBar.max_value = xpNeeded
	xpBar.value = gd.xp
	
	# Gold — show carried gold in area, saved gold in town
	if gd.inArea:
		goldLabel.text = "Gold"
		goldValue.text = str(gd.gold)
	else:
		goldLabel.text = "Saved Gold"
		goldValue.text = str(gd.savedGold)

	# Area
	areaValue.text = gd.currentArea if gd.inArea else "Town"
	eventValue.text = "Event #%d" % gd.eventCount

func updateHp() -> void:
	var gd = main.game_data
	hpValue.text = "%d / %d" % [gd.hp, gd.maxHp]
	hpBar.max_value = gd.maxHp
	hpBar.value = gd.hp
	var hpPct = float(gd.hp) / float(gd.maxHp)
	if hpPct > 0.6:
		hpValue.modulate = Color("#27ae60")
		hpBar.modulate = Color("#27ae60")
	elif hpPct > 0.3:
		hpValue.modulate = Color("#c8880a")
		hpBar.modulate = Color("#c8880a")
	else:
		hpValue.modulate = Color("#e74c3c")
		hpBar.modulate = Color("#e74c3c")

func onEventLogged(_text: String, _style: String, _track_num: bool) -> void:
	# Refresh stats on every event tick
	refresh()

func onAreaEntered(areaName: String) -> void:
	areaValue.text = areaName
	eventValue.text = "Event #0"
	goldLabel.text = "Looted Gold"
	goldValue.text = str(0)

func onAreaExited() -> void:
	areaValue.text = "Town"
	eventValue.text = ""
	goldLabel.text = "Saved Gold"
	goldValue.text = str(main.game_data.savedGold)

func onGoldDeposited(_amount: int) -> void:
	goldValue.text = str(main.game_data.gold)

func xpForNextLevel() -> int:
	return main.game_data.level * 70 + (main.game_data.level - 1) * 35
