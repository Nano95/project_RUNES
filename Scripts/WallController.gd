extends Node2D
class_name WallController

var FloatingLabel := preload("res://Scenes/DamageLabel.tscn")
@export var p_bar: TextureProgressBar

var max_health: float
var health:float = 20
var bump_damage:float = 0.0
var player_attack: float = 4.0

signal wall_destroyed # can potentially emit arguments of loot as well

func _ready() -> void:
	$Timer.timeout.connect(get_hit)
	p_bar.max_value = 1.0
	p_bar.value = (health / max_health)
	p_bar.modulate.a = 0.0

func setup(data: Dictionary) -> void:
	health = data.hp
	max_health = health
	player_attack = data.player_attack
	$Timer.wait_time = data.player_attack_speed

func get_hit() -> void:
	health -= player_attack
	print("HIT: ", player_attack," hp: :", health)
	
	# Spawn floating damage label
	spawn_damage_label(player_attack)
	if (health <= 0):
		emit_signal("wall_destroyed")
		queue_free()
		return
	
	# PROG BAR
	if (p_bar.modulate.a == 0.0):
		var fade := create_tween()
		fade.tween_property(p_bar, "modulate:a", 1.0, 0.15)
	var ratio: float = clamp(health / max_health, 0.0, 1.0)
	p_bar.tint_progress = get_hp_color(ratio)
	var tween1 = create_tween()
	tween1.tween_property(p_bar, "value", ratio, 0.1).set_trans(Tween.TRANS_SINE)
	
	# ANIMATE SIZE
	var tween = create_tween()
	tween.tween_property(%Sprite2D, "scale", Vector2(0.95, 1.1), 0.05)
	tween.tween_property(%Sprite2D, "scale", Vector2(1.06, .93), 0.05)
	tween.tween_property(%Sprite2D, "scale", Vector2(1.0, 1.0), 0.05)
	
	# ANIMATE WHITE COLOR
	var tween2 := create_tween()
	tween2.tween_property(%Sprite2D.material, "shader_parameter/active", true, 0.05)
	tween2.tween_property(%Sprite2D.material, "shader_parameter/active", false, 0.1)

func begin_attack() -> void:
	get_hit() # Quick first hit
	$Timer.start(.3) # TODO: This number will change based on stats later

func spawn_damage_label(amount: float) -> void:
	var label = FloatingLabel.instantiate()
	add_child(label)

	# Position relative to the wall sprite
	label.global_position = %Sprite2D.global_position

	label.show_damage(amount)

func get_hp_color(ratio: float) -> Color:
	var hue = ratio * 0.33  # green → yellow → red
	return Color.from_hsv(hue, 0.8, 1.0)
