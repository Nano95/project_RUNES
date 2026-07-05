extends Control
class_name FocusChamber

@export var number_pad:Control
@export var code_label:Label # The 
@export var player_input_label:Label 
@export var timer_progress_bar:TextureProgressBar # time left to play
@export var end_btn:Button
@export var whiteout:PackedScene
@export var focus_chamber_summary:PackedScene
@export var time_up_panel:Panel
@export var time_up_label:Label
@export var particles:CPUParticles2D
@export var particles_timer:Timer
@export var loot_manager:LootManager

var player_input:String = "" # What the player types
var code_number:String = "" # Code that the player needs to type
var code_label_tween: Tween
var shake_tween: Tween

var current_loot_summary:Dictionary
var timer_duration: float = 25.0
var timer_remaining: float = 0.0
var timer_active: bool = false
var on_correct_addition:float = 1.0

var score:int = 0 # keeps track of how many times the player got it right.
var main:MainNode

# When is_practice is false then we do things a bit differently
var is_practice:bool=false
var practice_difficulty:String = "" # E(asy),M(ed),H(ard) 

func _ready() -> void:
	# Begin some timer once we are ready for the countdown
	connect_number_pad()
	start_round(true)
	end_btn.pressed.connect(main.spawn_main_menu)
	particles_timer.timeout.connect(stop_emitting_particles)
	timer_progress_bar.min_value = 0.0
	timer_progress_bar.max_value = 1.0
	timer_progress_bar.step = 0.0
	timer_progress_bar.rounded = false
	# Clear it!
	main.game_data.last_focus_chamber_summary = []
	main.save_game()

func setup(m:MainNode, ispractice:bool=false, practice_mode:String="") -> void:
	main = m
	is_practice = ispractice
	if (!is_practice):
		return
	practice_difficulty = practice_mode

func _process(delta: float) -> void:
	if (not timer_active):
		return
	timer_remaining -= delta

	# Update progress bar (1.0 → 0.0)
	timer_progress_bar.value = (timer_remaining / timer_duration)

	if (timer_remaining <= 0.0):
		set_process(false)
		timer_active = false
		on_time_expired()

func on_time_expired() -> void:
	var white = whiteout.instantiate()
	white.setup(Color(1.0, 1.0, 1.0, .5))
	main.spawn_to_top_ui_layer(white)
	disable_buttons(true)
	slide_banner_label(time_up_label, time_up_panel)
	main.save_game()

func reward_essences(amount: int = 10) -> void:
	particles.emitting = true
	particles_timer.start(.1)
	
	# Do not reward essences in practice mode
	if (is_practice):
		return
	
	var essence_types := ["arcane", "fire", "ice", "earth", "electric"]
	var chosen = essence_types[randi() % essence_types.size()]
	loot_manager.add_loot_from_key(chosen + " essence", amount)
	if !(current_loot_summary.has(chosen + " essence")):
		current_loot_summary[chosen + " essence"] = 0
	current_loot_summary[chosen + " essence"] += amount
	# Add to current essences
	main.game_data.current_essences[chosen] += amount
	# Add to total essences (lifetime)
	main.game_data.total_essences[chosen] += amount

func connect_number_pad() -> void:
	# Loop through all Button children of this Control node
	for button in number_pad.get_children():
		if button is Button:
			button.connect("pressed", Callable(self, "_on_number_pad_button_pressed").bind(button))

func disable_buttons(should_disable:bool=true) -> void:
	# Loop through all Button children of this Control node
	for button in number_pad.get_children():
		if button is Button:
			button.disabled = should_disable

func stop_emitting_particles() -> void:
	particles_timer.stop()
	particles.emitting = false

# Callback function for button presses
func _on_number_pad_button_pressed(button: Button):
	if (button.text.contains("<")):
		if player_input.length() > 0:
			player_input = player_input.substr(0, player_input.length() - 1)
	elif (button.text.contains("Clear")):
		player_input = ""
		#player_input = str(code_number)
	else:
		# Append the number to the input
		player_input += button.text
	
	update_player_input()
	check_enemy_output_visibility()
	check_accuracy()

func check_accuracy() -> void:
	if !(player_input.length() == code_number.length()):
		return
	record_focus_attempt(code_label.text, player_input_label.text, code_number, player_input)
	if (player_input == code_number):
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

func start_round(start_timer:bool=false) -> void:
	player_input = ""
	player_input_label.text = ""
	var _length: int
	var chunk: int
	if (is_practice):
		match practice_difficulty:
			"E":
				_length = 4
				chunk = 4
				on_correct_addition = .7
			"M":
				_length = 6
				chunk = 3
				on_correct_addition = 1.5
			"H":
				_length = 8
				chunk = 4
				on_correct_addition = 2.5
	else:
		var diff := get_trial_difficulty(score)
		_length = diff["length"]
		chunk = diff["chunk"]
	
	code_number = generate_focus_code(_length)
	code_label.text = format_code(code_number, chunk)
	animate_code_label(1.0, .1)
	
	if (start_timer):
		set_process(true)
		# Reset timer
		timer_remaining = timer_duration
		timer_active = true
		timer_progress_bar.value = 1.0  # full bar

func on_correct_code() -> void:
	score += 1
	timer_remaining += 1.0
	reward_essences(15 + (score * 5))
	# Play a success animation, sound, etc.
	# Start next round (you can adjust length/chunk_size based on difficulty)
	start_round()  # example

func on_wrong_code() -> void:
	# Play a failure animation
	# End trial or reduce streak
	disable_buttons(true)
	animate_code_label(1.0, .1)
	shake_code_label(20) # The shake inside of this will start the round

func get_trial_difficulty(_score: int) -> Dictionary:
	if (_score < 4):
		on_correct_addition = 0.5
		return {"length": 4, "chunk": 4}
	elif (_score < 10):
		on_correct_addition = 1.4
		return {"length": 6, "chunk": 3}
	elif (_score < 15):
		on_correct_addition = 1.8
		return {"length": 8, "chunk": 4}
	else:
		on_correct_addition = 2.5
		return {"length": 9, "chunk": 3}

func spawn_summary() -> void:
	var summary = focus_chamber_summary.instantiate()
	summary.setup(main, self, score, is_practice, practice_difficulty)
	main.spawn_to_top_ui_layer(summary)

func record_focus_attempt(generated: String, typed: String, num_generated:String, player_typed:String) -> void:
	var entry := {
		"formatted_generated": generated,
		"typed": typed,
		"generated": num_generated
	}
	main.game_data.last_focus_chamber_summary.append(entry)

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
	shake_tween.tween_callback(func (): 
		start_round()
		disable_buttons(false)
	)

func slide_banner_label(label: Label, panel: Panel) -> void:
	panel.visible = true
	var screen_width := panel.size.x
	var center_x := (screen_width - label.size.x) * 0.5

	# Start off-screen left
	label.position.x = -label.size.x

	var slide_tween = create_tween()

	# 1. Enter fast → slow down near center
	slide_tween.tween_property(label, "position:x", center_x, .8) \
		.set_trans(Tween.TRANS_CIRC) \
		.set_ease(Tween.EASE_OUT)

	# 2. Exit fast → speed up as it leaves
	slide_tween.tween_property(label, "position:x", screen_width + label.size.x, 1.5) \
		.set_trans(Tween.TRANS_SINE) \
		.set_ease(Tween.EASE_IN)
	
	slide_tween.tween_callback(spawn_summary)
