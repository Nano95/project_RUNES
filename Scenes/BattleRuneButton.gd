extends Button

var qty:int = 0
var rune_data:RuneData
func setup(rune:RuneData, _qty:int=1) -> void:
	rune_data = rune
	icon = rune.icon
	$manaLbl.text = str(rune.focus_cost)
	qty = _qty
	set_rune_qty(qty)

func set_rune_qty(_qty:int) -> void:
	qty = _qty
	%qty.text = str(Utils.numberize(qty))
	disabled = qty <= 0
