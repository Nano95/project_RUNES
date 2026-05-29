extends Control
class_name IconSlideLabel

@export var icon:TextureRect
@export var lbl:Label
var slide_distance:float = -100

func _ready() -> void:
	animate_and_slide()

func setup(txt:String, dist:float, img:Texture) -> void:
	lbl.text = txt
	slide_distance = dist
	if (!img): return
	icon.texture = img

func animate_and_slide() -> void:
	var t := create_tween()
	t.set_trans(Tween.TRANS_BACK)
	t.set_ease(Tween.EASE_OUT)

	# --- Double bounce (scale) ---
	# Start slightly small
	scale = Vector2(0.8, 0.8)

	# Bounce 1
	t.tween_property(self, "scale", Vector2(1.20, 1.20), 0.3)
	t.tween_property(self, "scale", Vector2(0.9, 0.9), 0.3)

	# Bounce 2
	t.tween_property(self, "scale", Vector2(1.1, 1.1), 0.25)
	t.tween_property(self, "scale", Vector2(1.0, 1.0), 0.25)

	# --- Slide + Fade ---
	var final_pos := position.y + slide_distance

	t.parallel().tween_property(self, "position:y", final_pos, 1.4).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN)
	t.parallel().tween_property(self, "modulate:a", 0.0, .5).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)

	# Cleanup
	t.tween_callback(queue_free)
