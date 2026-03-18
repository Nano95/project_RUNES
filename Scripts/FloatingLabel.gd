extends Control

func set_color(color:Color) -> void:
	$Label.self_modulate = color

func show_label(lbl_text:String, amount: float) -> void:
	z_index = 10
	$Label.text = lbl_text

	# Start small and slightly below the monster
	var starting_position = global_position
	scale = Vector2(0.3, 0.6)

	var tween := create_tween()

	# --- POP-IN ---
	tween.tween_property(self, "scale", Vector2(1.2, 1.2), 0.32)\
		.set_trans(Tween.TRANS_BACK)\
		.set_ease(Tween.EASE_OUT)

	# --- FLOAT UP ---
	tween.parallel().tween_property(self, "global_position", starting_position + Vector2(0.0, amount), 0.85)\
		.set_trans(Tween.TRANS_SINE)\
		.set_ease(Tween.EASE_OUT)

	# --- FADE OUT ---
	tween.parallel().tween_property(self, "modulate:a", 0.0, 0.85)\
		.set_trans(Tween.TRANS_SINE)\
		.set_ease(Tween.EASE_IN)

	# --- CLEANUP ---
	tween.tween_callback(queue_free)
