extends Node2D
class_name GameController

@export var monster_instance:Resource
@export var summary_panel_ref: Resource
@export var my_grid_ref:Resource
@export var rune_animation:Resource
var base_width = ProjectSettings.get_setting("display/window/size/viewport_width")
var base_height = ProjectSettings.get_setting("display/window/size/viewport_height")

var main:MainNode
var my_grid:MyGrid
var game_ui:GameUI

var game_is_active: bool = true
var group_turns_left:int = 5
var monsters := []  # list of MonsterInstance nodes, only used for things like if all monsters are dead. NOT positional reasons

var selected_monster_family:String="orcs"
var selected_monster_index:int=1
var PADDING:Vector2 = Vector2(38, 290)

### Stats
var max_hp:int
var base_max_hp:int
var current_hp:int
var base_luck:int
var current_luck:int
var current_power:int
var base_power:int
var enemies_killed:int
var runes_used:int
var total_exp:int
var total_gold:int
var loot:Array

signal gained_exp

func _ready() -> void:
	%Camera2D.setup(null) # temporary null until i know what i need to do
	setup_stats()
	spawn_grid()
	start_game()

func start_game(restart:bool=false) -> void:
	game_is_active = true
	if (restart):
		clear_all_monsters()
		group_turns_left = max(2, 5) # it will be base - some ascension number
		
	spawn_stage(selected_monster_index, 5)
	print("Turns to go on start: ", group_turns_left)
	game_ui.update_monster_data(group_turns_left, calculate_group_power())

func setup(main_ref:MainNode, g_ui:GameUI) -> void:
	main = main_ref
	game_ui = g_ui

func setup_stats() -> void:
	max_hp = Utils.get_stat_for_ui("health") + main.bonus_stats.health
	current_hp = max_hp
	current_luck = Utils.get_stat_for_ui("luck") + main.bonus_stats.luck
	base_luck = current_luck
	current_power = Utils.get_stat_for_ui("power") + main.bonus_stats.power
	base_power = current_power

func spawn_grid() -> void:
	my_grid = my_grid_ref.instantiate()
	my_grid.setup(self)
	my_grid.position += PADDING
	add_child(my_grid)

func clear_all_monsters():
	# Free all monster instances
	for monster in monsters:
		if is_instance_valid(monster):
			monster.queue_free()

	# Clear the flat list
	monsters.clear()
	# Clear the grid
	my_grid.clear_all_cells()

	# Update UI
	#game_ui.refresh_monster_data()

func spawn_stage(stage: int, count: int):
	for i in count:
		var base = get_monster_for_stage(stage)
		var cell = my_grid.pick_empty_cell()
		my_grid.spawn_monster_into_cell(cell.x, cell.y, base)

func take_damage(dmg:int=0) -> void:
	game_ui.update_hp_bar(current_hp, max_hp, dmg)
	current_hp -= dmg
	if (current_hp <= 0):
		print("DEAD")
		spawn_summary_panel("you died :(")

func spawn_summary_panel(message:String="mmm!") -> void:
	game_is_active = false
	var panel = summary_panel_ref.instantiate()
	panel.setup(self, main, message)
	main.spawn_to_top_ui_layer(panel)

func register_monster(monster:MonsterInstance): 
	monsters.append(monster)
	monster.died.connect(monster_died)

func monster_died(monster):
	# Remove from flat list
	enemies_killed += 1
	monsters.erase(monster)

	# Remove from grid
	my_grid.clear_monster(monster)
	game_ui.update_monster_damage(calculate_group_power())
	
	check_if_all_monsters_dead()

	# Update UI if needed
	#game_ui.refresh_monster_data()

func prune_dead_monsters(): 
	monsters = monsters.filter(is_instance_valid)

func check_if_all_monsters_dead() -> void:
	if monsters.is_empty():
		# Spawn a victory animation that lasts less than a second, and when that 
		# finishes, then spawn this.
		spawn_summary_panel("Victory!")

func advance_turn():
	if (!game_is_active): return
	prune_dead_monsters() # Safety check for potential bug with a freed instance remaining in array
	check_if_all_monsters_dead()
	runes_used += 1
	group_turns_left -= 1
	print("Advance a turn: ", group_turns_left)
	var incoming_group_power = calculate_group_power()
	if (group_turns_left <= 0):
		apply_group_attack(incoming_group_power)
		group_turns_left = 3
	
	game_ui.update_monster_turns(group_turns_left)
	game_ui.update_monster_damage(incoming_group_power)
	# Handle elites/bosses
	for monster in monsters:
		if (monster.is_elite_or_boss()):
			monster.individual_turns_left -= 1
			if (monster.individual_turns_left <= 0):
				take_damage(monster.base.power)
				#show_elite_attack_feedback(monster)
				monster.individual_turns_left = monster.base.attack_speed
		monster.update_individual_atk_label()
func apply_group_attack(dmg:int= 0) -> void:
	if (dmg > 0):
		%Camera2D.add_shake(30.0)
		take_damage(dmg)
		show_group_attack_feedback(dmg)

func calculate_group_power() -> int:
	var total_power: int = 0
	# Sum power of all NORMAL monsters
	for monster in monsters:
		if not is_instance_valid(monster):
			continue
		if monster.is_elite_or_boss():
			continue
		total_power += monster.base.power
	
	return total_power

# Only if an elite is present.
func calculate_elite_power() -> int:
	var total := 0
	for monster in monsters:
		if is_instance_valid(monster) and monster.is_elite_or_boss():
			if monster.individual_turns_left == 1:
				total += monster.base.power
	return total

func show_group_attack_feedback(_amt: int) -> void:
	# Example: shake screen, flash UI, show damage popup
	pass
	#$ScreenShake.shake(0.2)
	#$UI.show_damage_popup(_amt)

func get_monster_for_stage(stage: int) -> MonsterBase:
	var base_index = stage - 1  # stage 1 = index 0
	var base = MonsterDatabase[selected_monster_family][base_index]

	# Boss logic for stage 4
	if (stage == 4 and randf() < 0.05):
		return MonsterDatabase.boss_orc  # or whatever your boss is

	# Mutation logic
	if (randf() < 0.10 and base_index + 1 < MonsterDatabase[selected_monster_family].size()):
		return MonsterDatabase[selected_monster_family][base_index + 1]

	return base

######################
########### RUNE STUFF
######################
func on_cell_tapped(row, col) -> void:
	if (!game_is_active): return
	damage_plus(row, col)
	advance_turn()
	#var rune = player.get_selected_rune()
#
	#match rune.area_type:
		#"single":
			#damage_single(row, col)
		#"plus":
			#damage_plus(row, col)
		#"aoe3":
			#damage_3x3(row, col)

func damage_cell(r: int, c: int) -> int:
	var xp_gained := 0
	if !(my_grid.is_valid(r, c)): return 0
	
	spawn_rune_explosion(r, c)
	var monster = my_grid.cells[r][c]
	if (is_instance_valid(monster)):
		var died = monster.take_damage(current_power)
		if (died):
			xp_gained += monster.base.exp_reward
	
	return xp_gained

func spawn_rune_explosion(row: int, col: int):
	var rune = rune_animation.instantiate()
	rune.position = my_grid.grid_to_world(row, col) + Vector2(64, 64)
	my_grid.add_to_rune_container(rune)

func damage_single(r, c) -> void:
	var gained = damage_cell(r, c)
	if (gained > 0): emit_signal("gained_exp", gained)

func damage_plus(row, col) -> void:
	var plus_offsets = [
		Vector2i(0, 0),   # center
		Vector2i(-1, 0),  # up
		Vector2i(1, 0),   # down
		Vector2i(0, -1),  # left
		Vector2i(0, 1)    # right
	]
	var gained = 0
	for offset in plus_offsets:
		var r = row + offset.x
		var c = col + offset.y
		gained += damage_cell(r, c)
	
	if (gained > 0): emit_signal("gained_exp", gained)

func damage_3x3(r, c) -> void:
	var gained = 0
	for dr in range(-1, 2):
		for dc in range(-1, 2):
			gained += damage_cell(r+dr, c+dc)
	
	if (gained > 0): emit_signal("gained_exp", gained)
