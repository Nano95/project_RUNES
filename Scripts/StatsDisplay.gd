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
	GameEvents.leveledUp.connect(playLevelUpEffect)
	
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

	#  HP and XP
	updateHp()
	updateXp()
	
	# Gold — show carried gold in area, saved gold in town
	if (gd.inArea):
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
	#hpBar.value = gd.hp
	var hpPct = float(gd.hp) / float(gd.maxHp) # percentage
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
	hpBar.max_value = gd.maxHp
	if hpTween:
		hpTween.kill()
	hpTween = create_tween()
	hpTween.tween_property(hpBar, "value", gd.hp, 0.35).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	# Pulse the label on every HP change
	#pulseHpLabel()

func updateXp() -> void:
	var gd = main.game_data
	var xpNeeded = xpForNextLevel()

	# Update text immediately
	lvValue.text = "Lvl: %d" % gd.level
	xpValue.text = "%d / %d" % [gd.xp, xpNeeded]

	# Update bar max in case of level up
	xpBar.max_value = xpNeeded

	# Animate the bar
	if xpTween:
		xpTween.kill()
	xpTween = create_tween()
	xpTween.tween_property(xpBar, "value", gd.xp, 0.35).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)


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

func playLevelUpEffect() -> void:
	var gd = main.game_data
	
	# First animate to full
	if xpTween:
		xpTween.kill()
	xpTween = create_tween()
	xpTween.tween_property(xpBar, "value", xpBar.max_value, 0.20) \
		.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	
	# Then flash the bar white
	xpTween.tween_property(xpBar, "modulate", Color(1, 1, 1, 1), 0.15)
	xpTween.tween_property(xpBar, "modulate", Color("#35d0ff"), 0.15)
	
	# Then reset to zero and animate up to current xp with new max
	xpTween.tween_callback(func():
		xpBar.max_value = xpForNextLevel()
		xpBar.value = 0
		lvValue.text = "Lvl: %d" % gd.level
	)
	xpTween.tween_property(xpBar, "value", gd.xp, 0.35) \
		.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)

func pulseHpLabel() -> void:
	if pulseTween:
		pulseTween.kill()
	hpValue.scale = NORMAL_SCALE
	pulseTween = create_tween()
	pulseTween.tween_property(hpValue, "scale", PULSE_SCALE, 0.12) \
		.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	pulseTween.tween_property(hpValue, "scale", NORMAL_SCALE, 0.20) \
		.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
