# Monster.gd
extends Node2D
class_name MonsterInstance

@export var damage_label:Resource
@export var xp_label:Resource
@onready var hp_label:Label = $Hp
var base: MonsterBase
var current_hp: int
var individual_turns_left:int = 5 # only used by elites/bosses
var current_power:int=1
var is_elite:bool = false
var is_boss:bool = false
var my_grid:MyGrid
var status_effects = {
	#"poison": {
		#"damage_per_tick": 0,
		#"turns_remaining": 0
	#}
}
var POISON:String = "earth"
var STUN:String = "electric"
var dmg_color:Dictionary = {
	"arcane": "ff6969",
	"earth": "bbff69",
	"electric": "ffde42"
}
var is_pending_death:bool=false

signal died
func _ready() -> void:
	hp_label.text = str(current_hp)
	if (is_elite or is_boss):
		update_individual_atk_label()

func setup(monster_base: MonsterBase, grid:MyGrid):
	base = monster_base
	current_hp = base.max_hp
	current_power = base.power
	individual_turns_left = base.attack_speed
	$AnimatedSprite2D.play(base.anim_name)
	#$AnimatedSprite2D.offset.y = base.anim_offset_y
	my_grid = grid

func is_elite_or_boss() -> bool:
	return (is_elite or is_boss)

func become_elite():
	is_elite = true
	$AtkIcon.visible = true
	$atk.visible = true
	current_hp = int(current_hp * 1.5)
	current_power = int(base.power * 1.5)
	individual_turns_left = base.attack_speed - 1 # elites attack faster

func update_individual_atk_label() -> void:
	$atk.text = str(individual_turns_left)

func take_damage(dmg:int=1, dmg_color_type:String="arcane", crit_hit:bool=false) -> bool:
	spawn_damage_label(dmg, dmg_color_type, crit_hit)
	current_hp -= dmg
	hp_label.text = str(current_hp)
	animate_hit()
	if (current_hp <= 0):
		is_pending_death = true
		emit_signal("died")
		spawn_xp_label()
		return true
	return false

func spawn_xp_label() -> void:
	var label = xp_label.instantiate()
	
	my_grid.spawn_to_fx_container(label)
	label.global_position = %AnimatedSprite2D.global_position + Vector2(-5, 50)
	label.show_label("+" + str(base.exp_reward) + " XP", 20.0)

func spawn_damage_label(amount: float, dmg_color_type:String="arcane", crit_hit:bool=false) -> void:
	var label = damage_label.instantiate()
	my_grid.spawn_to_fx_container(label)

	# Position relative to the wall sprite
	label.global_position = %AnimatedSprite2D.global_position  + Vector2(-35, -50)

	label.show_label(amount, dmg_color[dmg_color_type], crit_hit)

func apply_poison(dmg:int, turns:int) -> void:
	if (status_effects.has(POISON)):
		status_effects[POISON]["damage_per_tick"] += dmg
		status_effects[POISON]["turns_remaining"] += turns
	else:
		status_effects[POISON] = {"damage_per_tick": dmg, "turns_remaining": turns }

	#add_status_icon(POISON) # optional # it should be a Vcontainer 

func process_status_effect() -> void:
	if (status_effects.has(POISON)):
		if (status_effects[POISON]["turns_remaining"] > 0):
			take_damage(status_effects[POISON]["damage_per_tick"], POISON)
			status_effects[POISON]["turns_remaining"] -= 1
			if (status_effects[POISON]["turns_remaining"] <= 0):
				status_effects.erase(POISON)
				#remove_status_icon(POISON)

func animate_hit() -> void:
	# ANIMATE SIZE
	var tween = create_tween()
	tween.tween_property(%AnimatedSprite2D, "scale", Vector2(4.25, 7.4), 0.07)
	tween.tween_property(%AnimatedSprite2D, "scale", Vector2(7.2, 2.63), 0.05)
	tween.tween_property(%AnimatedSprite2D, "scale", Vector2(4.0, 4.0), 0.05)
	
	# ANIMATE WHITE COLOR
	var tween2 := create_tween()
	tween2.tween_property(%AnimatedSprite2D.material, "shader_parameter/active", true, 0.05)
	tween2.tween_property(%AnimatedSprite2D.material, "shader_parameter/active", false, 0.1)
