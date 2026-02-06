extends Control

func show_label(amount: float) -> void:
	z_index = 10
	$Label.text = str("-", int(amount))

	# Random horizontal drift
	var x_drift = randf_range(-20, 20)
	var starting_position = global_position
	position = starting_position + Vector2(-90, -420)

	var tween := create_tween()

	# Move upward + sideways
	tween.tween_property(self, "global_position", Vector2(global_position.x + x_drift, global_position.y-50), 0.45).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	tween.tween_property(self, "scale", Vector2(0,0), .45).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN)

	# Fade out
	tween.parallel().tween_property(self, "modulate:a", 0.0, 0.25)

	# Cleanup
	tween.tween_callback(self.queue_free)
