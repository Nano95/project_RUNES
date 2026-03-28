extends Control
class_name PrestigeCard

@export var card_name:Label
@export var card_desc:Label
@export var panel:TextureRect
@export var card_button:Button
@export var card_yes:Texture
@export var card_no:Texture

var og_scale:Vector2
var is_blessing:bool = true
var main:MainNode
var data:Dictionary
var card_id:String

func _ready() -> void:
	og_scale = scale

func setup(main_node:MainNode, blessing:bool, my_data:Dictionary) -> void:
	main = main_node
	is_blessing = blessing
	data = my_data
	card_id = data['id']
	setup_ui()
	# Connect button
	card_button.pressed.connect(card_pressed)

func setup_ui() -> void:
	card_name.text = data['name']
	card_desc.text = data['desc']
	panel.texture = card_yes if (data['toggled']) else card_no

func card_pressed() -> void:
	data.toggled = !data['toggled']
	panel.texture = card_yes if (data['toggled']) else card_no
	main.save_game()
	play_press_bounce()

func play_press_bounce() -> void:
	var t := create_tween()
	t.set_parallel(true)
	# Start slightly smaller
	scale = Vector2(og_scale.x - .08, og_scale.y - .08)

	# Pop up (overshoot)
	t.tween_property(self, "scale", Vector2(og_scale.x + .1, og_scale.y + .1), 0.10)\
		.set_trans(Tween.TRANS_BOUNCE)\
		.set_ease(Tween.EASE_OUT)

	# Settle back to normal
	t.set_parallel(false).tween_property(self, "scale", og_scale, 0.08)\
		.set_trans(Tween.TRANS_BOUNCE)\
		.set_ease(Tween.EASE_OUT)
	
