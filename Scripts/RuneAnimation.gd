extends Node2D
class_name RuneAnimation

@export var p_arcane:PackedScene
@export var p_fire:PackedScene
@export var p_ice:PackedScene
@export var p_earth:PackedScene
@export var p_electric:PackedScene
var particle_scenes:Dictionary = {
	"fire": null,
	"ice": null,
	"arcane": null,
	"electric": null,
	"earth": null,
}
var should_spawn:bool = true
var anim_name:String = "arcane"
var grid:MyGrid

func _ready() -> void:
	$AnimatedSprite2D.play(anim_name)
	$AnimatedSprite2D.animation_finished.connect(queue_free)
	if (should_spawn):
		particle_scenes = {
			"fire": p_fire,
			"ice": p_ice,
			"arcane": p_arcane,
			"electric": p_electric,
			"earth": p_earth,
		}
		
		spawn_particles()

func setup(an_name:String, spawn:bool, grid_parent) -> void:
	anim_name = an_name
	should_spawn = spawn
	grid = grid_parent

func spawn_particles() -> void:
	if (particle_scenes.has(anim_name)):
		print("ATTEMPT SPAWN")
		var p = particle_scenes[anim_name].instantiate()
		p.position = position 
		grid.spawn_to_fx_container(p)
