extends Control
class_name BattleSettingsPanel

@export var opacity_slider:HSlider
@export var exit_btn:Button

var main:MainNode
var game_controller:GameController

func _ready() -> void:
	Utils.animate_summary_in_happy(self)
	### Connect things
	exit_btn.pressed.connect(exit)
	$Button.pressed.connect(exit)
	opacity_slider.value_changed.connect(opacity_slider_updated)
	
	### Initialize settings
	opacity_slider.value = main.game_data.grid_opacity
	print("opac: ", main.game_data.grid_opacity)

func opacity_slider_updated(val:float) -> void:
	game_controller.my_grid.adjust_tile_opacity(val)
	main.game_data.grid_opacity = val

func setup(m:MainNode, gc:GameController) -> void:
	main = m
	game_controller = gc

func exit() -> void:
	Utils.animate_summary_out_and_free(self)
