extends Control
class_name GameUI

@onready var rune_button: PackedScene = preload("res://Scenes/BattleRuneButton.tscn")

var main:MainNode
var game_controller:GameController
@export var back_btn:Button
@export var hp_bar:TextureProgressBar
@export var xp_bar:TextureProgressBar
@export var hp_label:Label
@export var xp_label:Label
@export var monster_turns:Label
@export var monster_damage:Label
@export var rune_btns_container:HBoxContainer
@export var mana_icon:TextureRect
@export var focus_label:Label
@export var loot_manager:LootManager
var BAR_CONST:float = 1000.0
var hp_tween:Tween
var xp_tween:Tween
var dmg_tween:Tween
var focus_tween:Tween
var turns_tween:Tween

func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE

func setup(main_node:MainNode) -> void:
	main = main_node

func setup_game_controller(gc:GameController) -> void:
	game_controller = gc
	$TopSection/QuickRespawn.pressed.connect(restart)
	setup_hp(game_controller.current_hp, game_controller.max_hp)
	xp_bar.setup(main, game_controller)
	setup_rune_buttons()

func setup_rune_buttons() -> void:
	if !(is_instance_valid(game_controller)): return
	for rune in main.battle_data["selected_runes"]:
		var btn = rune_button.instantiate()
		btn.setup(rune)
		if (rune.activation == "grid"):
			btn.pressed.connect(game_controller.change_selected_rune.bind(rune))
		else:
			btn.pressed.connect(game_controller.activate_instant_rune.bind(rune))
			
		rune_btns_container.add_child(btn)
		
	#$BottomSection/MarginContainer/ScrollContainer/HBoxContainer/RuneButton1.pressed.connect(game_controller.change_selected_rune.bind("single"))
	#$BottomSection/MarginContainer/ScrollContainer/HBoxContainer/RuneButton2.pressed.connect(game_controller.change_selected_rune.bind("plus"))
	#$BottomSection/MarginContainer/ScrollContainer/HBoxContainer/RuneButton3.pressed.connect(game_controller.change_selected_rune.bind("aoe3"))
	#$BottomSection/MarginContainer/ScrollContainer/HBoxContainer/RuneButton4.pressed.connect(game_controller.activate_instant_rune)

func setup_hp(player_hp:float, player_max_hp:float) -> void:
	hp_bar.max_value = BAR_CONST
	@warning_ignore("integer_division")
	hp_bar.value = (player_hp / player_max_hp) * BAR_CONST
	hp_bar.tint_progress = get_health_color(player_hp / player_max_hp)
	update_hp_bar(player_hp, player_max_hp, 0)

#func update_hp_bar(hp:float, max_hp:float, amt:int=0) -> void:
	#@warning_ignore("integer_division")
	#var ratio = float(hp) / float(max_hp)
	#var from_percent: float = ratio * BAR_CONST
	#@warning_ignore("integer_division")
	#var to_percent: float = ((float(hp) + float(amt)) / float(max_hp)) * BAR_CONST
	#
	#var color: Color = get_health_color(ratio)
	#if (amt > 0):
		#hp_bar.tint_progress = Color.WHITE
		#tween_hp_bar(from_percent, to_percent, color)
	#
	#hp = clamp(hp + amt, 0, max_hp)
	#hp_label.text = str(hp)

func update_hp_bar(current_hp: float, max_hp: float, delta: float) -> void:
	# delta > 0 = heal, delta < 0 = damage

	var old_hp := current_hp
	var new_hp:float = clamp(current_hp + delta, 0, max_hp)

	# Percentages for tween
	var from_ratio:float = old_hp / max_hp
	var to_ratio:float = new_hp / max_hp

	var from_percent:float = from_ratio * BAR_CONST
	var to_percent:float = to_ratio * BAR_CONST

	# Color based on NEW ratio (optional: use old if you prefer)
	var color: Color = get_health_color(to_ratio)

	if delta != 0:
		hp_bar.tint_progress = Color.WHITE
		tween_hp_bar(from_percent, to_percent, color)

	hp_label.text = str(new_hp)

func restart() -> void:
	game_controller.spawn_stage(game_controller.selected_monster_index, 5)

func update_stair_level_label() -> void:
	%Level.text = "Level: " + str(main.game_current_level)

func update_timer_label(time_left:float=10.0) -> void:
	$TopSection/Time.text = "Time: " + str(time_left)

func update_monster_data(turns:int, power:int) -> void:
	monster_turns.text = str(turns)
	monster_damage.text = str(power)

func update_monster_turns(turns:int) -> void:
	#var prev_turns:int = monster_turns.text.to_int()
	## Animate
	#if (prev_turns == turns): return
	monster_turns.text = str(turns)
	# Scale based on urgency (closer to 1 = bigger)
	var danger_scale = 0.3 + (.7 / max(turns, 1)) * 0.5
	# Start slightly smaller so the tween pops it up
	monster_turns.scale = Vector2(danger_scale, danger_scale)
	if (turns_tween and turns_tween.is_running()): turns_tween.kill()
	turns_tween = create_tween()
	turns_tween.tween_property(monster_turns, "scale", Vector2(.3, .3), 0.4)\
		.set_trans(Tween.TRANS_CUBIC)

func update_monster_damage(power:int) -> void:
	var prev_dmg:int = monster_damage.text.to_int()
	if (prev_dmg == power): return
	monster_damage.text = str(power)
	# Animate
	if (dmg_tween and dmg_tween.is_running()): dmg_tween.kill()
	monster_damage.scale = Vector2(.4, .4)
	dmg_tween = create_tween()
	dmg_tween.tween_property(monster_damage, "scale", Vector2(.3, .3), 0.4)\
		.set_trans(Tween.TRANS_CUBIC)

func shake_mana_icon() -> void:
	Utils.warn_shake_node(mana_icon)

func update_focus(focus:int) -> void:
	var prev_focus:int = focus_label.text.to_int()
	if (prev_focus == focus): return
	focus_label.text = str(focus)
	# Animate
	if (focus_tween and focus_tween.is_running()): focus_tween.kill()
	focus_label.scale = Vector2(.4, .4)
	focus_tween = create_tween()
	focus_tween.tween_property(focus_label, "scale", Vector2(.3, .3), 0.4)\
		.set_trans(Tween.TRANS_CUBIC)

func tween_hp_bar(from: float, to: float, clr:Color) -> void:
	hp_bar.value = from  # explicitly set the start
	hp_tween = create_tween()
	hp_tween.tween_property(hp_bar, "value", to, 0.1)
	hp_tween = create_tween()
	hp_tween.tween_property(hp_bar, "tint_progress", clr, 0.1)

func get_health_color(ratio: float) -> Color:
	if ratio > 0.75:
		return Utils.HP_GREEN
	elif ratio > 0.25:
		return Utils.HP_YELLOW
	else:
		return Utils.RED

func disable_back_button(is_disabled:bool=false) -> void:
	back_btn.disabled = is_disabled
