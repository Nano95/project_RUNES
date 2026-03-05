extends Control
class_name OfflineRuneSelectionButton

var rune:RuneData

func _ready() -> void:
	populate_rune_data()

func setup(r:RuneData, cta:Callable) -> void:
	rune = r
	$Panel/Button.pressed.connect(cta.bind(r.name))

func populate_rune_data() -> void:
	$Panel/Panel/TextureRect.texture = rune.icon
	
