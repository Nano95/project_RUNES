extends Control
class_name Whiteout

@onready var whiteout:TextureRect = $TextureRect

var starting_color:Color = Color(1, 0, 0, .3)
func _ready() -> void:
	whiteout.self_modulate = starting_color
	fade_away()

func setup(col:Color=starting_color) -> void:
	starting_color = col

func fade_away() -> void:
	var t := create_tween()
	t.set_trans(Tween.TRANS_SINE)
	t.set_ease(Tween.EASE_OUT)

	# Optional: tiny fade-in pop (makes it feel snappier)
	whiteout.self_modulate.a = 0.0
	t.tween_property(whiteout, "self_modulate:a", starting_color.a, 0.05)

	# Fade out
	t.tween_property(whiteout, "self_modulate:a", 0.0, 0.15)

	# Cleanup
	t.tween_callback(self.queue_free)
