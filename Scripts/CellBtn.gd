extends Button

var row: int = 0 
var col: int = 0


signal cell_pressed(row, col)

func set_coords(r:int, c:int) -> void:
	row = r
	col = c

func _pressed():
	emit_signal("cell_pressed", row, col)
