extends Control
class_name FightMenu

@export var monster_grid_container:GridContainer
@export var location_grid_container:GridContainer
@export var rune_grid_container:GridContainer
@export var start_button:Button
@export var exit_button:Button
@export var my_button:PackedScene
@onready var rune_button:PackedScene = preload("res://Scenes/FightMenuRuneButton.tscn")
@onready var monster_info:Control = $ColorRect/Panel/MonsterInfo
var areas:Array = ["slimes", "orcs", "sandlings", "dwarves"]

var selected_family: String = ""
var selected_monster_index: int = -1
var selected_runes: Array = []
var starting_turns: int = 4

var game_controller: GameController
var main: MainNode

func _ready() -> void:
	Utils.animate_summary_in_happy(self)
	setup_monster_grid()
	setup_rune_grid()
	start_button.pressed.connect(main.spawn_game)
	exit_button.pressed.connect(close)
	$ColorRect/Panel/ToggleMonsterInfo.pressed.connect(toggle_monster_info)

func setup(main_node:MainNode) -> void:
	main = main_node

func setup_rune_grid() -> void:
	for btn in rune_grid_container.get_children():
		btn.queue_free()
	#for rune in Utils.all_runes:
	var runes = RuneDatabase.runes
	for rune in runes.keys():
		if !(rune in main.game_data.rune_inv):
			continue
		var btn := rune_button.instantiate()
		btn.setup(runes[rune])
		btn.pressed.connect(_on_rune_pressed.bind(rune))
		rune_grid_container.add_child(btn)
		main.battle_data["selected_runes"].append(runes[rune])

func setup_monster_grid() -> void:
	for btn in monster_grid_container.get_children():
		btn.queue_free()
	var next_family := get_next_unlockable_family()
	for family in areas:
		# Only show unlocked families OR the next unlockable one
		if main.game_data.unlocked_monster_families[family] or family == next_family:
			var btn := my_button.instantiate()
			var callable:Callable = try_unlock_family.bind(family) if (family == next_family) else _on_family_selected.bind(family)
			btn.setup(
				family,
				callable,
				Vector2(.4, .4),
				!main.game_data.unlocked_monster_families[family]
			)

			monster_grid_container.add_child(btn)

	# Auto-select the first unlocked family
	if (main.game_data.unlocked_monster_families[main.battle_data["family"]]):
		_on_family_selected(main.battle_data["family"])

func try_unlock_family(family: String):
	var cost = MonsterDatabase.monster_stage_cost[family]

	if main.game_data.current_gold < cost:
		print(" NOT ENOUGH MONEY! ")
		#show_not_enough_gold_popup()
		return

	main.game_data.current_gold -= cost
	main.game_data.unlocked_monster_families[family] = true
	main.save_game()
	main.purchase_successful_update_ui()

	setup_monster_grid() # rebuild UI

func get_next_unlockable_family() -> String:
	for family in areas:
		if not main.game_data.unlocked_monster_families[family]:
			return family
	return ""  # all unlocked

func _on_rune_pressed(rune):
	if main.battle_data["selected_runes"].has(rune):
		main.battle_data["selected_runes"].erase(rune)
	else:
		if main.battle_data["selected_runes"].size() < 5:
			main.battle_data["selected_runes"].append(rune)

func _on_family_selected(family: String) -> void:
	#if (main.battle_data["family"] == family): return
	main.battle_data["family"] = family
	for btn in location_grid_container.get_children():
		btn.queue_free()
	
	var monsters = MonsterDatabase[family]
	for i in monsters.size():
		var btn := my_button.instantiate()
		btn.setup(monsters[i].name.capitalize(),_on_monster_selected.bind(i + 1, monsters[i]), Vector2(.4, .4))
		location_grid_container.add_child(btn)

func _on_monster_selected(index: int, monster:MonsterBase) -> void: 
	main.battle_data["index"] = index
	monster_info.update_panel(monster)

func close() -> void:
	Utils.animate_summary_out_and_free(self)

func toggle_monster_info() -> void:
	$ColorRect/Panel/ChooseRunes.visible = !$ColorRect/Panel/ChooseRunes.visible
	monster_info.visible = !monster_info.visible
