extends Node2D
class_name MyGrid

@export var cell_sprite:Resource
@export var rows := 7
@export var cols := 5
@export var cell_size := Vector2(128, 128)
var game_controller:GameController

var cells = [] # 2D array storing monster instances or null

"""
(0,0) (0,1) (0,2)
(1,0) (1,1) (1,2)
(2,0) (2,1) (2,2)
"""

func _ready():
	cells.resize(rows)
	for r in rows:
		cells[r] = []
		for c in cols:
			cells[r].append(null)
			var sprite = Sprite2D.new()
			sprite.texture = cell_sprite
			sprite.position = grid_to_world(r,c) + cell_size * 0.5
			sprite.scale = Vector2(3.5, 3.5)
			$TileContainer.add_child(sprite)

func setup(gc:GameController) -> void:
	game_controller = gc

func _input(event):
	if event is InputEventScreenTouch and event.pressed:
		var cell = world_to_grid(event.position)
		if not is_valid(cell.x, cell.y): return # ignore taps outside the grid
		game_controller.on_cell_tapped(cell.x, cell.y)

func spawn_monster_into_cell(row: int, col: int, base: MonsterBase):
	if (not is_valid(row, col)): return
	if cells[row][col] != null: return # cell occupied

	var monster = game_controller.monster_instance.instantiate()
	monster.setup(base, self)

	# mutation
	if (randf() < 0.25):
		monster.become_elite()

	# convert grid coords → world coords
	monster.position = grid_to_world(row, col) + Vector2(64, 108)
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

func world_to_grid(world_pos: Vector2) -> Vector2i:
	var local = to_local(world_pos)
	var col = int(floor(local.x / cell_size.x))
	var row = int(floor(local.y / cell_size.y))
	return Vector2i(row, col)

func grid_to_world(row: int, col: int) -> Vector2:
	return Vector2(col * cell_size.x, row * cell_size.y)

func is_valid(r: int, c: int) -> bool:
	return r >= 0 and r < rows and c >= 0 and c < cols
