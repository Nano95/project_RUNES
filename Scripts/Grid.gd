extends Control
class_name MyGrid

@export var cell_btn:PackedScene
@export var rows := 7
@export var cols := 5
var cell_size := Vector2(128, 128)
var game_controller:GameController
var grid_origin :Vector2= Vector2.ZERO
var cells = [] # 2D array storing monster instances or null

"""
(0,0) (0,1) (0,2)
(1,0) (1,1) (1,2)
(2,0) (2,1) (2,2)
"""
var padding := -4.0
func _ready():
	grid_origin = global_position
	cells.resize(rows)
	for r in rows:
		cells[r] = []
		for c in cols:
			cells[r].append(null)
			var cell = cell_btn.instantiate() as Button
			cell.set_coords(r, c)
			cell.row = r
			cell.col = c
			cell.position = Vector2(
				c * (cell_size.x + padding),
				r * (cell_size.y + padding)
			)
			cell.connect("cell_pressed", _on_cell_pressed)
			$TileContainer.add_child(cell)

func setup(gc:GameController) -> void:
	game_controller = gc

func _on_cell_pressed(row, col):
	game_controller.on_cell_tapped(row, col)

func spawn_monster_into_cell(row: int, col: int, base: MonsterBase):
	if (not is_valid(row, col)): return
	if cells[row][col] != null: return # cell occupied

	var monster = game_controller.monster_instance.instantiate() as MonsterInstance
	monster.died.connect(game_controller.monster_died.bind(monster))
	monster.setup(base, self)

	# mutation
	if (randf() < 0.05):
		monster.become_elite()

	# convert grid coords → world coords
	monster.position = grid_to_world(row, col) + Vector2(6, 0) # Some adjustment to center
	$MonstersContainer.add_child(monster)
	cells[row][col] = monster
	game_controller.register_monster(monster)

func clear_monster(monster):
	for r in rows:
		for c in cols:
			if cells[r][c] == monster:
				cells[r][c] = null
				return

# Helper for when we reset the round
func clear_all_cells():
	for r in range(rows):
		for c in range(cols):
			cells[r][c] = null

func add_to_rune_container(rune:Node2D) -> void:
	%RuneContainer.add_child(rune)

func spawn_to_fx_container(node) -> void:
	%fxContainer.add_child(node)

func pick_empty_cell() -> Vector2i:
	var list = []
	for r in rows:
		for c in cols:
			if cells[r][c] == null:
				list.append(Vector2i(r, c))
	return list.pick_random()

func highlight_cell(row, col, color):
	var index = row * cols + col
	var sprite = $CellContainer.get_child(index)
	sprite.modulate = color

func grid_to_world(row: int, col: int) -> Vector2:
	return Vector2(
		col * (cell_size.x + padding) + cell_size.x * 0.5,
		row * (cell_size.y + padding) + cell_size.y * 0.5
	)

func is_valid(r: int, c: int) -> bool:
	return r >= 0 and r < rows and c >= 0 and c < cols
