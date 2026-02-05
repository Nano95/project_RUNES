extends Control
class_name DebugPanel

@export var button_group:ButtonGroup
var qty_multiplier:int = 1000

@export var btn1000:Button
@export var btn20000:Button
@export var btn500000:Button
@export var btn90000000:Button
@export var exp_btn:Button
@export var gold_btn:Button

var main_menu:MainMenu
var main_node:MainNode

func _ready() -> void:
	connect_buttons()

func setup(menu:MainMenu, main:MainNode) -> void:
	main_menu = menu
	main_node = main

func connect_buttons() -> void:
	btn1000.toggled.connect(qty_button_pressed)
	btn20000.toggled.connect(qty_button_pressed)
	btn500000.toggled.connect(qty_button_pressed)
	btn90000000.toggled.connect(qty_button_pressed)
	exp_btn.pressed.connect(give_exp)
	gold_btn.pressed.connect(give_gold)
	$backdropButton.pressed.connect(delete_debug)

func delete_debug() -> void:
	queue_free()

func give_exp() -> void:
	main_menu.add_xp(qty_multiplier)

func give_gold() -> void:
	main_node.game_data.current_gold += qty_multiplier
	#main_node.game_data.total_gold += qty_multiplier # Dont give it to total gold?? Avoids the stat getting inflated.

func qty_button_pressed(toggled) -> void:
	print("toggled ", toggled)
	if !toggled: return
	var button_pressed = button_group.get_pressed_button()
	print("Name: ", button_pressed.name)
	match button_pressed.name:
		btn1000.name:
			qty_multiplier = 1000
		btn20000.name: 
			qty_multiplier = 20000
		btn500000.name:
			qty_multiplier = 500000
		btn90000000.name:
			qty_multiplier = 90000000
		_:
			qty_multiplier = 1000
	
	print("-debug multi: ", qty_multiplier)
