# Monster.gd
extends Node2D
class_name MonsterInstance

@export var damage_label:Resource
@export var xp_label:Resource
@onready var hp_label:Label = $Hp
var base: MonsterBase
var current_hp: int
var individual_turns_left:int = 5 # only used by elites/bosses
var is_elite:bool = false
var is_boss:bool = false
var my_grid:MyGrid

signal died
func _ready() -> void:
	hp_label.text = str(current_hp)
	if (is_elite or is_boss):
		update_individual_atk_label()

func setup(monster_base: MonsterBase, grid:MyGrid):
	base = monster_base
	current_hp = base.max_hp
	individual_turns_left = base.attack_speed
	$AnimatedSprite2D.play(base.anim_name)
	$AnimatedSprite2D.offset.y = base.anim_offset_y
	my_grid = grid

func is_elite_or_boss() -> bool:
	return (is_elite or is_boss)

func become_elite():
	is_elite = true
	$AtkIcon.visible = true
	$atk.visible = true
	current_hp = int(current_hp * 1.5)
	base.power = int(base.power * 1.5)
	individual_turns_left = base.attack_speed - 1 # elites attack faster

func update_individual_atk_label() -> void:
	$atk.text = str(individual_turns_left)

func take_damage(dmg:int=1) -> bool:
	spawn_damage_label(dmg)
	current_hp -= dmg
	hp_label.text = str(current_hp)
	animate_hit()
	if (current_hp <= 0):
		emit_signal("died", self)
		spawn_xp_label()
		queue_free() # will be enhanced later
		return true
		
	return false

func spawn_xp_label() -> void:
	var label = xp_label.instantiate()
	
	my_grid.spawn_to_fx_container(label)
	label.global_position = %AnimatedSprite2D.global_position + Vector2(-5, -50)
	label.show_label(base.exp_reward)

func spawn_damage_label(amount: float) -> void:
	var label = damage_label.instantiate()
	my_grid.spawn_to_fx_container(label)

	# Position relative to the wall sprite
	label.global_position = %AnimatedSprite2D.global_position + Vector2(20, 5)

	label.show_label(amount)

func animate_hit() -> void:
	# ANIMATE SIZE
	var tween = create_tween()
	tween.tween_property(%AnimatedSprite2D, "scale", Vector2(3.55, 4.9), 0.05)
	tween.tween_property(%AnimatedSprite2D, "scale", Vector2(4.96,3.63), 0.05)
	tween.tween_property(%AnimatedSprite2D, "scale", Vector2(4.0, 4.0), 0.05)
	
	# ANIMATE WHITE COLOR
	var tween2 := create_tween()
	tween2.tween_property(%AnimatedSprite2D.material, "shader_parameter/active", true, 0.05)
	tween2.tween_property(%AnimatedSprite2D.material, "shader_parameter/active", false, 0.1)
