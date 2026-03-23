# Monster.gd
extends Node2D
class_name MonsterInstance

@onready var hp_label:Label = $Hp
@export var status_popup_ref:Resource
@export var status_entry:Resource
@export var damage_label:Resource
@export var xp_label:Resource
@export var STUN_ICON:Texture
@export var POISON_ICON:Texture
@export var status_container:VBoxContainer

var POISON:String = "earth"
var STUN:String = "electric" # KEEP IN SYNC WITH GAME CONTROLLER
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
	#"stun": 0
}

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
		spawn_status(POISON)
		status_effects[POISON] = {"damage_per_tick": dmg, "turns_remaining": turns }

	var entry = add_or_update_status(
		POISON,
		POISON_ICON,
		turns
	)
	status_effects[POISON]["ui_entry"] = entry

 #Change color of stun so that i can validate this working
func apply_stun(turns: int) -> void:
	# If already stunned, refresh or extend — your choice
	if (!status_effects.has(STUN)):
		spawn_status(STUN)
		status_effects[STUN] = {
			"turns_remaining": turns,
		}
	else:
		status_effects[STUN]["turns_remaining"] = max(
			status_effects[STUN]["turns_remaining"], 
			turns
		)

	# Create or update UI entry
	var entry = add_or_update_status(
		STUN, 
		STUN_ICON, 
		status_effects[STUN]["turns_remaining"]
	)
	status_effects[STUN]["ui_entry"] = entry

func process_status_effect() -> void:
	if (status_effects.has(POISON)):
		if (status_effects[POISON]["turns_remaining"] > 0):
			take_damage(status_effects[POISON]["damage_per_tick"], POISON)
			status_effects[POISON]["turns_remaining"] -= 1
			if (status_effects[POISON].has("ui_entry") and status_effects[POISON]["ui_entry"] is MonsterStatusEntry):
				status_effects[POISON]["ui_entry"].update_label(status_effects[POISON]["turns_remaining"])
			if (status_effects[POISON]["turns_remaining"] <= 0):
				if (status_effects[POISON].has("ui_entry")):
					status_effects[POISON]["ui_entry"].delete_animation()
				status_effects.erase(POISON)
	
	if (status_effects.has(STUN)):
		status_effects[STUN]["turns_remaining"] -= 1
		if (status_effects[STUN].has("ui_entry") and status_effects[STUN]["ui_entry"] is MonsterStatusEntry):
			status_effects[STUN]["ui_entry"].update_label(status_effects[STUN]["turns_remaining"])
		if (status_effects[STUN]["turns_remaining"] <= 0):
			if (status_effects[STUN].has("ui_entry")):
				status_effects[STUN]["ui_entry"].delete_animation()
			status_effects.erase(STUN)

func spawn_status(type:String) -> void:
	var status = status_popup_ref.instantiate() as MonsterStatusPopup
	add_child(status)
	match type:
		POISON:
			status.animate_me(POISON_ICON)
		STUN:
			status.animate_me(STUN_ICON)
		_:
			pass

func add_or_update_status(status_name: String, icon: Texture, turns: int) -> MonsterStatusEntry:
	var entry:MonsterStatusEntry
	if (status_effects.has(status_name) and status_effects[status_name].has("ui_entry")):
		entry = status_effects[status_name]["ui_entry"] as MonsterStatusEntry
		entry.update_label(turns)
		return entry

	# Create new entry
	entry = status_entry.instantiate() as MonsterStatusEntry
	entry.setup(icon, turns)
	status_container.add_child(entry)
	status_effects[status_name]["ui_entry"] = entry
	return entry

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
