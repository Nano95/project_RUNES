extends Control
class_name UIController

@export var mainActionRow: ScrollContainer
@export var areaSelectRow: ScrollContainer
@export var chooseAreaButton: Button
@export var brewButton: Button
@export var storageButton: Button
@export var equipmentButton: Button
@export var eventLogButton: Button
@export var merchantButton: Button
@export var blacksmithButton: Button
@export var bazaarButton: Button
@export var expeditionButton: Button
@export var debugButton: Button
@export var areaButtons: Array[Button] = []
@export var eventLogPanel: Panel
@export var equipmentPanel: Panel
@export var expeditionPanel: Panel
@export var quickConfigPanel: Panel
@export var bazaarActionsPanel: Panel
@export var bazaarStartStopBtn: Button

@export var topMainTitlePanel:Panel
@export var expeditionTitlePanel:Panel
@export var mainStatsHBox: HBoxContainer
@export var expeditionHBox: HBoxContainer

@export var bazaarLeaveBtn: Button
@export var bazaarSystem: BazaarSystem
@export var inventorySystem: InventorySystem
@export var storageDisplay: StorageDisplay
@export var alchemyDisplay: BrewDisplay
@export var merchantDisplay: MerchantDisplay
@export var blacksmithDisplay: BlacksmithDisplay
@export var checkPointDisplay: CheckpointOverlay
@export var debugDisplay: DebugDisplay
@export var areaSystem: AreaSystem
@export var adventuringRow: HBoxContainer
@export var inventoryPanel: Panel
@export var autoContinueButton: Button

var main:MainNode

func _ready() -> void:
	main = Utils.get_main()
	GameEvents.areaEntered.connect(onAreaEntered)
	GameEvents.areaExited.connect(onAreaExited)
	GameEvents.playerDied.connect(onAreaExited)
	GameEvents.areaUnlocked.connect(onAreaUnlocked)
	GameEvents.checkpointReached.connect(showCheckpoint)
	autoContinueButton.toggled.connect(emitAutoContinueToggled) # outgoing emit
	GameEvents.autoContinueToggled.connect(onAutoContinueToggled) # incoming emit
	
	bazaarStartStopBtn.pressed.connect(onBazaarStartStopPressed)
	bazaarLeaveBtn.pressed.connect(onBazaarLeavePressed)
	bazaarButton.pressed.connect(onBazaarPressed)
	chooseAreaButton.pressed.connect(onChooseAreaPressed)
	storageButton.pressed.connect(showDisplay)
	brewButton.pressed.connect(showAlchemy)
	equipmentButton.pressed.connect(showEquipment)
	eventLogButton.pressed.connect(showEventPanel)
	merchantButton.pressed.connect(showMerchant)
	blacksmithButton.pressed.connect(showBlacksmith)
	debugButton.pressed.connect(debugDisplay.open)
	expeditionButton.pressed.connect(showExpeditionMode)
	
	mainActionRow.show()
	eventLogPanel.show()
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

func showInventory() -> void:
	inventoryPanel.visible = true

func showDisplay() -> void:
	Utils.animateButtonPress(storageButton)
	storageDisplay.open()

func showAlchemy() -> void:
	Utils.animateButtonPress(brewButton)
	alchemyDisplay.open()

func showEquipment() -> void:
	Utils.animateButtonBounce(equipmentPanel)
	equipmentPanel.show()
	eventLogPanel.hide()

func showEventPanel() -> void:
	Utils.animateButtonBounce(eventLogPanel)
	eventLogPanel.show()
	equipmentPanel.hide()

func showMerchant() -> void:
	Utils.animateButtonPress(merchantButton)
	merchantDisplay.open()

func showBlacksmith() -> void:
	Utils.animateButtonPress(blacksmithButton)
	blacksmithDisplay.open()

func onAreaEntered(_areaName: String) -> void:
	adventuringRow.visible = true
	mainActionRow.visible = false
	areaSelectRow.visible = false
	showEventPanel()
	showInventory()
	call_deferred("resetPanelPositionMeta")
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
	call_deferred("resetPanelPositionMeta")
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

func emitAutoContinueToggled(isToggled:bool=false) -> void:
	GameEvents.autoContinueToggled.emit(isToggled)

func onAutoContinueToggled(isToggled:bool=false) -> void:
	autoContinueButton.button_pressed = isToggled

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
			btn.text = nextLocked.areaName
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

### BAZAAR
func onBazaarPressed() -> void:
	# Show event log in case equipment panel is open
	equipmentPanel.visible = false
	eventLogPanel.visible = true
	Utils.animateButtonBounce(eventLogPanel)
	# Swap bars
	quickConfigPanel.visible = false
	bazaarActionsPanel.visible = true
	
	adventuringRow.visible = true
	mainActionRow.visible = false
	showInventory()
	bazaarStartStopBtn.text = "Start"

func onBazaarLeavePressed() -> void:
	bazaarSystem.stopBazaar()
	Utils.animateButtonBounce(eventLogPanel)
	# Restore normal state
	bazaarActionsPanel.visible = false
	quickConfigPanel.visible = true
	adventuringRow.visible = false
	mainActionRow.visible = true

func onBazaarStartStopPressed() -> void:
	Utils.animateButtonPress(bazaarStartStopBtn)
	if bazaarSystem.isBazaarActive:
		bazaarSystem.stopBazaar()
		bazaarStartStopBtn.text = "Start"
	else:
		bazaarSystem.startBazaar()
		bazaarStartStopBtn.text = "Stop"

func resetPanelPositionMeta() -> void:
	if eventLogPanel.has_meta("originalY"):
		eventLogPanel.remove_meta("originalY")
	if equipmentPanel.has_meta("originalY"):
		equipmentPanel.remove_meta("originalY")


### EXPEDITION
# Show expedition mode
func showExpeditionMode() -> void:
	# Hide normal UI
	mainStatsHBox.visible = false
	mainActionRow.visible = false
	topMainTitlePanel.visible = false
	eventLogPanel.visible = false
	
	# Show expedition UI
	expeditionTitlePanel.visible = true
	expeditionHBox.visible = true
	expeditionPanel.visible = true
	Utils.animateButtonBounce(expeditionPanel)
	
	expeditionPanel.open()

# Return to town
func hideExpeditionMode() -> void:
	# Restore normal UI
	mainStatsHBox.visible = true
	mainActionRow.visible = true
	topMainTitlePanel.visible = true
	eventLogPanel.visible = true
	Utils.animateButtonBounce(eventLogPanel)
	
	# Hide expedition UI
	expeditionTitlePanel.visible = false
	expeditionHBox.visible = false
	expeditionPanel.visible = false
