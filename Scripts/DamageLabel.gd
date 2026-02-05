extends Control

func show_label(amount: float) -> void:
	z_index = 10
	$Label.text = str("-", amount)

	# Random horizontal drift
	var x_drift = randf_range(-20, 20)
	position = Vector2(-25, -100)

	var tween := create_tween()

	# Move upward + sideways
	tween.tween_property(self, "position", Vector2(position.x + x_drift, -160), 0.45).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	tween.tween_property(self, "scale", Vector2(0,0), .45).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN)

	# Fade out
	tween.parallel().tween_property(self, "modulate:a", 0.0, 0.25)

	# Cleanup
	tween.tween_callback(self.queue_free)
