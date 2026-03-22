extends Control
class_name MonsterStatusEntry

@export var img:TextureRect
@export var lbl:Label

func setup(i:Texture, turns:int) -> void:
	img.texture = i
	update_label(turns)

func update_label(turns_left:int) -> void:
	lbl.text = str(turns_left)

func delete_animation() -> void:
	var t := create_tween()

	# --- FADE IN + SCALE UP ---
	t.tween_property(self, "scale", Vector2(2.5, 2.5), 0.6)\
	.set_trans(Tween.TRANS_SINE)\
	.set_ease(Tween.EASE_OUT)


	# --- FADE OUT WHILE CONTINUING TO GROW ---
	t.tween_property(self, "scale", Vector2(0, 0), 0.4)\
	.set_trans(Tween.TRANS_CUBIC)\
	.set_ease(Tween.EASE_IN)

	t.parallel().tween_property(self, "modulate:a", 0.0, 0.4)\
	.set_trans(Tween.TRANS_SINE)\
	.set_ease(Tween.EASE_IN)
	t.parallel().tween_property(self, "position:y", position.y + 30.0, 0.4)\
	.set_trans(Tween.TRANS_CUBIC)\
	.set_ease(Tween.EASE_IN)

	# --- DELETE WHEN DONE ---
	t.finished.connect(queue_free)
	# DONT FORGET A VCONTAINER FOR STATUS' 
