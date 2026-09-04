extends ColorRect
class_name CastleDisplay

@export var availablePointsLabel: Label
@export var atkLabel: Label
@export var defLabel: Label
@export var hpLabel: Label
@export var weightLabel: Label
@export var dodgeLabel: Label
@export var townRegenLabel: Label
@export var checkPointLabel: Label
@export var atkAddBtn: Button
@export var defAddBtn: Button
@export var hpAddBtn: Button
@export var weightAddBtn: Button
@export var dodgeAddBtn: Button
@export var TownRegenAddBtn: Button
@export var checkpointRegenAddBtn: Button
@export var resetBtn: Button
@export var closeBtn: Button
@export var equipmentSystem: EquipmentSystem

const RESET_COST = 100

var main:MainNode = null

func _ready() -> void:
	main = Utils.get_main()
	atkAddBtn.pressed.connect(func(): onAllocate("atk"))
	defAddBtn.pressed.connect(func(): onAllocate("def"))
	hpAddBtn.pressed.connect(func(): onAllocate("hp"))
	weightAddBtn.pressed.connect(func(): onAllocate("weight"))
	dodgeAddBtn.pressed.connect(func(): onAllocate("dodge"))
	resetBtn.pressed.connect(onReset)
	closeBtn.pressed.connect(onClose)
	hide()

func open() -> void:
	refresh()
	Utils.animate_modal_entry(self)

func onClose() -> void:
	Utils.animate_modal_exit(self)
	#Utils.animateButtonPress(closeBtn)

func refresh() -> void:
	var available = main.game_data.totalAllocationPoints - \
					main.game_data.allocatedAtk - \
					main.game_data.allocatedDef - \
					main.game_data.allocatedHp - \
					main.game_data.allocatedWeight - \
					main.game_data.allocatedDodge

	availablePointsLabel.text = "Available Points: %d" % available

	atkLabel.text    = " +%d" % main.game_data.allocatedAtk
	defLabel.text    = " +%d" % main.game_data.allocatedDef
	hpLabel.text     = " +%d" % main.game_data.allocatedHp
	weightLabel.text = " +%d" % [main.game_data.allocatedWeight * 3]
	dodgeLabel.text  = " +%d%%" % main.game_data.allocatedDodge
	townRegenLabel.text = " +%d" % main.game_data.allocatedTownRegen
	checkPointLabel.text = " +%d%%" % [main.game_data.allocatedCheckpointRegen * 2]
	# Disable add buttons if no points available
	var hasPoints = available > 0
	atkAddBtn.disabled    = not hasPoints
	defAddBtn.disabled    = not hasPoints
	hpAddBtn.disabled     = not hasPoints
	weightAddBtn.disabled = not hasPoints
	dodgeAddBtn.disabled  = not hasPoints
	TownRegenAddBtn.disabled  = not hasPoints
	checkpointRegenAddBtn.disabled  = not hasPoints

	# Reset button
	var hasAllocated = main.game_data.allocatedAtk > 0 or \
					   main.game_data.allocatedDef > 0 or \
					   main.game_data.allocatedHp > 0 or \
					   main.game_data.allocatedWeight > 0 or \
					   main.game_data.allocatedDodge > 0 or \
					   main.game_data.allocatedTownRegen > 0 or \
					   main.game_data.allocatedCheckpointRegen > 0
	resetBtn.visible = hasAllocated
	resetBtn.text = "Reset All (%dg)" % RESET_COST

func onAllocate(stat: String) -> void:
	var available = main.game_data.totalAllocationPoints - \
					main.game_data.allocatedAtk - \
					main.game_data.allocatedDef - \
					main.game_data.allocatedHp - \
					main.game_data.allocatedWeight - \
					main.game_data.allocatedDodge - \
					main.game_data.allocatedTownRegen - \
					main.game_data.allocatedCheckpointRegen
	if available <= 0:
		return

	match stat:
		"atk":    main.game_data.allocatedAtk += 1
		"def":    main.game_data.allocatedDef += 1
		"hp":     main.game_data.allocatedHp += 1
		"weight": main.game_data.allocatedWeight += 1
		"dodge":  main.game_data.allocatedDodge += 1
		"townRegen": main.game_data.allocatedTownRegen += 1
		"checkpointRegen": main.game_data.allocatedCheckpointRegen += 1

	main.save_game()
	GameEvents.equipmentChanged.emit()
	GameEvents.eventLogged.emit(
		"Allocated 1 point to %s." % stat.to_upper(), "town", false
	)
	refresh()

func onReset() -> void:
	if main.game_data.savedGold < RESET_COST:
		GameEvents.eventLogged.emit(
			"Not enough gold to reset. Need %dg." % RESET_COST, "system", false
		)
		return

	main.game_data.savedGold -= RESET_COST
	main.game_data.allocatedAtk = 0
	main.game_data.allocatedDef = 0
	main.game_data.allocatedHp = 0
	main.game_data.allocatedWeight = 0
	main.game_data.allocatedDodge = 0
	main.game_data.allocatedTownRegen = 0
	main.game_data.allocatedCheckpointRegen = 0

	main.save_game()
	GameEvents.equipmentChanged.emit()
	GameEvents.goldDeposited.emit(0)
	GameEvents.eventLogged.emit(
		"All allocation points reset for %dg." % RESET_COST, "town", false
	)
	refresh()
