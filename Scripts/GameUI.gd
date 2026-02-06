extends Control
class_name GameUI

var main:MainNode
var game_controller:GameController

@export var hp_bar:TextureProgressBar
@export var xp_bar:TextureProgressBar
@export var hp_label:Label
@export var xp_label:Label
@export var monster_turns:Label
@export var monster_damage:Label
var BAR_CONST:float = 1000.0
var hp_tween:Tween
var xp_tween:Tween

func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE

func setup(main_node:MainNode) -> void:
	main = main_node

func setup_game_controller(gc:GameController) -> void:
	game_controller = gc
	$TopSection/QuickRespawn.pressed.connect(restart)
	# Escaping should simulate 3 turns. potential for you to get hit and die
	$TopSection/BackBtn.pressed.connect(game_controller.spawn_summary_panel.bind("Escaped safely!"))
	setup_hp(game_controller.current_hp, game_controller.max_hp)
	xp_bar.setup(main, game_controller)

func setup_hp(player_hp:float, player_max_hp:float) -> void:
	hp_bar.max_value = BAR_CONST
	@warning_ignore("integer_division")
	hp_bar.value = (player_hp / player_max_hp) * BAR_CONST
	hp_bar.tint_progress = get_health_color(player_hp / player_max_hp)
	update_hp_bar(player_hp, player_max_hp, 0)

func update_hp_bar(hp:float, max_hp:float, damage:int=0) -> void:
	@warning_ignore("integer_division")
	var ratio = float(hp) / float(max_hp)
	var from_percent: float = ratio * BAR_CONST
	@warning_ignore("integer_division")
	var to_percent: float = ((float(hp) - float(damage)) / float(max_hp)) * BAR_CONST
	
	var color: Color = get_health_color(ratio)
	if (damage > 0):
		hp_bar.tint_progress = Color.WHITE
		tween_hp_bar(from_percent, to_percent, color)
	
	hp_label.text = str(hp - damage)

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
	var prev_turns:int = monster_turns.text.to_int()
	monster_turns.text = str(turns)
	# Animate
	if (prev_turns == turns): return
	# Scale based on urgency (closer to 1 = bigger)
	var danger_scale = 0.3 + (.7 / max(turns, 1)) * 0.5
	# Start slightly smaller so the tween pops it up
	monster_turns.scale = Vector2(danger_scale, danger_scale)
	#monster_turns.scale = Vector2(.4, .4) / (turns * 2)
	var dmg_tween = create_tween()
	dmg_tween.tween_property(monster_turns, "scale", Vector2(.3, .3), 0.4)\
		.set_trans(Tween.TRANS_CUBIC)

func update_monster_damage(power:int) -> void:
	var prev_dmg:int = monster_damage.text.to_int()
	#print("prev: ", prev_dmg)
	#print("incoming: ", power)
	monster_damage.text = str(power)
	if (prev_dmg == power): return
	# Animate
	monster_damage.scale = Vector2(.4, .4)
	var dmg_tween = create_tween()
	dmg_tween.tween_property(monster_damage, "scale", Vector2(.3, .3), 0.4)\
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
