extends Control
class_name LootEntry

@export var display_time := 2.0
var current_quantity:int = 0
var timer := 0.0
var my_name:String = ""

func _ready() -> void:
	# Start invisible and small
	scale = Vector2(0.0, 0.0)
	modulate.a = 0.0
	_play_appear_tween()

func _process(delta: float) -> void:
	timer -= delta
	if timer <= 0.0:
		_play_disappear_tween()

func setup(loot_name:String, loot_icon:Texture, quantity:int=1) -> void:
	my_name = loot_name
	$Panel/Label.text = my_name
	$Panel/icon.texture = loot_icon
	if (quantity > 0):
		current_quantity += quantity
		$Panel/Label.text += "x" + str(current_quantity)

func add_quantity(quantity:int=1) -> void:
	current_quantity += quantity
	$Panel/Label.text = my_name + " x" + str(current_quantity)
	# Reset timer
	timer = display_time
	# Little bump animation
	var t := create_tween()
	t.tween_property(self, "scale", Vector2(1.15, 1.15), 0.12)
	t.tween_property(self, "scale", Vector2(1.0, 1.0), 0.12)

func _play_appear_tween() -> void:
	timer = display_time
	var t := create_tween()
	t.tween_property(self, "scale", Vector2(1.0, 1.0), 0.25) \
		.set_trans(Tween.TRANS_BOUNCE) \
		.set_ease(Tween.EASE_OUT)
	t.parallel().tween_property(self, "modulate:a", 1.0, 0.2)

func _play_disappear_tween() -> void:
	# Prevent multiple triggers
	set_process(false)

	var t := create_tween()
	t.tween_property(self, "scale", Vector2(0.0, 0.0), 0.2) \
		.set_trans(Tween.TRANS_SINE) \
		.set_ease(Tween.EASE_IN)
	t.parallel().tween_property(self, "modulate:a", 0.0, 0.15)
	t.tween_callback(queue_free)
