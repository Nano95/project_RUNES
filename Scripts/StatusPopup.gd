extends Node2D
class_name MonsterStatusPopup

func animate_me(status_image: Texture) -> void:
	$Sprite2D.texture = status_image

	# Start small and invisible
	$Sprite2D.scale = Vector2(0.5, 0.5)
	$Sprite2D.modulate.a = 0.0

	var t := create_tween()

	# --- FADE IN + SCALE UP ---
	t.tween_property($Sprite2D, "scale", Vector2(2.7, 2.7), 0.6)\
	.set_trans(Tween.TRANS_SINE)\
	.set_ease(Tween.EASE_OUT)

	t.parallel().tween_property($Sprite2D, "modulate:a", 1.0, 0.3)\
	.set_trans(Tween.TRANS_SINE)\
	.set_ease(Tween.EASE_OUT)

	# --- FADE OUT WHILE CONTINUING TO GROW ---
	t.tween_property($Sprite2D, "scale", Vector2(1.2, 1.2), 0.4)\
	.set_trans(Tween.TRANS_CUBIC)\
	.set_ease(Tween.EASE_IN)

	t.parallel().tween_property($Sprite2D, "modulate:a", 0.0, 0.4)\
	.set_trans(Tween.TRANS_SINE)\
	.set_ease(Tween.EASE_IN)

	# --- DELETE WHEN DONE ---
	t.finished.connect(queue_free)
	# DONT FORGET A VCONTAINER FOR STATUS' 
