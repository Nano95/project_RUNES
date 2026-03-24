extends Control
class_name GameController

@export var luck_popup:PackedScene
@export var status_message:PackedScene
@export var monster_instance:Resource # Used in Grid
@export var summary_panel_ref: Resource
@export var my_grid_ref:Resource
@export var xp_label:Resource
@export var rune_animation:Resource
@export var escape_timer:Timer
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

var PADDING:Vector2 = Vector2(44, 225)
var selected_rune:RuneData
var selected_rune_btn_ref:Button

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
var loot_summary:Dictionary
var round_gained_exp:int=0

signal gained_exp

var escape_timer_counter:int = 0
var escape_in_progress:bool = false

var STUN:String = "electric" # KEEP IN SYNC WITH MONSTER INSTANCE 'STUN'

func _ready() -> void:
	%Camera2D.setup(null) # temporary null until i know what i need to do
	setup_stats()
	spawn_grid()
	start_game()
	# OnReady lets turn all of the names into data for the battle rune buttons to work
	#THIS IS THE NEXT THING TO DO
	select_available_rune()

func start_game(restart:bool=false) -> void:
	game_is_active = true
	escape_in_progress = false
	escape_timer_counter = 0
	round_gained_exp = 0
	if (restart):
		clear_all_monsters()
		group_turns_left = max(2, GENERAL_STARTING_TURNS_LEFT) # it will be base - some ascension number
		current_hp = max_hp
		current_focus = max_focus
		heal(1000)
		
	# Max should be 20
	spawn_stage(main.battle_data["index"], (10 + min(10,Utils.get_unlocked_number_of_families())))
	var next_attack = calculate_next_incoming_attack()
	game_ui.update_monster_data(next_attack.turns, next_attack.damage)
	game_ui.update_focus(current_focus)

func setup(main_ref:MainNode, g_ui:GameUI) -> void:
	main = main_ref
	game_ui = g_ui
	game_ui.back_btn.pressed.connect(escape_pressed_behavior)
	escape_timer.timeout.connect(escape_timer_timeout)

func escape_pressed_behavior() -> void:
	if (escape_in_progress):
		return
	escape_in_progress = true
	advance_turn(true)
	escape_timer_counter += 1
	game_ui.disable_back_button(true)
	escape_timer.stop()
	escape_timer.wait_time = 0.3
	escape_timer.call_deferred("start")

func escape_timer_timeout() -> void:
	advance_turn(true)
	escape_timer_counter += 1
	if (escape_timer_counter >= 3):
		escape_timer.stop()
		if (current_hp > 0):
			spawn_status_message(false, false, true)
			return

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

func spawn_status_message(died:bool=false, no_focus:bool=false, escaped:bool=false) -> void:
	if (!game_is_active): return
	var msg = Utils.STATUS_MESSAGE_VICTORY
	var xp_gain:int = current_focus
	var focus_msg:String = "No more focus! Escaping..."
	game_is_active = false
	if (died):
		msg = "You Ded :("
		xp_gain = 0
	elif (no_focus):
		msg = focus_msg
		
		game_is_active = true # Have to do this so that escape behavior will work
	elif(escaped):
		msg = "Escaped! :D"
		@warning_ignore("integer_division")
		xp_gain = int(current_focus/4)
	
	var lbl = status_message.instantiate() as GameStatusPopup
	lbl.setup(msg)
	main.spawn_to_top_ui_layer(lbl)
	if (msg != focus_msg):
		lbl.animation_complete.connect(spawn_summary_panel.bind(msg))
	
	game_ui.update_monster_data(0, 0)
	if (xp_gain > 0):
		var xp_lbl = xp_label.instantiate()
		my_grid.spawn_to_fx_container(xp_lbl)
		xp_lbl.global_position = game_ui.mana_icon.global_position + Vector2(20, 80)
		xp_lbl.show_label("+" + str(xp_gain) + " XP", 20)
		emit_signal("gained_exp", xp_gain)
	
	if (no_focus and !escape_in_progress):
		await get_tree().create_timer(1.0).timeout
		escape_pressed_behavior()

func spawn_summary_panel(message:String="mmm!") -> void:
	game_ui.disable_back_button(false) # Just in case in any scenario
	var panel = summary_panel_ref.instantiate()
	panel.setup(self, main, message)
	main.spawn_to_top_ui_layer(panel)
	

func register_monster(monster:MonsterInstance): 
	monsters.append(monster)

func monster_died(monster):
	# Remove from flat list
	enemies_killed += 1
	main.game_data.enemies_killed += 1
	if (monster.base.name in main.game_data.total_monster_kills):
		main.game_data.total_monster_kills[monster.base.name] += 1
	else:
		main.game_data.total_monster_kills[monster.base.name] = 1
	if (monster.base.name in main.game_data.total_run_monster_kills):
		main.game_data.total_run_monster_kills[monster.base.name] += 1
	else:
		main.game_data.total_run_monster_kills[monster.base.name] = 1
	emit_signal("gained_exp", monster.base.exp_reward)
	round_gained_exp += monster.base.exp_reward
	
	#game_ui.update_monster_damage(calculate_group_power()) # I dont think we want to update this as game ends
	roll_loot(monster.base)
	
	var game_over = check_if_all_monsters_dead(false)
	if (game_over): return # would adding the win game situation here cause it to happen too many times if multiple monsters die from poison at the same time?


func prune_dead_monsters(): # iterate a shallow copy to avoid mutation issues
	for monster in monsters.duplicate():
		if (monster.is_pending_death or monster.is_queued_for_deletion()):
			if monsters.has(monster):
				monsters.erase(monster)
			my_grid.clear_monster(monster)
			monster.queue_free()
				# Remove from grid

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
		emit_signal("gained_exp", -round_gained_exp)
		
		# In case we die while trying to escape
		if (!escape_timer.is_stopped()): escape_timer.stop()

func heal(amt:int=100) -> void:
	game_ui.update_hp_bar(current_hp, max_hp, amt)
	current_hp += amt
	if (current_hp > max_hp):
		current_hp = max_hp

func apply_group_attack(dmg:int= 0) -> void:
	if (dmg > 0):
		take_damage(dmg)

func advance_turn(is_escaping=false):
	if !game_is_active: return
	# Advancing turns should be happening when a rune is used
	if (!is_escaping):
		runes_used += 1
		main.game_data.runes_used += 1
	# 1. Decrement group timer
	group_turns_left -= 1
	
	# 2A. Decrement elite timers FIRST
	for monster in monsters:
		if monster.is_elite_or_boss():
			monster.individual_turns_left -= 1
	# 2B.
	for monster in monsters:
		if monster.is_pending_death or monster.is_queued_for_deletion() or not monster.is_inside_tree():
			continue
		if !(monster.is_pending_death):
			monster.process_status_effect()
	# Remove monsters killed by poison BEFORE attacks
	prune_dead_monsters()
	if check_if_all_monsters_dead(true):
		return
	
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
				if monster.status_effects.has(STUN): # SKIP ATTACK IF STUNNED
					monster.status_effects[STUN]["turns_remaining"] -= 1
					if monster.status_effects[STUN]["turns_remaining"] <= 0:
						monster.status_effects.erase(STUN)
					monster.individual_turns_left = monster.base.attack_speed
					continue
				take_damage(monster.current_power)
				monster.individual_turns_left = monster.base.attack_speed
				
		monster.update_individual_atk_label()

	# 6. Recalculate preview AFTER attacks resolve (optional but clean)
	next_attack = calculate_next_incoming_attack()
	# 7. Update UI
	game_ui.update_monster_turns(next_attack.turns)
	game_ui.update_monster_damage(next_attack.damage)
	
	if (current_focus <= 0 and current_hp > 0 and escape_timer.is_stopped() and !escape_in_progress):
		spawn_status_message(false, true)

func calculate_group_power() -> int:
	var total_power: int = 0
	# Sum power of all NORMAL monsters
	for monster in monsters:
		if not is_instance_valid(monster):
			continue
		if monster.is_elite_or_boss():
			continue
		if monster.status_effects.has(STUN):
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
	#if (monster_group_damage == 0): monster_group_turns = INF # This means group enemies are dead - elite is alive
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

func roll_loot(monster: MonsterBase) -> void:
	# --- ESSENCE (always drops) ---
	var essence_amount := randi_range(monster.min_essence_amount, monster.max_essence_amount)
	main.game_data.current_essences[monster.essence_type] += essence_amount
	main.game_data.total_essences[monster.essence_type] += essence_amount
	
	# Now add loot to notifications and summary loot.
	var essence_key:String = str(monster.essence_type + " essence")
	game_ui.loot_manager.add_loot_from_key(essence_key, essence_amount)
	if !(loot_summary.has(essence_key)):
		loot_summary[essence_key] = 0
	loot_summary[essence_key] += essence_amount
	### --- GOLD (chance-based) ---
	var final_gold_chance = monster.gold_chance + (current_luck * 0.01)
	if (randf() <= (final_gold_chance)):
		var gold_amount := randi_range(monster.min_gold_reward, monster.max_gold_reward)
		main.game_data.current_gold += gold_amount
		main.game_data.total_gold += gold_amount
		
		game_ui.loot_manager.add_loot_from_key("gold", gold_amount)
		if !(loot_summary.has("gold")):
			loot_summary["gold"] = 0
		loot_summary["gold"] += gold_amount
		
	### --- EQUIPMENT (rare) ---
	#if randf() <= monster.equipment_chance and monster.equipment_pool.size() > 0:
		#var item_id := monster.equipment_pool.pick_random()
		#var item := ItemDatabase.generate_item(item_id)
		#main.game_data.add_item_to_inventory(item)
		#loot_panel.add_loot_entry("Found: " + item.name, item_color, true)


######################
########### RUNE STUFF
######################
func change_selected_rune(rune:RuneData, btn:Button=null) -> void:
	selected_rune = rune
	selected_rune_btn_ref = btn

# needed when we start the game
func select_available_rune() -> void:
	if (!main.game_data.selected_battle_runes):
		return
	for rune_name in main.game_data.selected_battle_runes.values():
		if (rune_name == null):
			continue
		
		selected_rune = RuneDatabase.runes[rune_name]
		return

# Also leveraged in the Game_UI Script
func get_modified_rune_cost(rune:RuneData) -> int:
	var base_cost = rune.focus_cost
	var diff = base_power - max_focus
	@warning_ignore("integer_division")
	var adjustment = diff / 10  # floors automatically
	var final_cost = base_cost + adjustment
	return max(1, final_cost)

func focus_check(pressed_rune:RuneData, pressed_btn:Button=null) -> bool:
	var cost:int = get_modified_rune_cost(pressed_rune)
	if (current_focus < cost):
		game_ui.shake_mana_icon()
		return false
	
	var lucky_focus_refund:bool = roll_luck_focus_refund()
	if (lucky_focus_refund):
		if (pressed_btn):
			var pos = pressed_btn.global_position
			pos.x += pressed_btn.size.x/2
			spawn_luck_popup(pos, "Free Focus!")
	else:
		current_focus -= cost
	if (cost > 0): 
		game_ui.update_focus(current_focus)
	return true

func spawn_luck_popup(new_position:Vector2, txt:String) -> void:
	var popup := luck_popup.instantiate()
	popup.global_position = new_position
	popup.setup(txt)
	game_ui.add_child(popup)

func on_cell_tapped(row, col) -> void:
	if (!game_is_active): return
	if (!main.game_data.rune_inv.get(selected_rune.name)): return
	if (!focus_check(selected_rune, selected_rune_btn_ref)): return # This check must go after checking for inventory! Otherwise focus is subtracted when we dont have enough
	# Here is now where we have to subtract and make checks for focus used
	match selected_rune.pattern:
		"strike":
			damage_single(row, col)
		"plus":
			damage_plus(row, col)
		"expl":
			damage_3x3(row, col)
		"cross":
			damage_cross(row, col)
		"diamond":
			damage_diamond(row, col)
	
	var new_qty = main.game_data.remove_rune_from_inv(selected_rune, 1)
	game_ui.update_rune_qty(selected_rune.name, new_qty)
	advance_turn()

# btn parameter is needed to know the position of where we will spawn a label
func activate_instant_rune(pressed_rune:RuneData, btn:Button=null):
	if (!game_is_active): return
	if (!main.game_data.rune_inv.get(pressed_rune.name)): return
	if (!focus_check(pressed_rune, btn)): return
	var lbl_pos:Vector2=Vector2.ZERO
	if (btn):
		lbl_pos = btn.global_position + btn.size/2
	_apply_instant_rune(pressed_rune.pattern, lbl_pos)
	var new_qty = main.game_data.remove_rune_from_inv(pressed_rune, 1)
	game_ui.update_rune_qty(pressed_rune.name, new_qty)
	advance_turn()

func _apply_instant_rune(type: String, lbl_position:Vector2):
	var base_heal:int = 0
	match type:
		"light_heal":
			base_heal = 10
		"great_heal":
			base_heal = 25
		#"reduce_timers":
			#reduce_all_monster_timers(1)
	var percent:float = max_focus * 0.01
	var bonus:int = int(ceil(base_heal * percent))
	heal(base_heal + bonus)
	
	if (lbl_position != Vector2.ZERO):
		var heal_lbl = xp_label.instantiate()
		game_ui.add_child(heal_lbl)
		heal_lbl.global_position = lbl_position
		heal_lbl.show_label("+" + str(base_heal + bonus), -100)
		heal_lbl.set_color(Utils.PASTEL_GREEN)

func damage_cell(r: int, c: int) -> void:
	if !(my_grid.is_valid(r, c)): return
	
	spawn_rune_explosion(r, c)
	var monster = my_grid.cells[r][c]
	if (is_instance_valid(monster)):
		var mult:float = get_element_multiplier(selected_rune.rune_type, monster)
		# Earth runes deal slightly less direct damage 
		match selected_rune.rune_type:
			"earth": # Earth magic has the DoT ability
				mult *= 0.75
			"electric": # Stuns
				mult *= .8
		var dmg:int = int(current_power * mult)
		# Apply poison if rune is poison
		var crit_hit:bool=false
		match selected_rune.rune_type:
			"arcane": # Arcane magic has the ability to Critical strike
				var crit_chance := get_crit_chance(current_luck)
				if randf() < crit_chance:
					dmg = int(dmg * 1.5)  # or 2.0, or a formula
					crit_hit = true
				
			"earth": # Earth magic has the DoT ability
				var poison_dmg = int(current_power * 0.15)
				monster.apply_poison(poison_dmg, 4)
			"electric":
				#make it 100% for now to test
				var stun_chance := 0.3 + (current_luck * .02)
				if randf() < stun_chance:
					var duration:int = 3
					monster.apply_stun(duration)
		monster.take_damage(dmg, selected_rune.rune_type, crit_hit)

func spawn_rune_explosion(row: int, col: int):
	var rune = rune_animation.instantiate()
	rune.setup(selected_rune.rune_type)
	rune.position = my_grid.grid_to_world(row, col)
	my_grid.add_to_rune_container(rune)

func damage_single(r, c) -> void:
	damage_cell(r, c)

func damage_plus(row, col) -> void:
	var plus_offsets = [
		Vector2i(0, 0),   # center
		Vector2i(-1, 0),  # up
		Vector2i(1, 0),   # down
		Vector2i(0, -1),  # left
		Vector2i(0, 1)    # right
	]
	for offset in plus_offsets:
		var r = row + offset.x
		var c = col + offset.y
		damage_cell(r, c)

func damage_3x3(r, c) -> void:
	for dr in range(-1, 2):
		for dc in range(-1, 2):
			damage_cell(r+dr, c+dc)

func damage_diamond(r: int, c: int) -> void:
	var offsets = [
		Vector2i(-2, 0),
		Vector2i(-1, -1), Vector2i(-1, 1),
		Vector2i(0, -2), Vector2i(0, 0), Vector2i(0, 2),
		Vector2i(1, -1), Vector2i(1, 1),
		Vector2i(2, 0)
	]

	for off in offsets:
		damage_cell(r + off.x, c + off.y)

func damage_cross(r: int, c: int) -> void:
	var offsets = [
		Vector2i(-1, -1), Vector2i(-1, 1),
		Vector2i(0, 0),
		Vector2i(1, -1), Vector2i(1, 1)
	]

	for off in offsets:
		damage_cell(r + off.x, c + off.y)

func roll_luck_focus_refund() -> bool:
	#var chance := current_luck * 75 
	var chance := current_luck * 0.15  # 10=1.5%|20=3.0%|30=4.5%|40=6.0%|50=7.5%
	var roll := randf() * 100.0

	if (roll <= chance):
		return true
	return false

func get_element_multiplier(rune_element: String, monster) -> float:
	if rune_element in monster.base.immunities:
		return 0.0
	if rune_element in monster.base.weaknesses:
		return 1.5
	if rune_element in monster.base.resistances:
		return 0.5
	return 1.0

func get_crit_chance(luck: int) -> float:
	var max_crit := 0.35
	var k := 30.0
	return max_crit * (luck / (luck + k))
