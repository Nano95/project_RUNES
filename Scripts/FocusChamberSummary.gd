extends Control
class_name FocusChamberSummary

@export var quote_label:Label
@export var score_label:Label
@export var highscore_label:RichTextLabel
@export var back_button:Button
var score:int
var main:MainNode

func _ready() -> void:
	setup_labels()
	setup_loot()
	back_button.pressed.connect(main.delete_all_top_ui_children)
	back_button.pressed.connect(main.spawn_main_menu)

func setup(m:MainNode, scor:int=0) -> void:
	main = m
	score = scor

func setup_labels() -> void:
	var best_score:int = main.game_data.focus_chamber_highscore
	
	if (score > best_score):
		score_label.visible = false
		highscore_label.visible = true
		Utils.set_rainbow_text(highscore_label, "NEW BEST: " + str(best_score))
	else:
		score_label.text = "Score: " + str(score) + " | Best: " +\
		str(main.game_data.focus_chamber_highscore)
	

func setup_loot() -> void:
	pass
