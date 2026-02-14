extends Control
class_name GameStatusPopup

signal animation_complete
var my_label:Label
func _ready() -> void:
	popup_message($Label.text)

func setup(message:String) -> void:
	my_label = $Label
	my_label.text = str(message)

func popup_message(message:String) -> void:
	if (message == Utils.STATUS_MESSAGE_VICTORY):
		play_happy_message()
	else:
		play_lose_message()

func play_happy_message() -> void:
	my_label.scale = Vector2.ZERO
	my_label.modulate.a = 0.0

	var tween := create_tween()

	# --- SCALE UP WITH BOUNCE ---
	tween.tween_property(my_label, "scale", Vector2(0.5, 0.5), 0.45)\
		.set_trans(Tween.TRANS_BOUNCE)\
		.set_ease(Tween.EASE_OUT)

	# --- FADE IN PARALLEL ---
	tween.parallel().tween_property(my_label, "modulate:a", 1.0, 0.35)\
		.set_trans(Tween.TRANS_SINE)\
		.set_ease(Tween.EASE_OUT)

	# --- HOLD FOR A MOMENT ---
	tween.tween_interval(0.6)

	# --- FADE OUT ---
	tween.tween_property(my_label, "modulate:a", 0.0, 0.3)\
		.set_trans(Tween.TRANS_SINE)\
		.set_ease(Tween.EASE_IN)
	tween.parallel().tween_property(my_label, "position:y", my_label.position.y - 200, 0.5) \
		.set_trans(Tween.TRANS_QUAD) \
		.set_ease(Tween.EASE_IN_OUT)

	# --- OPTIONAL CALLBACK ---
	tween.tween_callback(func():
		# Show your summary panel here
		emit_signal("animation_complete")
		queue_free()
	)

func play_lose_message() -> void:
	print("LOSE MSG")
	my_label.scale = Vector2(0.2, 0.2)
	my_label.modulate.a = 0.0

	# Start slightly above
	var start_pos := my_label.position
	my_label.position = start_pos + Vector2(0, -20)

	var tween := create_tween()

	# Fade in slowly
	tween.tween_property(my_label, "modulate:a", 1.0, 0.4) \
		.set_trans(Tween.TRANS_SINE) \
		.set_ease(Tween.EASE_OUT)

	# Slight scale shrink (feels defeated)
	tween.parallel().tween_property(my_label, "scale", Vector2(0.5, 0.5), 0.5) \
		.set_trans(Tween.TRANS_QUAD) \
		.set_ease(Tween.EASE_IN_OUT)

	# Hold briefly
	tween.tween_interval(0.5)
	# Drop downward with a soft ease
	tween.parallel().tween_property(my_label, "position:y", start_pos.y, 0.5) \
		.set_trans(Tween.TRANS_QUAD) \
		.set_ease(Tween.EASE_IN_OUT)
	# Fade out slowly
	tween.tween_property(my_label, "modulate:a", 0.0, 0.4) \
		.set_trans(Tween.TRANS_QUAD) \
		.set_ease(Tween.EASE_IN_OUT)
	tween.parallel().tween_property(my_label, "scale", Vector2(0.0, 0.0), 0.4) \
		.set_trans(Tween.TRANS_QUAD) \
		.set_ease(Tween.EASE_IN_OUT)

	tween.tween_callback(func():
		emit_signal("animation_complete")
		queue_free()
	)
