extends Control
class_name OfflineRuneSelectionButton

var rune:RuneData

func _ready() -> void:
	populate_rune_data()

func setup(r:RuneData, cta:Callable) -> void:
	rune = r
	var rune_name = "" if (rune == null) else r.name
	$Panel/Button.pressed.connect(cta.bind(rune_name))

func populate_rune_data() -> void:
	if (rune is not RuneData): return
	$Panel/Panel/TextureRect.texture = rune.icon
	var ess_per_hour:int = floor((float(rune.essence_cost) / float(rune.craft_time)) * 3600)
	$Panel/Panel2/essLabel.text = str("/hr: ", ess_per_hour)
	var runes_per_hour:int = floor((1.0 / float(rune.craft_time)) * 3600.0)
	$Panel/Panel2/runeLabel.text = str("/hr: ", runes_per_hour) 
	
