extends Control
class_name BattleSettingsPanel

@export var opacity_slider:HSlider
@export var grid_pos_slider:HSlider
@export var two_tap_btn:CheckButton
@export var exit_btn:Button

var main:MainNode
var game_controller:GameController

func _ready() -> void:
	Utils.animate_summary_in_happy(self)
	exit_btn.pressed.connect(exit)
	$Button.pressed.connect(exit)
	# ypos slider connected in the initialize func
	### Initialize settings
	opacity_slider.value = main.game_data.grid_opacity
	opacity_slider.value_changed.connect(opacity_slider_updated)
	initialize_grid_y_position_slider()
	two_tap_btn.button_pressed = main.game_data.two_tap_attack
	two_tap_btn.pressed.connect(two_tap_btn_cta)

func initialize_grid_y_position_slider() -> void:
	grid_pos_slider.min_value = game_controller.my_grid.Y_POS_STARTING - 120
	grid_pos_slider.max_value = game_controller.my_grid.Y_POS_STARTING + 120
	grid_pos_slider.value = main.game_data.grid_y_pos_offset
	grid_pos_slider.value_changed.connect(grid_pos_updated)

func grid_pos_updated(val:float) -> void:
	game_controller.my_grid.adjust_grid_height(val)
	main.game_data.grid_y_pos_offset = val

func opacity_slider_updated(val:float) -> void:
	game_controller.my_grid.adjust_tile_opacity(val)
	main.game_data.grid_opacity = val

func two_tap_btn_cta() -> void:
	main.game_data.two_tap_attack = !main.game_data.two_tap_attack

func setup(m:MainNode, gc:GameController) -> void:
	main = m
	game_controller = gc

func exit() -> void:
	Utils.animate_summary_out_and_free(self)
