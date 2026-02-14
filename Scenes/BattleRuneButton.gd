extends Button

func setup(rune:RuneData) -> void:
	icon = rune.icon
	$manaLbl.text = str(rune.focus_cost)
