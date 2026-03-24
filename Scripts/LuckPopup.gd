extends Node2D
class_name LuckPopup

var my_owner:Node=null
var sprite_size:Vector2 = Vector2.ZERO
var move_distance:float = -60.0 # go up by default
func _ready() -> void:
	if (my_owner):
		# This EXACT NAME is needed only for components (active_luck_popups)
		# That may stack luck popups so that they wont sit on top of each other 
		my_owner.active_luck_popups.append(self)
	animate_me()

func _exit_tree() -> void:
	if (my_owner):
		my_owner.active_luck_popups.erase(self)

func setup(txt:String="", additional_distance:float=0) -> void:
	%Label.text = txt
	sprite_size = $Sprite.size
	move_distance -= additional_distance # we going up by default

func animate_me() -> void:
	var duration := 1.7
	var tween := create_tween()

	# Start small and invisible
	scale = Vector2(0.6, 0.6)
	modulate.a = 0.0

	# PHASE 1 — Pop in (overshoot)
	tween.tween_property(self, "scale", Vector2(1.8, 1.8), 0.38)\
		.set_trans(Tween.TRANS_BOUNCE)\
		.set_ease(Tween.EASE_OUT)

	tween.parallel().tween_property(self, "modulate:a", 1.0, 0.18)

	# PHASE 2 — Bounce down to normal size
	tween.tween_property(self, "scale", Vector2(1.5, 1.5), 0.72)\
		.set_trans(Tween.TRANS_BOUNCE)\
		.set_ease(Tween.EASE_OUT)

	# PHASE 3 — Float upward + fade out
	tween.parallel().tween_property(self, "position:y", position.y + move_distance, duration)\
		.set_trans(Tween.TRANS_CUBIC)\
		.set_ease(Tween.EASE_OUT)

	tween.parallel().tween_property(self, "modulate:a", 0.0, duration)

	tween.tween_callback(queue_free)
