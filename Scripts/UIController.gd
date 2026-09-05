extends Control
class_name UIController

@export var mainActionRow: ScrollContainer
@export var chooseAreaButton: Button
@export var brewButton: Button
@export var storageButton: Button
@export var equipmentButton: Button
@export var eventLogButton: Button
@export var merchantButton: Button
@export var blacksmithButton: Button
@export var bazaarButton: Button
@export var expeditionButton: Button
@export var castleButton: Button
@export var debugButton: Button
@export var areaButtons: Array[Button] = []
@export var eventLogPanel: Panel
@export var equipmentPanel: Panel
@export var expeditionPanel: Panel
@export var quickConfigPanel: Panel
@export var bazaarActionsPanel: Panel
@export var bazaarStartStopBtn: Button
@export var goToStage:Button

@export var areaNavPanel: Panel
@export var areaNavFlow: HFlowContainer
@export var areaDisplay: AreaDisplay

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
@export var castleDisplay: CastleDisplay
@export var checkPointDisplay: CheckpointOverlay
@export var debugDisplay: DebugDisplay
@export var areaSystem: AreaSystem
@export var adventuringRow: HBoxContainer
@export var inventoryPanel: Panel
@export var autoContinueButton: Button

var main:MainNode
var selectedArea: String = "Hunting Grounds"

func _ready() -> void:
	main = Utils.get_main()
	GameEvents.areaEntered.connect(onAreaEntered)
	GameEvents.areaExited.connect(onAreaExited)
	GameEvents.playerDied.connect(onAreaExited)
	GameEvents.areaUnlocked.connect(onAreaUnlocked)
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
	castleButton.pressed.connect(showCastle)
	blacksmithButton.pressed.connect(showBlacksmith)
	debugButton.pressed.connect(debugDisplay.open)
	expeditionButton.pressed.connect(showExpeditionMode)
	goToStage.pressed.connect(onGoPressed)
	
	mainActionRow.show()
	eventLogPanel.show()
	areaNavPanel.hide()
	adventuringRow.hide()
	
	
	if (main.game_data.inArea):
		onAreaEntered("")
	else: showSafeZone()

func updateCastleBtn() -> void:
	castleButton.visible = main.game_data.totalAllocationPoints > 0

func showSafeZone() -> void:
	chooseAreaButton.visible = true
	mainActionRow.show()
	areaNavPanel.hide()
	adventuringRow.hide()
	updateCastleBtn()

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

func showCastle() -> void:
	Utils.animateButtonPress(castleButton)
	castleDisplay.open()

func onAreaEntered(_areaName: String) -> void:
	adventuringRow.visible = true
	mainActionRow.visible = false
	areaNavPanel.visible = false
	showEventPanel()
	showInventory()
	call_deferred("resetPanelPositionMeta")

func onContinuePressed() -> void:
	GameEvents.eventLogged.emit("You press deeper...", "system", false)
	GameEvents.checkpointContinued.emit()

func onRetreatPressed() -> void:
	areaSystem.exitArea()

func onAreaExited() -> void:
	call_deferred("resetPanelPositionMeta")
	showSafeZone()

func onAreaUnlocked(areaName: String) -> void:
	refreshAreaGrid()
	GameEvents.eventLogged.emit("A new area is now accessible: " + areaName + ".", "discover", false)

func emitAutoContinueToggled(isToggled:bool=false) -> void:
	GameEvents.autoContinueToggled.emit(isToggled)

func onAutoContinueToggled(isToggled:bool=false) -> void:
	autoContinueButton.button_pressed = isToggled

func onChooseAreaPressed() -> void:
	# Hide normal action row
	mainActionRow.visible = false
	areaNavPanel.visible = true
	Utils.animateButtonBounce(areaDisplay)
	
	# Replace event log with stats panel
	eventLogPanel.visible = false
	equipmentPanel.visible = false
	areaDisplay.visible = true
	# Build area buttons
	buildAreaButtons()

func buildAreaButtons() -> void:
	for child in areaNavFlow.get_children():
		child.free()

	var unlocked = main.game_data.unlockedAreas

	# Back button
	var backBtn = Button.new()
	backBtn.text = "       Back       "
	backBtn.pressed.connect(onAreaNavBackPressed)
	backBtn.add_theme_font_size_override("font_size", 22)
	areaNavFlow.add_child(backBtn)

	# Area buttons
	for area in unlocked:
		var btn = Button.new()
		btn.text = " " + area + " "
		btn.mouse_filter = Control.MOUSE_FILTER_PASS
		btn.pressed.connect(onAreaButtonPressed.bind(area))
		btn.add_theme_font_size_override("font_size", 22)
		areaNavFlow.add_child(btn)

	# Next to unlock label
	var nextArea = getNextAreaToUnlock()
	if nextArea != "":
		var lbl = Label.new()
		lbl.text = "Next: %s (equip higher tier Expedition Map)" % nextArea
		lbl.add_theme_color_override("font_color", Color("#888888"))
		lbl.add_theme_font_size_override("font_size", 18)
		areaNavFlow.add_child(lbl)

	# Default to first unlocked area only if no valid selection exists
	if not unlocked.is_empty():
		if selectedArea == "" or not unlocked.has(selectedArea):
			selectedArea = unlocked[0]
		areaDisplay.showArea(selectedArea)
	

# Choose an area and update panel 
func onAreaButtonPressed(area: String) -> void:
	selectedArea = area
	areaDisplay.showArea(area)

func onAreaNavBackPressed() -> void:
	Utils.animateButtonBounce(eventLogPanel)
	areaNavPanel.visible = false
	mainActionRow.visible = true
	eventLogPanel.visible = true
	areaDisplay.visible = false
	updateCastleBtn()

func onGoPressed() -> void:
	if selectedArea == "":
		return
	# Hide area UI
	areaNavPanel.visible = false
	areaDisplay.visible = false
	# Show adventure UI
	eventLogPanel.visible = true
	mainActionRow.visible = false  # replaced by inventory during adventure
	# Enter area
	areaSystem.enterArea(selectedArea)

func getNextAreaToUnlock() -> String:
	var allAreas = AreaRegistry.getAllAreas()
	var unlocked = main.game_data.unlockedAreas
	for area in allAreas:
		if not unlocked.has(area.areaName):
			return area.areaName
	return ""

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
			"%s is locked. Buy the respective map for this area!" % [areaName],
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
	equipmentPanel.visible = false
	
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
