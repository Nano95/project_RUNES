extends Button

var row: int = 0 
var col: int = 0
@export var tile_texture:TextureRect
@export var preview_texture:TextureRect
var shader_mat

signal cell_pressed(row, col)

func _ready() -> void:
	shader_mat = preview_texture.material

func set_coords(r:int, c:int) -> void:
	row = r
	col = c

func _pressed():
	emit_signal("cell_pressed", row, col)

func set_my_modulate(color:Color) -> void:
	tile_texture.self_modulate = color

func turn_on_preview(on:bool) -> void:
	preview_texture.visible = on

func set_color(color:Color) -> void:
	shader_mat.set("shader_parameter/glow_color", color)
