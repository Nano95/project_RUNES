extends Control
class_name FocusChamber

@export var number_pad:Control
@export var code_label:Label # The 
@export var player_input_label:Label 
@export var timer_progress_bar:TextureProgressBar # time left to play
@export var end_btn:Button

var player_input:String = "" # What the player types
var code_number:String = "" # Code that the player needs to type
var code_label_tween: Tween
var shake_tween: Tween

var score:int = 0 # keeps track of how many times the player got it right.
var main:MainNode

# When is_practice is false then we do things a bit differently
var is_practice:bool=false
var practice_difficulty:String = "" # E(asy),M(ed),H(ard) 

func _ready() -> void:
	# Begin some timer once we are ready for the countdown
	connect_number_pad()
	start_round()
	end_btn.pressed.connect(main.spawn_main_menu)

func setup(m:MainNode, ispractice:bool=false, practice_mode:String="") -> void:
	main = m
	is_practice = ispractice
	if (!is_practice):
		return
	practice_difficulty = practice_mode

func connect_number_pad() -> void:
	# Loop through all Button children of this Control node
	for button in number_pad.get_children():
		if button is Button:
			button.connect("pressed", Callable(self, "_on_number_pad_button_pressed").bind(button))

# Callback function for button presses
func _on_number_pad_button_pressed(button: Button):
	if (button.text.contains("<")):
		if player_input.length() > 0:
			player_input = player_input.substr(0, player_input.length() - 1)
	elif (button.text.contains("Clear")):
		player_input = ""
	else:
		# Append the number to the input
		player_input += button.text
	
	update_player_input()
	check_enemy_output_visibility()
	check_accuracy()

func check_accuracy() -> void:
	if !(player_input.length() == code_number.length()):
		return
	if player_input == code_number:
		on_correct_code()
	else:
		on_wrong_code()

func update_player_input() -> void:
	player_input_label.text = player_input

func check_enemy_output_visibility() -> void:
	# Only show the code label when the player has not began typing.
	if (player_input.length() <= 0):
		animate_code_label(1.0, .05)
	else:
		animate_code_label(0.0, .15)

func generate_focus_code(length: int) -> String:
	var code := ""
	for i in range(length):
		code += str(randi() % 10)
	return code

func format_code(code: String, chunk_size: int) -> String:
	var formatted := ""
	for i in range(0, code.length(), chunk_size):
		var chunk := code.substr(i, chunk_size)
		formatted += chunk + " "
	return formatted.strip_edges()

func start_round() -> void:
	player_input = ""
	player_input_label.text = ""
	var _length: int
	var chunk: int
	if (is_practice):
		match practice_difficulty:
			"E":
				_length = 4
				chunk = 4
			"M":
				_length = 6
				chunk = 3
			"H":
				_length = 8
				chunk = 4
	else:
		var diff := get_trial_difficulty(score)
		_length = diff["length"]
		chunk = diff["chunk"]
	
	print("- _length", _length, " - ", chunk)
	code_number = generate_focus_code(_length)
	code_label.text = format_code(code_number, chunk)
	animate_code_label(1.0, .1)
	print("- code_label.text: ", code_label.text)

func on_correct_code() -> void:
	score += 1
	# Play a success animation, sound, etc.
	# Start next round (you can adjust length/chunk_size based on difficulty)
	start_round()  # example

func on_wrong_code() -> void:
	# Play a failure animation
	# End trial or reduce streak
	shake_code_label(20)
	start_round()

func get_trial_difficulty(_score: int) -> Dictionary:
	if (_score < 5):
		return {"length": 4, "chunk": 4}
	elif (_score < 10):
		return {"length": 6, "chunk": 3}
	elif (_score < 15):
		return {"length": 8, "chunk": 4}
	else:
		return {"length": 9, "chunk": 3}


func animate_code_label(target_alpha: float, duration: float = 0.25) -> void:
	# Kill any previous tween
	if code_label_tween:
		code_label_tween.kill()

	# Create a new tween
	code_label_tween = create_tween()
	code_label_tween.tween_property(code_label, "modulate:a", target_alpha, duration) \
		.set_trans(Tween.TRANS_SINE) \
		.set_ease(Tween.EASE_OUT)

func shake_code_label(intensity: float = 8.0, duration: float = 0.08) -> void:
	# Kill any previous shake tween
	if shake_tween:
		shake_tween.kill()

	var original_pos := code_label.position

	shake_tween = create_tween()

	# Move left
	shake_tween.tween_property(code_label, "position:x", original_pos.x - intensity, duration) \
	.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)

	# Move right
	shake_tween.tween_property(code_label, "position:x", original_pos.x + intensity, duration) \
	.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	shake_tween.tween_property(code_label, "position:x", original_pos.x - intensity, duration) \
	.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)

	# Move back to center
	shake_tween.tween_property(code_label, "position:x", original_pos.x, duration) \
	.set_trans(Tween.TRANS_ELASTIC).set_ease(Tween.EASE_OUT)
