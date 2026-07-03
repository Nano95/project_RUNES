extends Control
class_name FocusChamberModal

@export var mainMenuView:Control
@export var practiceBtn:Button
@export var trialBtn:Button
@export var PracticeView:Control
@export var easyBtn:Button
@export var medBtn:Button
@export var hardBtn:Button
@export var backBtn1:Button

@export var trialView:Control
@export var goToTrialBtn:Button
@export var backBtn2:Button
var main:MainNode

func _ready() -> void:
	display_main_view()
	connect_buttons()
	Utils.animate_summary_in_happy(self)

func setup(m:MainNode) -> void:
	main = m

func connect_buttons() -> void:
	practiceBtn.pressed.connect(display_practice_view)
	trialBtn.pressed.connect(display_trial_view)
	backBtn1.pressed.connect(display_main_view)
	backBtn2.pressed.connect(display_main_view)
	easyBtn.pressed.connect(spawn_focus_chamber.bind(true, "E"))
	medBtn.pressed.connect(spawn_focus_chamber.bind(true, "M"))
	hardBtn.pressed.connect(spawn_focus_chamber.bind(true, "H"))
	goToTrialBtn.pressed.connect(spawn_focus_chamber.bind(false))

func display_practice_view(isVisible:bool=true) -> void:
	PracticeView.visible = isVisible
	mainMenuView.visible = !isVisible
	trialView.visible = !isVisible

func display_trial_view(isVisible:bool=true) -> void:
	trialView.visible = isVisible
	PracticeView.visible = !isVisible
	mainMenuView.visible = !isVisible

func display_main_view(isVisible:bool=true) -> void:
	mainMenuView.visible = isVisible
	PracticeView.visible = !isVisible
	trialView.visible = !isVisible

func spawn_focus_chamber(is_practice:bool=false, mode:String="") -> void:
	main.spawn_focus_chamber(is_practice, mode)
