extends Control
class_name FocusChamber

@export var number_pad:Control
@export var code_label:Label # The 
@export var player_input_label:Label 
@export var timer_progress_bar:TextureProgressBar # time left to play

var player_input:String = "" # What the player types
var code_number:String = "" # Code that the player needs to type
var score:int = 0 # keeps track of how many times the player got it right.
var main:MainNode

func _ready() -> void:
	# Begin some timer once we are ready for the countdown
	connect_number_pad()
	start_round(4, 1)

func setup(m:MainNode) -> void:
	main = m

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
	code_label.visible = player_input.length() <= 0

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

func start_round(length: int, chunk_size: int) -> void:
	player_input = ""
	player_input_label.text = ""

	code_number = generate_focus_code(length)
	code_label.text = format_code(code_number, chunk_size)
	code_label.visible = true

func on_correct_code() -> void:
	score += 1
	# Play a success animation, sound, etc.
	# Start next round (you can adjust length/chunk_size based on difficulty)
	start_round(code_number.length(), 2)  # example

func on_wrong_code() -> void:
	# Play a failure animation
	# End trial or reduce streak
	score = 0
	start_round(code_number.length(), 2)
