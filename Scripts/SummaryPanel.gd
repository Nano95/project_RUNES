extends Control

var main:MainNode
var game_controller: GameController
@export var back_btn: Button
@export var retry_btn: Button

func _ready() -> void:
	setup_labels()
	
	back_btn.pressed.connect(main.delete_all_top_ui_children)
	back_btn.pressed.connect(main.spawn_main_menu)
	retry_btn.pressed.connect(restart_game)
	animate_summary_in_happy()

func restart_game() -> void:
	game_controller.start_game(true)
	animate_summary_out_and_free()

func setup(game: GameController, main_node: MainNode, message:String="Victory!") -> void:
	main = main_node
	game_controller = game
	$ColorRect/Panel/Title.set_text(message)

func setup_labels() -> void:
	$ColorRect/Panel/EnemiesDead.text = "Enemies pulverized: " + str(game_controller.enemies_killed)
	$ColorRect/Panel/RunesUsed.text = "Runes used: " + str(game_controller.runes_used)

func animate_summary_in_happy():
	# Start invisible and slightly small
	modulate.a = 0.0
	scale = Vector2(0.85, 0.85)

	var tween := create_tween()

	# --- FADE IN ---
	tween.tween_property(self, "modulate:a", 1.0, 0.25)\
		.set_trans(Tween.TRANS_SINE)\
		.set_ease(Tween.EASE_OUT)

	# --- SCALE UP WITH BOUNCE ---
	tween.parallel().tween_property(self, "scale", Vector2(1.05, 1.05), 0.18)\
		.set_trans(Tween.TRANS_CUBIC)\
		.set_ease(Tween.EASE_OUT)

	# --- SETTLE BACK TO NORMAL SIZE ---
	tween.tween_property(self, "scale", Vector2(1.0, 1.0), 0.12)\
		.set_trans(Tween.TRANS_CIRC)\
		.set_ease(Tween.EASE_OUT)


func animate_summary_out_and_free():
	var tween := create_tween()

	# --- FADE OUT ---
	tween.tween_property(self, "modulate:a", 0.0, 0.22)\
		.set_trans(Tween.TRANS_SINE)\
		.set_ease(Tween.EASE_IN)

	# --- SCALE DOWN SLIGHTLY ---
	tween.parallel().tween_property(self, "scale", Vector2(0.9, 0.9), 0.22)\
		.set_trans(Tween.TRANS_CUBIC)\
		.set_ease(Tween.EASE_IN)

	# --- SLIDE DOWN (or up if you prefer) ---
	tween.parallel().tween_property(self, "position:y", position.y + 40, 0.28)\
		.set_trans(Tween.TRANS_SINE)\
		.set_ease(Tween.EASE_IN)

	# --- CLEANUP ---
	tween.tween_callback(queue_free)
