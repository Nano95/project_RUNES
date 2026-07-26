extends ColorRect
class_name CheckpointOverlay

@export var descLabel: RichTextLabel
@export var continueButton: Button
@export var retreatButton: Button
@export var eventLogPanel: Panel
@export var areaSystem: AreaSystem

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
	hide()

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
	onOpen()

func onContinuePressed() -> void:
	Utils.animateButtonPress(continueButton)
	onHide()
	GameEvents.checkpointContinued.emit()
	GameEvents.eventLogged.emit("You press deeper...", "system", false)

func onRetreatPressed() -> void:
	Utils.animateButtonPress(retreatButton)
	onHide()
	areaSystem.exitArea()
