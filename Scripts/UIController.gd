extends Control
class_name UIController

@export var mainActionRow: HBoxContainer
@export var areaSelectRow: GridContainer
@export var chooseAreaButton: Button
@export var brewButton: Button
@export var chestButton: Button
@export var areaButtons: Array[Button] = []
@export var inventorySystem: InventorySystem
@export var areaSystem: AreaSystem

func _ready() -> void:
	GameEvents.areaEntered.connect(onAreaEntered)
	GameEvents.areaExited.connect(onAreaExited)
	GameEvents.areaUnlocked.connect(onAreaUnlocked)
	chooseAreaButton.pressed.connect(onChooseAreaPressed)
	

	for i in areaButtons.size():
		var idx = i
		areaButtons[i].pressed.connect(onAreaButtonPressed.bind(idx))
	
	showSafeZone()

func showSafeZone() -> void:
	chooseAreaButton.text = "Choose Area"
	chooseAreaButton.visible = true

func onAreaEntered(_areaName: String) -> void:
	chooseAreaButton.text = "← Retreat"
	chooseAreaButton.pressed.disconnect(onChooseAreaPressed)
	chooseAreaButton.pressed.connect(onRetreatPressed)

func onRetreatPressed() -> void:
	areaSystem.exitArea()

func onAreaExited() -> void:
	chooseAreaButton.text = "Choose Area"
	chooseAreaButton.pressed.disconnect(onRetreatPressed)
	chooseAreaButton.pressed.connect(onChooseAreaPressed)
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
	GameEvents.eventLogged.emit("A new area is now accessible: " + areaName + ".", "discover")

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
