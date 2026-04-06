extends Control
class_name OfflineRuneSelectionButton

var rune:RuneData

func _ready() -> void:
	populate_rune_data()

func setup(r:RuneData, cta:Callable) -> void:
	rune = r
	var rune_name:String = "" if (rune == null) else r.name
	$Panel/Button.pressed.connect(cta.bind(rune_name))

func populate_rune_data() -> void:
	if (rune is not RuneData): return
	$Panel/Panel/TextureRect.texture = rune.icon
	$Panel/Panel2/essLabel.text = str("/craft: ", rune.essence_cost)
	var modified_time = rune.craft_time * Utils.crafting_speed_mult
	$Panel/Panel2/runeLabel.text = str("secs/craft: %.1f" % modified_time) 
	var essence_type_texture:String = "res://Sprites/" + rune.essence_type + "_ESSENCE_ICON.png"
	$Panel/Panel2/TextureRect.texture = load(essence_type_texture)
