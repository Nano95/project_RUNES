extends Button


func setup(rune:RuneData) -> void:
	text = rune.name
	icon = rune.icon
	$TextureRect/FocusLabel.text = str(rune.focus_cost)
