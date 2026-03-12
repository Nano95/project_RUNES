extends Control
class_name InfoPopup

@export var ctrl:Control
@export var lbl:Label

var duration := 4.0  # seconds
var rise_distance := 180  # pixels upward

func show_info(info:String) -> void:
	lbl.text = info
	print("INFO Pop up ", info)
	# Start animation
	animate_popup()

func animate_popup() -> void:
	var tween := create_tween()

	# Move upward
	tween.tween_property(ctrl, "global_position:y", global_position.y - rise_distance, duration - (duration*.3)).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_CUBIC)

	# Fade out
	tween.parallel().tween_property(lbl, "modulate:a", 0.0, duration + .5)

	# Free when done
	tween.tween_callback(Callable(self, "queue_free"))
