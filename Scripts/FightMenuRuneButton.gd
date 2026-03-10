extends Control
class_name FightMenuRuneButton

var rune:RuneData
var main:MainNode
func _ready() -> void:
	populate_rune_data()

# close_cta is optional
func setup(id:int, r:RuneData, m:MainNode ,cta:Callable, close_cta) -> void:
	rune = r
	main = m
	var rune_name = "" if (rune == null) else r.name
	
	# If we have a close_cta it means we are using the buttons with a panel, so you must pass id and rune name
	if (close_cta != null):
		$Panel/Button.pressed.connect(close_cta)
		$Panel/Button.pressed.connect(cta.bind(id, rune_name))
		$Panel.scale = Vector2(.65,.65)
		custom_minimum_size = Vector2(145,220)
	else:
		# Otherwise just the id because we are just opening the panel
		$Panel/Button.pressed.connect(cta.bind(id))

func populate_rune_data() -> void:
	if (rune is not RuneData): return
	$Panel/Panel2/Select.hide()
	$Panel/Panel/runeIcon.texture = rune.icon 
	$Panel/Panel2/nameLabel.visible = true
	$Panel/Panel2/nameLabel.text = rune.name
	$Panel/Panel2/Qty.visible = true
	$Panel/Panel2/Qty.text = str(main.game_data.rune_inv[rune.name], "x") 
	#var essence_type_texture:String = "res://Sprites/" + rune.essence_type + "_ESSENCE_ICON.png"
	#$Panel/Panel2/typeTexture.visible = true
	#$Panel/Panel2/typeTexture.texture = load(essence_type_texture) SET THE NEW ICONS HERE
	
