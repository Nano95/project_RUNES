extends Node2D
class_name LuckPopup

var sprite_size:Vector2 = Vector2.ZERO
func _ready() -> void:
	animate_me()

func setup(txt:String="") -> void:
	%Label.text = txt
	sprite_size = $Sprite.size

func animate_me() -> void:
	var rise_distance := 40.0
	var duration := 1.2
	var tween := create_tween()

	# Start small and invisible
	scale = Vector2(0.6, 0.6)
	modulate.a = 0.0

	# PHASE 1 — Pop in (overshoot)
	tween.tween_property(self, "scale", Vector2(1.8, 1.8), 0.38)\
		.set_trans(Tween.TRANS_BOUNCE)\
		.set_ease(Tween.EASE_OUT)

	tween.parallel().tween_property(self, "modulate:a", 1.0, 0.18)

	# PHASE 2 — Bounce down to normal size
	tween.tween_property(self, "scale", Vector2(1.5, 1.5), 0.52)\
		.set_trans(Tween.TRANS_BOUNCE)\
		.set_ease(Tween.EASE_OUT)

	# PHASE 3 — Float upward + fade out
	tween.parallel().tween_property(self, "position:y", position.y - rise_distance, duration)\
		.set_trans(Tween.TRANS_CUBIC)\
		.set_ease(Tween.EASE_OUT)

	tween.parallel().tween_property(self, "modulate:a", 0.0, duration)

	tween.tween_callback(queue_free)
