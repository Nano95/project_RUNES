extends ColorRect
class_name CheckpointOverlay

@export var descLabel: RichTextLabel
@export var continueButton: Button
@export var retreatButton: Button
@export var autoCheckbox: CheckButton

@export var autoTimer: Timer
@export var autoProgress: ProgressBar

@export var eventLogPanel: Panel
@export var areaSystem: AreaSystem

const AUTO_DURATION: float = 2.0

const CHECKPOINT_MESSAGES = [
	"Push your [shake rate=15 level=3]luck[/shake], or [wave amp=10 freq=2]live[/wave] to fight another day.",
	"The world holds its [shake rate=10 level=2]breath[/shake].",
	"How [wave amp=8 freq=3]far[/wave] is far enough?",
	"[shake rate=20 level=5]Danger[/shake] grows with every step forward.",
	"Your loot is [color=#27ae60]safe[/color] in town. Your [shake rate=25 level=6]life[/shake] is not.",
]

func _ready() -> void:
	GameEvents.checkpointReached.connect(onCheckpointReached)
	continueButton.pressed.connect(onContinuePressed)
	retreatButton.pressed.connect(onRetreatPressed)
	autoCheckbox.toggled.connect(onAutoToggled)
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
	position.y = eventLogPanel.position.y
	Utils.animate_modal_entry(self)
	show()

func onHide() -> void:
	Utils.animate_modal_exit(self)
	hide()

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
	onHide()
	GameEvents.checkpointContinued.emit()
	GameEvents.eventLogged.emit("You press deeper...", "system", false)

func onRetreatPressed() -> void:
	Utils.animateButtonPress(retreatButton)
	stopAutoTimer()
	onHide()
	areaSystem.exitArea()

func onAutoToggled(pressed: bool) -> void:
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
