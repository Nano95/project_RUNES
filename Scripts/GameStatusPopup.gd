extends Control
class_name GameStatusPopup

signal animation_complete
func _ready() -> void:
	popup_message($Label.text)

func setup(message:String) -> void:
	$Label.text = str(message)

func popup_message(message:String) -> void:
	if (message == Utils.STATUS_MESSAGE_VICTORY):
		play_happy_message()
	else:
		play_lose_message()

func play_happy_message() -> void:
	print("WIN MSG!")
	scale = Vector2.ZERO
	modulate.a = 0.0

	var tween := create_tween()

	# --- SCALE UP WITH BOUNCE ---
	tween.tween_property(self, "scale", Vector2(0.5, 0.5), 0.45)\
		.set_trans(Tween.TRANS_BOUNCE)\
		.set_ease(Tween.EASE_OUT)

	# --- FADE IN PARALLEL ---
	tween.parallel().tween_property(self, "modulate:a", 1.0, 0.35)\
		.set_trans(Tween.TRANS_SINE)\
		.set_ease(Tween.EASE_OUT)

	# --- HOLD FOR A MOMENT ---
	tween.tween_interval(0.6)

	# --- FADE OUT ---
	tween.tween_property(self, "modulate:a", 0.0, 0.3)\
		.set_trans(Tween.TRANS_SINE)\
		.set_ease(Tween.EASE_IN)

	# --- OPTIONAL CALLBACK ---
	tween.tween_callback(func():
		# Show your summary panel here
		emit_signal("animation_complete")
		queue_free()
	)

func play_lose_message() -> void:
	print("LOSE MSG")
	scale = Vector2(0.2, 0.2)
	modulate.a = 0.0

	# Start slightly above
	var start_pos := position
	position = start_pos + Vector2(0, -20)

	var tween := create_tween()

	# Fade in slowly
	tween.tween_property(self, "modulate:a", 0.5, 0.4) \
		.set_trans(Tween.TRANS_SINE) \
		.set_ease(Tween.EASE_OUT)

	# Drop downward with a soft ease
	tween.parallel().tween_property(self, "position:y", start_pos.y, 0.5) \
		.set_trans(Tween.TRANS_QUAD) \
		.set_ease(Tween.EASE_IN)

	# Slight scale shrink (feels defeated)
	tween.parallel().tween_property(self, "scale", Vector2(0.4, 0.4), 0.5) \
		.set_trans(Tween.TRANS_SINE) \
		.set_ease(Tween.EASE_OUT)

	# Hold briefly
	tween.tween_interval(0.5)

	# Fade out slowly
	tween.tween_property(self, "modulate:a", 0.0, 0.4) \
		.set_trans(Tween.TRANS_SINE) \
		.set_ease(Tween.EASE_IN)

	tween.tween_callback(func():
		emit_signal("animation_complete")
		queue_free()
	)
