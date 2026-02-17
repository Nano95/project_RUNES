extends Control
class_name MyButton

func setup(txt:String, callable:Callable, new_scale:Vector2=Vector2(1.0, 1.0)) -> void:
	$Button.text = str(txt)
	$Button.pressed.connect(callable)
	scale = new_scale
