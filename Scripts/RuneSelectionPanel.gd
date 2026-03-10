extends Control
class_name RunesSelectionPanel

@export var rune_select_btn:PackedScene
@export var exit_btn:Button
@export var grid_container:GridContainer
@export var clear_rune_button:FightMenuRuneButton

var main:MainNode
var slot_id:int=1
var button_cta:Callable
var show_all_runes:bool = false
func _ready() -> void:
	Utils.animate_summary_in_happy(self)
	exit_btn.pressed.connect(exit)
	$Button.pressed.connect(exit)
	populate_container()

func setup(m:MainNode, id:int, btn_cta:Callable, show_all:bool=false) -> void:
	main = m
	slot_id = id
	$Panel/Title/Title.text = str("Select slot ", slot_id, " rune!")
	button_cta = btn_cta
	show_all_runes = show_all
 
func populate_container() -> void:
	clear_rune_button.setup(slot_id, null, main, button_cta, close_cta)
	for rune in RuneDatabase.runes.values():
		if (show_all_runes == false and !(main.game_data.rune_inv.get(rune.name))):
			continue
		var rune_btn = rune_select_btn.instantiate()
		rune_btn.setup(slot_id, rune, main, button_cta, close_cta)
		grid_container.add_child(rune_btn)

func close_cta() -> void:
	Utils.animate_summary_out_and_free(self)

func exit() -> void:
	Utils.animate_summary_out_and_free(self)
