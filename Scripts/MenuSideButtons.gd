extends Control
class_name MenuSideButtons

@export var button:Button
var vertical_pos:int = 0
var original_position:Vector2

func _ready() -> void:
	pass

func setup(icon:Texture, callable:Callable, pos:Vector2, v_pos:int, group: ButtonGroup) -> void:
	button.pressed.connect(callable)
	button.toggled.connect(_on_toggled)
	button.icon = icon
	original_position = pos
	position = pos
	vertical_pos = v_pos
	button.button_group = group

# Triggered by the container
func play_slide_in(delay: float) -> void:
	print("delay: ", delay)
	#var t := create_tween()
	#var track = t.tween_property(self, "position:x", original_position.x, 2.5)\
		#.set_trans(Tween.TRANS_SINE)\
		#.set_ease(Tween.EASE_OUT)
	#track.set_delay(delay)


func play_selected() -> void:
	print("-test selected")
	var t := create_tween()
	t.tween_property(self, "position:y", original_position.y - 20, 0.15)\
		.set_trans(Tween.TRANS_SINE)\
		.set_ease(Tween.EASE_OUT)

func play_unselected() -> void:
	print("- unselected")
	var t := create_tween()
	t.tween_property(self, "position:y", original_position.y, 0.15)\
		.set_trans(Tween.TRANS_SINE)\
		.set_ease(Tween.EASE_OUT)

func _on_toggled(pressed: bool) -> void:
	print("- pressed ", pressed)
	if pressed:
		play_selected()
	else:
		play_unselected()

func emit_my_cta() -> void:
	button.pressed.emit()
