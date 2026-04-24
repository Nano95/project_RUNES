extends Control
class_name PrestigeCard

@export var card_name:Label
@export var card_desc:Label
@export var card_cost:Label
@export var panel:TextureRect
@export var card_button:Button
@export var card_yes:Texture
@export var card_no:Texture

var og_scale:Vector2
var is_blessing:bool = true
var main:MainNode
var prestige_panel:PrestigePanel
var data:Dictionary
var card_id:String
var in_debug_mode:bool=false # NEW - not in use yet. When debug mode is on, we dont need to purchase to toggle on

func _ready() -> void:
	og_scale = scale

func setup(main_node:MainNode, prestige_panel_ref:PrestigePanel, blessing:bool, my_data:Dictionary) -> void:
	main = main_node
	prestige_panel = prestige_panel_ref
	in_debug_mode = prestige_panel.in_debug_mode
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
	update_card_cost()

func update_card_cost() -> void:
	if (is_blessing):
		if (data['locked']):
			card_cost.text = "AP cost: %d" % data.cost
			card_cost.show()
			return
	card_cost.text = "" # Hidden but removes the label? i guess
	card_cost.hide()

func card_pressed() -> void:
	if (in_debug_mode):
		# Regardless of blessing or curse, just toggle
		toggle_card()
		return

	# If this is a blessing, enforce purchase logic
	# Curses are automatically toggled on based on prestige level
	if (is_blessing):
		# If locked → try to buy it
		if (data["locked"]):
			var success = prestige_panel.try_purchase_blessing(card_id)
			if (success):
				toggle_card()
				update_card_cost()
			return
		else:
			# Already unlocked → just toggle
			toggle_card()
			return

func toggle_card():
	data["toggled"] = !data["toggled"]
	panel.texture = card_yes if(data["toggled"]) else card_no
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
	
