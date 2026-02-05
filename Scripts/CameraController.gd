extends Camera2D
class_name CameraController

var player
var shake_strength: float = 0.0
var shake_decay: float = 25.0  # how fast the shake fades

func _ready() -> void:
	set_process(false)

func setup(player_ref) -> void:
	player = player_ref
	set_process(true)

func _process(delta: float) -> void:
	#position = Vector2(360, player.position.y)
	if shake_strength > 0.01:
		# random offset each frame
		offset = Vector2(
			randf_range(-shake_strength, shake_strength),
			randf_range(-shake_strength, shake_strength)
		)
		shake_strength = lerp(shake_strength, 0.0, shake_decay * delta)
	else:
		offset = Vector2.ZERO

func add_shake(amount: float) -> void:
	shake_strength += amount
