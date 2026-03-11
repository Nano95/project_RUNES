extends Control

func show_label(amount: float, hex_color: String = "ff6969") -> void:
	
	# Convert hex → Color 
	var color = Color("#" + hex_color) 
	$Label.self_modulate = color
	z_index = 10
	$Label.text = str("-", int(amount))

	# Random horizontal drift
	var x_drift = randf_range(-20, 20)
	var starting_position = global_position

	var tween := create_tween()

	# Move upward + sideways
	tween.tween_property(self, "global_position", Vector2(starting_position.x + x_drift, starting_position.y-50), 0.45).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	tween.tween_property(self, "scale", Vector2(0,0), .45).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN)

	# Fade out
	tween.parallel().tween_property(self, "modulate:a", 0.0, 0.25)

	# Cleanup
	tween.tween_callback(self.queue_free)
