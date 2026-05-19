extends Button

var qty:int = 0
var rune_data:RuneData
var active_luck_popups: Array = [] # This EXACT NAME is needed only for components
# That may stack luck popups so that they wont sit on top of each other 
var is_selected:bool=false
var SHADER_SCALE:Vector2 = Vector2(0.8, 0.8)

@onready var manaLbl = $manaLbl

func _ready() -> void:
	# Freeze shader animation
	%Shader.scale = Vector2(0,0)
	%Shader.material.set("shader_parameter/swirl_speed", 0.0)
	%Shader.material.set("shader_parameter/swirl_strength", 0.0)
	if (rune_data):
		set_vortex_color(rune_data.rune_type)

func setup(rune:RuneData, _qty:int=1) -> void:
	rune_data = rune
	$runeSprite.texture = rune.icon
	qty = _qty
	set_rune_qty(qty)

func set_rune_qty(_qty:int) -> void:
	qty = _qty
	%qty.text = str(Utils.numberize(qty))
	disabled = qty <= 0

# this is called in game_ui when setting up the buttons
func refresh_cost_display(modded_cost_value:int):
	var base_cost = rune_data.focus_cost
	manaLbl.text = str(modded_cost_value)
	
	if (modded_cost_value < base_cost):
		manaLbl.modulate = Color.GREEN
	elif (modded_cost_value > base_cost):
		manaLbl.modulate = Color.RED
	else:
		manaLbl.modulate = Color(1, 1, 1)

func set_selected() -> void:
	is_selected = true
	# Turn on shader animation
	%Shader.visible = true
	%Shader.material.set("shader_parameter/swirl_speed", 3.0)
	%Shader.material.set("shader_parameter/swirl_strength", 17.5)
	
	var t := create_tween()
	t.set_trans(Tween.TRANS_CUBIC)
	t.set_ease(Tween.EASE_OUT)

	# Fade in
	t.tween_property(%Shader, "modulate:a", 1.0, 0.15)

	# Grow slightly
	t.parallel().tween_property(%Shader, "scale", SHADER_SCALE, 0.15)


func set_unselected() -> void:
	is_selected = false
	var t := create_tween()
	t.set_trans(Tween.TRANS_CUBIC)
	t.set_ease(Tween.EASE_IN)

	# Fade out
	t.tween_property(%Shader, "modulate:a", 0.0, 0.15)

	# Shrink
	t.parallel().tween_property(%Shader, "scale", Vector2(0.0, 0.0), 0.15)

	# When done, hide it
	t.tween_callback(func():
		%Shader.visible = false
		%Shader.material.set("shader_parameter/swirl_speed", 0.0)
		%Shader.material.set("shader_parameter/swirl_strength", 0.0)
	)

	# Freeze shader animation


func set_vortex_color(rune_type: String) -> void:
	var mat = %Shader.material
	if mat == null:
		return
	print("Shader going to be set", rune_type)
	match rune_type:
		"arcane":
			mat.set("shader_parameter/color1", Color(0.308, 0.0, 0.319, 1.0)) # purple/pink
			mat.set("shader_parameter/color2", Color(0.308, 0.0, 0.319, 1.0)) # purple/pink
			mat.set("shader_parameter/outline_color", Color(0.82, 0.45, 1.0)) # purple/pink
		"electric":
			mat.set("shader_parameter/color1", Color("fefff2")) # bright yellow
			mat.set("shader_parameter/color2", Color("00000")) # bright yellow
			mat.set("shader_parameter/outline_color", Color("fff138")) # bright yellow
		"fire":
			mat.set("shader_parameter/color1", Color("cfb300")) # orange/red
			mat.set("shader_parameter/color2", Color("ff1c1c")) # orange/red
			mat.set("shader_parameter/outline_color", Color("c75d00")) # orange/red
		"ice":
			mat.set("shader_parameter/color1", Color("00fffb")) # icy blue
			mat.set("shader_parameter/color2", Color("38bdff")) # icy blue
			mat.set("shader_parameter/outline_color", Color("99f9f8"))
		"earth":
			mat.set("shader_parameter/color2", Color("572300")) # greenish earth tone
			mat.set("shader_parameter/color2", Color("572300")) # greenish earth tone
			mat.set("shader_parameter/outline_color", Color("67b706"))
		_:
			mat.set("shader_parameter/color_2", Color(1,1,1)) # fallback
			mat.set("shader_parameter/outline_color", Color("000000ff"))
