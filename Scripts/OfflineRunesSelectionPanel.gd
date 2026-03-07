extends Control
class_name OfflineRunesSelectionPanel

@export var rune_select_btn:PackedScene
@export var exit_btn:Button
@export var grid_container:GridContainer
@export var clear_rune_button:OfflineRuneSelectionButton

var main:MainNode
var slot_id:int=1
var parent:OfflineRunesPanel
func _ready() -> void:
	Utils.animate_summary_in_happy(self)
	exit_btn.pressed.connect(exit)
	populate_container()

func setup(m:MainNode, id:int, parent_panel:OfflineRunesPanel) -> void:
	main = m
	slot_id = id
	parent = parent_panel
	$ColorRect/Panel/Title/Title.text = str("Select slot ", slot_id, " rune!")

func populate_container() -> void:
	clear_rune_button.setup(null, select_rune)
	for rune in RuneDatabase.runes.values():
		var rune_btn = rune_select_btn.instantiate()
		rune_btn.setup(rune, select_rune)
		grid_container.add_child(rune_btn)

func select_rune(rune_name:String) -> void:
	main.game_data.set_offline_rune_slot(slot_id, rune_name)
	Utils.animate_summary_out_and_free(self)
	parent.populate_container()

func exit() -> void:
	Utils.animate_summary_out_and_free(self)
