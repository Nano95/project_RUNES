extends Button

var qty:int = 0
var rune_data:RuneData
var active_luck_popups: Array = [] # This EXACT NAME is needed only for components
# That may stack luck popups so that they wont sit on top of each other 
@onready var manaLbl = $manaLbl
func setup(rune:RuneData, _qty:int=1) -> void:
	rune_data = rune
	icon = rune.icon
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
