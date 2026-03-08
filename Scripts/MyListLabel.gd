extends Control
class_name MyListLabel

func setup(my_txt:String, my_scale:Vector2=Vector2(.3, .3)) -> void:
	$Label.text = my_txt
	$Label.scale = my_scale
