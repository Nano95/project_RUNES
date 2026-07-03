extends Control
class_name FocusChamberSummary

@export var quote_label:Label
@export var score_label:Label
@export var highscore_label:RichTextLabel
@export var back_button:Button
var score:int
var is_practice:bool=false
var mode:String=""
var main:MainNode

func _ready() -> void:
	score_and_labels()
	setup_loot()
	back_button.pressed.connect(main.delete_all_top_ui_children)
	back_button.pressed.connect(main.spawn_main_menu)

func setup(m:MainNode, scor:int=0, practice:bool=false, _mode:String="") -> void:
	main = m
	score = scor
	is_practice = practice
	mode = _mode

func setup_loot() -> void:
	pass

func score_and_labels() -> void:
	var was_highscore:bool = false
	var mode_score:int = score
	if (is_practice):
		match mode:
			"E":
				mode_score = main.game_data.focus_chamber_practice_easy_highscore
				if (score > mode_score):
					main.game_data.focus_chamber_practice_easy_highscore = score
					was_highscore = true
			"M":
				mode_score = main.game_data.focus_chamber_practice_med_highscore
				if (score > mode_score):
					main.game_data.focus_chamber_practice_med_highscore = score
					was_highscore = true
			"H":
				mode_score = main.game_data.focus_chamber_practice_hard_highscore
				if (score > mode_score):
					main.game_data.focus_chamber_practice_hard_highscore = score
					was_highscore = true
	else:
		# Trial mode
		mode_score = main.game_data.focus_chamber_trial_highscore
		if (score > mode_score):
			main.game_data.focus_chamber_trial_highscore = score
			was_highscore = true
	
	if (was_highscore):
		score_label.visible = false
		highscore_label.visible = true
		Utils.set_rainbow_text(highscore_label, "NEW BEST: " + str(score))
	else:
		score_label.text = "Score: " + str(score) + " | Best: " +\
		str(mode_score)
