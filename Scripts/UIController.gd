extends Control
class_name UIController

@export var mainActionRow: HBoxContainer
@export var areaSelectRow: GridContainer
@export var chooseAreaButton: Button
@export var brewButton: Button
@export var storageButton: Button
@export var armoryButton: Button
@export var areaButtons: Array[Button] = []
@export var inventorySystem: InventorySystem
@export var storageDisplay: StorageDisplay
@export var alchemyDisplay: BrewDisplay
@export var equipmentDisplay:EquipmentDisplay
@export var areaSystem: AreaSystem
@export var adventuringRow: HBoxContainer
@export var inventoryPanel: Panel
@export var continueButton: Button
@export var retreatButton: Button

var main:MainNode

func _ready() -> void:
	main = Utils.get_main()
	GameEvents.areaEntered.connect(onAreaEntered)
	GameEvents.areaExited.connect(onAreaExited)
	GameEvents.playerDied.connect(onAreaExited)
	GameEvents.areaUnlocked.connect(onAreaUnlocked)
	GameEvents.checkpointReached.connect(showCheckpoint)
	chooseAreaButton.pressed.connect(onChooseAreaPressed)
	continueButton.pressed.connect(onContinuePressed)
	retreatButton.pressed.connect(onRetreatPressed)
	storageButton.pressed.connect(showDisplay)
	brewButton.pressed.connect(showAlchemy)
	armoryButton.pressed.connect(showArmory)
	
	mainActionRow.show()
	areaSelectRow.hide()
	adventuringRow.hide()
	
	for i in areaButtons.size():
		var idx = i
		areaButtons[i].pressed.connect(onAreaButtonPressed.bind(idx))
	
	showSafeZone()

func showSafeZone() -> void:
	chooseAreaButton.text = "Choose Area"
	chooseAreaButton.visible = true
	mainActionRow.show()
	areaSelectRow.hide()
	adventuringRow.hide()

func showCheckpoint() -> void:
	mainActionRow.hide()
	areaSelectRow.hide()
	adventuringRow.show()
	inventoryPanel.visible = false
	continueButton.visible = true
	retreatButton.visible = true

func showInventory() -> void:
	inventoryPanel.visible = true
	continueButton.visible = false
	retreatButton.visible = false

func showDisplay() -> void:
	storageDisplay.open()

func showAlchemy() -> void:
	alchemyDisplay.open()

func showArmory() -> void:
	equipmentDisplay.open()

func onAreaEntered(_areaName: String) -> void:
	adventuringRow.visible = true
	mainActionRow.visible = false
	areaSelectRow.visible = false
	showInventory()
	#chooseAreaButton.text = "← Retreat"
	#chooseAreaButton.pressed.disconnect(onChooseAreaPressed)
	#chooseAreaButton.pressed.connect(onRetreatPressed)

func onContinuePressed() -> void:
	showInventory()
	GameEvents.eventLogged.emit("You press deeper...", "system", false)
	GameEvents.checkpointContinued.emit()

func onRetreatPressed() -> void:
	areaSystem.exitArea()

func onAreaExited() -> void:
	chooseAreaButton.text = "Choose Area"
	showSafeZone()

func onChooseAreaPressed() -> void:
	refreshAreaGrid()
	mainActionRow.visible = false
	areaSelectRow.visible = true

func onAreaButtonPressed(idx: int) -> void:
	var areaName = main.game_data.unlockedAreas[idx]
	areaSelectRow.visible = false
	mainActionRow.visible = true
	areaSystem.enterArea(areaName)

func onAreaUnlocked(areaName: String) -> void:
	refreshAreaGrid()
	GameEvents.eventLogged.emit("A new area is now accessible: " + areaName + ".", "discover", false)

func refreshAreaGrid() -> void:
	var unlocked = main.game_data.unlockedAreas
	var nextLocked = AreaRegistry.getNextLockedArea()

	for i in areaButtons.size():
		var btn = areaButtons[i]

		if i < unlocked.size():
			# Unlocked area
			btn.visible = true
			btn.text = unlocked[i]
			btn.disabled = false
			btn.modulate = Color(1, 1, 1, 1)
			# Clear previous connections to avoid duplicates
			if btn.pressed.is_connected(onAreaButtonPressed):
				btn.pressed.disconnect(onAreaButtonPressed)
			if btn.pressed.is_connected(onLockedAreaPressed):
				btn.pressed.disconnect(onLockedAreaPressed)
			btn.pressed.connect(onAreaButtonPressed.bind(i))

		elif nextLocked != null and i == unlocked.size():
			# Next locked area — visible but disabled looking, still tappable
			btn.visible = true
			btn.text = nextLocked.areaName + " 🔒"
			btn.disabled = false
			btn.modulate = Color(1, 1, 1, 0.8)
			if btn.pressed.is_connected(onAreaButtonPressed):
				btn.pressed.disconnect(onAreaButtonPressed)
			if btn.pressed.is_connected(onLockedAreaPressed):
				btn.pressed.disconnect(onLockedAreaPressed)
			btn.pressed.connect(onLockedAreaPressed.bind(nextLocked.areaName))

		else:
			# Hidden
			btn.visible = false

func onLockedAreaPressed(areaName: String) -> void:
	var previousArea = ""
	for i in AreaRegistry.areas.size():
		if AreaRegistry.areas[i].areaName == areaName and i > 0:
			previousArea = AreaRegistry.areas[i - 1].areaName
			break
	if previousArea != "":
		GameEvents.eventLogged.emit(
			"%s is locked. Reach event #100 in %s to unlock it." % [areaName, previousArea],
			"system", false
		)
