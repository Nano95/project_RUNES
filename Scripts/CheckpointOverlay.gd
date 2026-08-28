extends ColorRect
class_name CheckpointOverlay

@export var descLabel: RichTextLabel
@export var continueButton: Button
@export var retreatButton: Button
@export var autoCheckbox: CheckButton

@export var autoProgress: ProgressBar
@export var autoTimer: Timer

@export var eventLogPanel: Panel
@export var equipmentPanel: Panel
@export var areaSystem: AreaSystem

@export var pendingLootPanel: ColorRect
@export var pendingLootFlow: HFlowContainer
@export var inventorySystem: InventorySystem

const AUTO_DURATION: float = 2.0

const CHECKPOINT_MESSAGES = [
	"Push your [shake rate=15 level=3]luck[/shake], or [wave amp=10 freq=2]live[/wave] to fight another day.",
	"The world holds its [shake rate=10 level=2]breath[/shake].",
	"How [wave amp=8 freq=3]far[/wave] is far enough?",
	"[shake rate=20 level=5]Danger[/shake] grows with every step forward.",
	"Your loot is [color=#27ae60]safe[/color] in town. Your [shake rate=25 level=6]life[/shake] is not.",
]

var main:MainNode

func _ready() -> void:
	main = Utils.get_main()
	GameEvents.checkpointReached.connect(onCheckpointReached)
	continueButton.pressed.connect(onContinuePressed)
	retreatButton.pressed.connect(onRetreatPressed)
	autoCheckbox.toggled.connect(onAutoToggled)
	# toggled from eventPanel quick settings
	GameEvents.autoContinueToggled.connect(onAutoContinueToggled)
	autoTimer.wait_time = AUTO_DURATION
	autoTimer.one_shot = true
	autoTimer.timeout.connect(onAutoTimerTimeout)
	autoProgress.min_value = 0.0
	autoProgress.max_value = AUTO_DURATION
	autoProgress.value = 0.0
	autoProgress.visible = false
	set_process(false)
	hide()

func _process(_delta: float) -> void:
	if not autoTimer.is_stopped():
		autoProgress.value = AUTO_DURATION - autoTimer.time_left
	else:
		set_process(false)

func onOpen() -> void:
	if (eventLogPanel.visible):
		global_position.y = eventLogPanel.global_position.y
	elif (equipmentPanel.visible):
		global_position.y = equipmentPanel.global_position.y
	
	Utils.animate_modal_entry(self)
	show()
	refreshPendingLoot()

func onHide() -> void:
	Utils.animate_modal_exit(self)
	hide()

func onAutoContinueToggled(toggled:bool = true) -> void:
	autoCheckbox.set_pressed_no_signal(toggled)

func onCheckpointReached() -> void:
	descLabel.bbcode_enabled = true
	descLabel.text = CHECKPOINT_MESSAGES[randi() % CHECKPOINT_MESSAGES.size()]
	autoProgress.value = 0.0
	# Start timer automatically if checkbox is checked
	if autoCheckbox.button_pressed:
		startAutoTimer()
	onOpen()

func onContinuePressed() -> void:
	Utils.animateButtonPress(continueButton)
	stopAutoTimer()
	clearPendingLoot()
	onHide()
	GameEvents.checkpointContinued.emit()
	GameEvents.eventLogged.emit("You press deeper...", "system", false)

func onRetreatPressed() -> void:
	Utils.animateButtonPress(retreatButton)
	stopAutoTimer()
	clearPendingLoot()
	onHide()
	areaSystem.exitArea()

func onAutoToggled(pressed: bool) -> void:
	GameEvents.autoContinueToggled.emit(pressed)
	if (pressed):
		startAutoTimer()
	else:
		stopAutoTimer()

func startAutoTimer() -> void:
	autoProgress.max_value = AUTO_DURATION
	autoProgress.value = 0.0
	autoProgress.visible = true
	autoTimer.start(AUTO_DURATION)
	set_process(true)

func stopAutoTimer() -> void:
	autoTimer.stop()
	autoProgress.value = 0.0
	autoProgress.visible = false
	set_process(false)

func onAutoTimerTimeout() -> void:
	autoProgress.visible = false
	onContinuePressed()

func refreshPendingLoot() -> void:
	pendingLootPanel.visible = not main.game_data.pendingLoot.is_empty()
	
	for child in pendingLootFlow.get_children():
		child.queue_free()
	
	for stack in main.game_data.pendingLoot:
		var btn = Button.new()
		var itemName = stack.get("name", "")
		var qty = stack.get("qty", 1)
		btn.text = "%s x%d" % [itemName, qty] if qty > 1 else itemName
		btn.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
		var item = ItemRegistry.getItem(itemName)
		if item:
			match item.itemType:
				"equipment": btn.add_theme_color_override("font_color", Color("#e74c3c"))
				"potion":    btn.add_theme_color_override("font_color", Color("#8e44ad"))
				"part":      btn.add_theme_color_override("font_color", Color("#c8880a"))
				"forageable":btn.add_theme_color_override("font_color", Color("#27ae60"))
				_:           btn.add_theme_color_override("font_color", Color("#ffffff"))
		btn.pressed.connect(onPendingItemPressed.bind(stack))
		pendingLootFlow.add_child(btn)


func onPendingItemPressed(stack: Dictionary) -> void:
	var itemName = stack.get("name", "")
	var success = inventorySystem.addToBackpack(itemName, 1, true) # one at a time
	print(" - stack: ", itemName, " - ", stack)
	if (success):
		# Decrement qty or remove if empty
		stack["qty"] -= 1
		if stack["qty"] <= 0:
			main.game_data.pendingLoot.erase(stack)
		main.save_game()
		refreshPendingLoot()
		GameEvents.eventLogged.emit(
			"Picked up %s." % itemName, "gather", false
		)
	else:
		GameEvents.eventLogged.emit(
			"Still too heavy or full.", "system", false
		)

func clearPendingLoot() -> void:
	main.game_data.pendingLoot.clear()
	main.save_game()
