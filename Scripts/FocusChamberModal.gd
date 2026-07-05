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
@export var easy_hs:Label
@export var med_hs:Label
@export var hard_hs:Label
@export var trial_hs:Label

@export var trialView:Control
@export var goToTrialBtn:Button
@export var backBtn2:Button
@export var trial_timer:Timer
var main:MainNode

func _ready() -> void:
	display_main_view()
	connect_buttons()
	setup_labels()
	Utils.animate_summary_in_happy(self)
	
	if (is_focus_chamber_available()):
		goToTrialBtn.text = "Go!"
		trial_timer.stop()
	else:
		goToTrialBtn.disabled = true
		var remaining := get_focus_chamber_remaining()
		goToTrialBtn.text = format_hms(remaining)

		# Start ticking every second
		trial_timer.wait_time = 1.0
		trial_timer.start()
		trial_timer.timeout.connect(_on_trial_timer_tick)

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
	
	if (is_practice):
		return
	
	@warning_ignore("narrowing_conversion")
	var now: int = Time.get_unix_time_from_system()
	#var cooldown_seconds: int = 60 # while testing, only a minute
	var cooldown_seconds: int = 3600
	# an hour from now is what is being set here
	main.game_data.focus_chamber_time_available = int(now + cooldown_seconds)

func is_focus_chamber_available() -> bool:
	var now := Time.get_unix_time_from_system()
	return now >= main.game_data.focus_chamber_time_available

func get_focus_chamber_remaining() -> int:
	var now := Time.get_unix_time_from_system()
	return max(0, main.game_data.focus_chamber_time_available - now)

func setup_labels() -> void:
	easy_hs.text = "Best: " + str(main.game_data.focus_chamber_practice_easy_highscore)
	med_hs.text = "Best: " + str(main.game_data.focus_chamber_practice_med_highscore)
	hard_hs.text = "Best: " + str(main.game_data.focus_chamber_practice_hard_highscore)
	trial_hs.text = "Best: " + str(main.game_data.focus_chamber_trial_highscore)

func format_hms(seconds: int) -> String:
	@warning_ignore("integer_division")
	var mins = (seconds % 3600) / 60
	var secs = seconds % 60
	return "%02d:%02d" % [mins, secs]

func _on_trial_timer_tick() -> void:
	var remaining := get_focus_chamber_remaining()

	if (remaining <= 0):
		trial_timer.stop()
		goToTrialBtn.text = "Go!"
		goToTrialBtn.disabled = false
	else:
		goToTrialBtn.text = format_hms(remaining)
