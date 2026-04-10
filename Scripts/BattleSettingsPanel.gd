extends Control
class_name BattleSettingsPanel

@export var opacity_slider:HSlider
@export var grid_pos_slider:HSlider
@export var exit_btn:Button

var main:MainNode
var game_controller:GameController

func _ready() -> void:
	Utils.animate_summary_in_happy(self)
	### Connect things
	exit_btn.pressed.connect(exit)
	$Button.pressed.connect(exit)
	opacity_slider.value_changed.connect(opacity_slider_updated)
	# ypos slider connected in the initialize func
	### Initialize settings
	opacity_slider.value = main.game_data.grid_opacity
	initialize_grid_y_position_slider()

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

func setup(m:MainNode, gc:GameController) -> void:
	main = m
	game_controller = gc

func exit() -> void:
	Utils.animate_summary_out_and_free(self)
