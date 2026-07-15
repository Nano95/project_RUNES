extends Control
class_name UIController

@export var mainActionRow: HBoxContainer
@export var areaSelectRow: GridContainer
@export var chooseAreaButton: Button
@export var brewButton: Button
@export var storageButton: Button
@export var areaButtons: Array[Button] = []
@export var inventorySystem: InventorySystem
@export var storageDisplay: StorageDisplay
@export var areaSystem: AreaSystem
@export var adventuringRow: HBoxContainer
@export var inventoryPanel: Panel
@export var continueButton: Button
@export var retreatButton: Button

func _ready() -> void:
	GameEvents.areaEntered.connect(onAreaEntered)
	GameEvents.areaExited.connect(onAreaExited)
	GameEvents.playerDied.connect(onAreaExited)
	GameEvents.areaUnlocked.connect(onAreaUnlocked)
	GameEvents.checkpointReached.connect(showCheckpoint)
	chooseAreaButton.pressed.connect(onChooseAreaPressed)
	continueButton.pressed.connect(onContinuePressed)
	retreatButton.pressed.connect(onRetreatPressed)
	storageButton.pressed.connect(showDisplay)
	
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
	var main = Utils.get_main()
	var areaName = main.game_data.unlockedAreas[idx]
	areaSelectRow.visible = false
	mainActionRow.visible = true
	areaSystem.enterArea(areaName)

func onAreaUnlocked(areaName: String) -> void:
	refreshAreaGrid()
	GameEvents.eventLogged.emit("A new area is now accessible: " + areaName + ".", "discover", false)

# Call me when areaGrid becomes visible
func refreshAreaGrid() -> void:
	var main = Utils.get_main()
	var unlocked = main.game_data.unlockedAreas
	var nextLocked = AreaRegistry.getNextLockedArea()

	for i in areaButtons.size():
		var btn = areaButtons[i]
		if (i < unlocked.size()):
			# Unlocked area
			btn.visible = true
			btn.text = unlocked[i]
			btn.disabled = false
			btn.modulate = Color(1, 1, 1, 1)
		elif nextLocked != null and i == unlocked.size():
			# Next locked area — visible but disabled
			btn.visible = true
			btn.text = nextLocked.areaName + " 🔒"
			btn.disabled = true
			btn.modulate = Color(1, 1, 1, 0.4)
		else:
			# Hidden
			btn.visible = false
