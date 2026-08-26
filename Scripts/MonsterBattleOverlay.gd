extends ColorRect
class_name CombatOverlay

@export var enemyNameLabel: RichTextLabel
@export var enemyHPBar: ProgressBar
@export var enemyHPValue: Label
@export var fleeButton: Button
@export var eventLogPanel: Panel
@export var equipmentPanel: Panel

var main:MainNode
var monsterMaxHp: int = 0
var hpTween: Tween

func _ready() -> void:
	main = Utils.get_main()
	GameEvents.combatStarted.connect(onCombatStarted)
	GameEvents.combatTick.connect(onCombatTick)
	GameEvents.combatWon.connect(onCombatEnded)
	GameEvents.combatFled.connect(onCombatEnded)
	GameEvents.playerDied.connect(onCombatEnded)
	fleeButton.pressed.connect(onFleePressed)
	hide()

func onCombatStarted(monster: MonsterData, weakened: bool) -> void:
	# dont show if we end the battle in one hit
	if (main.game_data.currentMonsterHp <= 0):
		return
	var currHp = int(monster.hp * .5) if (weakened) else monster.hp
	monsterMaxHp = monster.hp

	var tierColor = ""
	match monster.tier:
		"weak":   tierColor = "#90ee90"  # light green
		"medium": tierColor = "#f1c40f"  # yellow
		"strong": tierColor = "#e74c3c"  # red
		"elite":  tierColor = "#9b59b6"  # purple for elite
		_:        tierColor = "#ffffff"

	enemyNameLabel.text = "%s [color=%s][%s][/color]" % [
		monster.monsterName,
		tierColor,
		monster.tier.to_upper()
	]
	enemyHPBar.max_value = monsterMaxHp
	enemyHPBar.value = currHp
	enemyHPValue.text = "%d / %d" % [currHp, monsterMaxHp]
	updateHPColor(currHp)
	fleeButton.disabled = false
	fleeButton.text = "Flee"
	
	if (eventLogPanel.visible):
		global_position.y = eventLogPanel.global_position.y
	elif (equipmentPanel.visible):
		global_position.y = equipmentPanel.global_position.y
	
	Utils.animate_modal_entry(self)

func onCombatTick(_playerDmg: int, _monsterDmg: int, monsterHpLeft: int) -> void:
	var hpLeft = max(0, monsterHpLeft)
	enemyHPValue.text = "%d / %d" % [hpLeft, monsterMaxHp]
	updateHPColor(hpLeft)
	# Animate the bar
	enemyHPBar.max_value = monsterMaxHp
	if hpTween:
		hpTween.kill()
	hpTween = create_tween()
	hpTween.tween_property(enemyHPBar, "value", monsterHpLeft, 0.25).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	# Update flee button if currently fleeing
	if main.game_data.isFleeing:
		fleeButton.disabled = true
		fleeButton.text = "Fleeing... (%d)" % main.game_data.fleeTicks

func onFleePressed() -> void:
	if main.game_data.isFleeing:
		return
	GameEvents.fleeRequested.emit()
	fleeButton.disabled = true
	fleeButton.text = "Fleeing... (3)"

func onCombatEnded(_a = null) -> void:
	Utils.animate_modal_exit(self)
	monsterMaxHp = 0

func updateHPColor(hpLeft: int) -> void:
	if monsterMaxHp == 0:
		return
	var pct = float(hpLeft) / float(monsterMaxHp)
	if pct > 0.6:
		enemyHPBar.modulate = Color("#27ae60")
	elif pct > 0.3:
		enemyHPBar.modulate = Color("#c8880a")
	else:
		enemyHPBar.modulate = Color("#e74c3c")
