extends Control
class_name OfflineRuneSlot

@export var slot_lbl:Label
@export var rune_name:Label
@export var essence_lbl:Label
@export var essence_hr_lbl:Label
@export var runes_hr_lbl:Label
@export var time_lbl:Label
@export var output_lbl:Label
@export var tap_lbl:Label
@export var rune_icon:TextureRect
@export var info_panel:Panel
@export var icon_panel:Panel
@export var select_rune:Button
@export var rune_selection_panel:PackedScene

var slot_id:int = 1
var rune
var main:MainNode
var parent_panel:OfflineRunesPanel
func setup(m:MainNode, r, parent:OfflineRunesPanel, id:int=1) -> void:
	main = m
	if r == null: 
		rune = null 
	else: 
		rune = RuneDatabase.runes[r] # convert string → RuneData
	slot_id = id
	slot_lbl.text = str("Slot ", slot_id)
	parent_panel = parent
	select_rune.pressed.connect(spawn_rune_selector)
	update_panel()

func spawn_rune_selector() -> void:
	var pnl = rune_selection_panel.instantiate()
	pnl.setup(main, slot_id, parent_panel)
	main.spawn_to_top_ui_layer(pnl)

func update_panel() -> void:
	if (rune == null):
		# Slot should indicate to tap it to select rune
		update_unselected_slot()
	else:
		update_rune_data()

func update_unselected_slot() -> void:
	tap_lbl.visible = true
	rune_name.text = ""
	icon_panel.visible = false
	info_panel.visible = false

func update_rune_data() -> void:
	tap_lbl.visible = false
	icon_panel.visible = true
	info_panel.visible = true
	rune_name.text = rune.name
	rune_icon.texture = rune.icon
	essence_lbl.text = rune.essence_type
	var avail_essences = main.game_data.current_essences[rune.essence_type]
	print("essences available: ", avail_essences)
	# Calculations:
	var ess_per_hour:int = floor((float(rune.essence_cost) / float(rune.craft_time)) * 3600)
	essence_hr_lbl.text = str(ess_per_hour)
	var runes_per_hour:int = floor((1.0 / float(rune.craft_time)) * 3600.0)
	runes_hr_lbl.text = str(runes_per_hour) 
