extends Node2D
class_name RuneAnimation

var anim_name:String = "magical3"

func _ready() -> void:
	$AnimatedSprite2D.play(anim_name)
	$AnimatedSprite2D.animation_finished.connect(queue_free)

func setup(an_name:String) -> void:
	anim_name = an_name
