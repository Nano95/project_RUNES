extends Control
class_name StatsDisplay

var main:MainNode
@export var hpValue: Label
@export var hpBar: ProgressBar
@export var goldLabel: Label
@export var goldValue: Label
@export var areaValue: Label
@export var eventValue: Label
@export var statsLabel: Label
@export var killsLabel: Label
@export var equipmentSystem: EquipmentSystem
var hpTween: Tween
var xpTween: Tween
var pulseTween: Tween
const PULSE_SCALE: Vector2 = Vector2(.33, .33)
const NORMAL_SCALE: Vector2 = Vector2(.3, .3)
var hpLabelOriginalPosition: Vector2

func _ready() -> void:
	main = Utils.get_main()
	hpLabelOriginalPosition = hpValue.position
	GameEvents.eventLogged.connect(onEventLogged)
	GameEvents.areaEntered.connect(onAreaEntered)
	GameEvents.areaExited.connect(onAreaExited)
	GameEvents.playerDied.connect(onPlayerDied)
	GameEvents.goldDeposited.connect(onGoldDeposited)
	GameEvents.hpChanged.connect(updateHp)
	GameEvents.combatWon.connect(updateStats)
	
	call_deferred("refresh")
	goldLabel.text = "Bank"
	goldValue.text = str(main.game_data.savedGold)

func onPlayerDied() -> void:
	var gd = main.game_data
	@warning_ignore("integer_division")
	main.game_data.hp = int(equipmentSystem.getMaxHp() * .2)
	hpValue.text = "%d / %d" % [gd.hp, gd.maxHp]
	hpBar.max_value = gd.maxHp
	hpBar.value = gd.hp

func refresh() -> void:
	var gd = main.game_data

	#  HP and XP
	updateHp()
	updateStats()
	
	# Gold — show carried gold in area, saved gold in town
	if (gd.inArea):
		goldLabel.text = "Gold"
		goldValue.text = str(gd.gold)
	else:
		goldLabel.text = "Bank"
		goldValue.text = str(gd.savedGold)

	# Area
	areaValue.text = gd.currentArea if gd.inArea else "Town"
	eventValue.text = "Event #%d" % gd.eventCount

func updateHp() -> void:
	var gd = main.game_data
	var maxHp = equipmentSystem.getMaxHp()
	hpValue.text = "%d / %d" % [gd.hp, maxHp]
	hpBar.max_value = maxHp
	#hpBar.value = gd.hp
	var hpPct = float(gd.hp) / float(maxHp) # percentage
	if hpPct > 0.6:
		hpValue.modulate = Color("#27ae60")
		hpBar.modulate = Color("#27ae60")
	elif hpPct > 0.3:
		hpValue.modulate = Color("#c8880a")
		hpBar.modulate = Color("#c8880a")
	else:
		hpValue.modulate = Color("#e74c3c")
		hpBar.modulate = Color("#e74c3c")
	# Animate the bar
	hpBar.max_value = maxHp
	if hpTween:
		hpTween.kill()
	hpTween = create_tween()
	hpTween.tween_property(hpBar, "value", gd.hp, 0.35).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	# Pulse the label on every HP change
	#pulseHpLabel()

func updateStats() -> void:
	var atk = equipmentSystem.getTotalAttack()
	var def = equipmentSystem.getTotalDefense()
	var dodge = equipmentSystem.getDodgeChance()
	statsLabel.text = "%d | %d | %d%%" % [atk, def, int(dodge * 100)]
	killsLabel.text = "Kills: %d" % main.game_data.sessionKills

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
	goldLabel.text = "Bank"
	goldValue.text = str(main.game_data.savedGold)

func onGoldDeposited(_amount: int) -> void:
	goldValue.text = str(main.game_data.gold)

func pulseHpLabel() -> void:
	if pulseTween:
		pulseTween.kill()
	hpValue.scale = NORMAL_SCALE
	pulseTween = create_tween()
	pulseTween.tween_property(hpValue, "scale", PULSE_SCALE, 0.12) \
		.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	pulseTween.tween_property(hpValue, "scale", NORMAL_SCALE, 0.20) \
		.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
