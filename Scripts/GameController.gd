extends Node2D
class_name GameController

@export var status_message:PackedScene
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
var GENERAL_STARTING_TURNS_LEFT:int = 4
var group_turns_left:int = GENERAL_STARTING_TURNS_LEFT
var monsters := []  # list of MonsterInstance nodes, only used for things like if all monsters are dead. NOT positional reasons

var selected_monster_index:int=1

var PADDING:Vector2 = Vector2(38, 240)
var selected_rune:RuneData

### Stats
var max_hp:int
var current_hp:int
var base_luck:int
var current_luck:int
var current_power:int
var base_power:int
var max_focus:int
var current_focus:int

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
	selected_rune = main.battle_data["selected_runes"][0]

func start_game(restart:bool=false) -> void:
	game_is_active = true
	if (restart):
		clear_all_monsters()
		group_turns_left = max(2, GENERAL_STARTING_TURNS_LEFT) # it will be base - some ascension number
		current_hp = max_hp
		current_focus = max_focus
	spawn_stage(main.battle_data["index"], 10)
	var next_attack = calculate_next_incoming_attack()
	game_ui.update_monster_data(next_attack.turns, next_attack.damage)
	game_ui.update_focus(current_focus)

func setup(main_ref:MainNode, g_ui:GameUI) -> void:
	main = main_ref
	game_ui = g_ui

func setup_stats() -> void:
	max_hp = Utils.get_stat_for_ui("health") + main.bonus_stats.health
	current_hp = max_hp
	max_focus = Utils.get_stat_for_ui("focus") + main.bonus_stats.focus
	current_focus = max_focus
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

func spawn_status_message(died:bool=false, no_focus:bool=false) -> void:
	var msg = Utils.STATUS_MESSAGE_VICTORY
	if (died):
		msg = "You Ded :("
	elif (no_focus):
		msg = "No more focus :("
	
	var lbl = status_message.instantiate() as GameStatusPopup
	lbl.setup(msg)
	lbl.animation_complete.connect(spawn_summary_panel.bind(msg))
	main.spawn_to_top_ui_layer(lbl)

func spawn_summary_panel(message:String="mmm!") -> void:
	game_is_active = false
	var panel = summary_panel_ref.instantiate()
	panel.setup(self, main, message)
	main.spawn_to_top_ui_layer(panel)

func register_monster(monster:MonsterInstance): 
	monsters.append(monster)
	#monster.died.connect(monster_died)

func monster_died(monster):
	# Remove from flat list
	enemies_killed += 1
	monsters.erase(monster)

	# Remove from grid
	my_grid.clear_monster(monster)
	#game_ui.update_monster_damage(calculate_group_power()) # I dont think we want to update this as game ends
	
	var game_over = check_if_all_monsters_dead(false)
	if (game_over): return

	# Update UI if needed
	#game_ui.refresh_monster_data()

func prune_dead_monsters(): 
	monsters = monsters.filter(is_instance_valid)

func check_if_all_monsters_dead(spawn_msg:bool=false) -> bool:
	if monsters.is_empty():
		# Spawn a victory animation that lasts less than a second, and when that 
		# finishes, then spawn this.
		if (spawn_msg): spawn_status_message()
		return true
	return false

func take_damage(dmg:int=0) -> void:
	if (dmg <= 0): return
	%Camera2D.add_shake(30.0)
	game_ui.update_hp_bar(current_hp, max_hp, -dmg)
	current_hp -= dmg
	if (current_hp <= 0):
		spawn_status_message(true)

func heal(amt:int=100) -> void:
	game_ui.update_hp_bar(current_hp, max_hp, amt)
	current_hp += amt
	if (current_hp > max_hp):
		current_hp = max_hp

func apply_group_attack(dmg:int= 0) -> void:
	if (dmg > 0):
		take_damage(dmg)

func advance_turn():
	if !game_is_active: return
	prune_dead_monsters()
	if check_if_all_monsters_dead(true): return
	runes_used += 1
	# 1. Decrement group timer
	group_turns_left -= 1
	# 2. Decrement elite timers FIRST
	for monster in monsters:
		if monster.is_elite_or_boss():
			monster.individual_turns_left -= 1
	
	# 3. Now calculate the next attack using UPDATED timers
	var next_attack = calculate_next_incoming_attack()
	
	# 4. Execute attacks that fire this turn
	if next_attack.turns <= 0:
		match next_attack.source:
			"group":
				apply_group_attack(next_attack.damage)
				group_turns_left = GENERAL_STARTING_TURNS_LEFT
	
			"elite":
				# elite damage will be applied below
				pass
	
			"both":
				apply_group_attack(next_attack.group_damage)
				group_turns_left = GENERAL_STARTING_TURNS_LEFT

	# 5. Apply elite attacks that fire this turn
	for monster in monsters:
		if monster.is_elite_or_boss():
			if monster.individual_turns_left <= 0:
				take_damage(monster.current_power)
				monster.individual_turns_left = monster.base.attack_speed
				
		monster.update_individual_atk_label()
		
	# 6. Recalculate preview AFTER attacks resolve (optional but clean)
	next_attack = calculate_next_incoming_attack()
	# 7. Update UI
	game_ui.update_monster_turns(next_attack.turns)
	game_ui.update_monster_damage(next_attack.damage)
	
	if (current_focus <= 0 and current_hp > 0):
		spawn_status_message(false, true)

func calculate_group_power() -> int:
	var total_power: int = 0
	# Sum power of all NORMAL monsters
	for monster in monsters:
		if not is_instance_valid(monster):
			continue
		if monster.is_elite_or_boss():
			continue
		total_power += monster.current_power
	
	return total_power

func calculate_next_elite_attack() -> Dictionary:
	var best_turns = 1000
	var total_damage = 0

	# First pass: find the soonest elite attack
	for monster in monsters:
		if monster.is_elite_or_boss():
			best_turns = min(best_turns, monster.individual_turns_left)
	# Second pass: sum all elites that attack on that turn
	for monster in monsters:
		if monster.is_elite_or_boss() and monster.individual_turns_left == best_turns:
			total_damage += monster.current_power

	return {
		"turns": best_turns,
		"damage": total_damage,
		"source": "elite"
	}


# This is purely for UI
func calculate_next_incoming_attack() -> Dictionary:
	var elite_turn = calculate_next_elite_attack()
	var monster_group_turns = group_turns_left
	var monster_group_damage = calculate_group_power()
	if (monster_group_damage == 0): monster_group_turns = INF # This means group enemies are dead - elite is alive
	# Compare which attack is sooner
	if (elite_turn.turns < monster_group_turns):
		return elite_turn
	elif (monster_group_turns < elite_turn.turns):
		return {
			"turns": monster_group_turns,
			"damage": monster_group_damage,
			"source": "group"
		}
	else:
		# They attack on the same turn → sum damage
		return {
			"turns": monster_group_turns,
			"damage": monster_group_damage + elite_turn.damage,
			"group_damage": monster_group_damage,
			"source": "both"
		}

func get_monster_for_stage(stage: int) -> MonsterBase:
	var base_index = stage - 1  # stage 1 = index 0
	var selected_monster_family = main.battle_data["family"]
	var base = MonsterDatabase[selected_monster_family][base_index]

	# Boss logic for stage 4
	#if (stage == 4 and randf() < 0.05):
		#return MonsterDatabase.boss_orc

	# Mutation logic
	if (randf() < 0.10 and base_index + 1 < MonsterDatabase[selected_monster_family].size()):
		return MonsterDatabase[selected_monster_family][base_index + 1]

	return base

######################
########### RUNE STUFF
######################
func change_selected_rune(rune:RuneData) -> void:
	selected_rune = rune

func on_cell_tapped(row, col) -> void:
	if (!game_is_active): return
	if (!focus_check(selected_rune)): return
	
	# Here is now where we have to subtract and make checks for focus used
	match selected_rune.pattern:
		"single":
			damage_single(row, col)
		"plus":
			damage_plus(row, col)
		"aoe3":
			damage_3x3(row, col)
	
	advance_turn()


func activate_instant_rune(pressed_rune:RuneData):
	if (!game_is_active): return
	if (!focus_check(pressed_rune)): return
	
	_apply_instant_rune("heal")
	advance_turn()

func focus_check(pressed_rune:RuneData) -> bool:
	if (current_focus < pressed_rune.focus_cost):
		game_ui.shake_mana_icon()
		return false
	
	current_focus -= pressed_rune.focus_cost
	if (pressed_rune.focus_cost > 0): game_ui.update_focus(current_focus)
	return true

#func _apply_instant_rune(rune: RuneData):
func _apply_instant_rune(type: String):
	match type:
		"heal":
			heal(100)
		#"skip_turn":
			#skip_monster_turns(1)
		#"reduce_timers":
			#reduce_all_monster_timers(1)

func damage_cell(r: int, c: int) -> int:
	var xp_gained := 0
	if !(my_grid.is_valid(r, c)): return 0
	
	spawn_rune_explosion(r, c)
	var monster = my_grid.cells[r][c]
	if (is_instance_valid(monster)):
		var died = monster.take_damage(current_power)
		if (died):
			xp_gained += monster.base.exp_reward
			monster_died(monster)
	
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
