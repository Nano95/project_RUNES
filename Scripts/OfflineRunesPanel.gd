extends Control
class_name OfflineRunesPanel

@export var rune_slot_ref:PackedScene
@export var close_btn:Button
@export var slots_container:VBoxContainer
@export var essence_summary_container:VBoxContainer
@export var rune_summary_container:VBoxContainer
@export var my_lbl:PackedScene

var main:MainNode
func _ready() -> void:
	Utils.animate_summary_in_happy(self)
	populate_container()

func setup(m:MainNode) -> void:
	main = m
	close_btn.pressed.connect(exit)

func populate_container() -> void:
	clear_children(slots_container)
	# For now just two, no need to worry about unlockable slots
	var unlocked_slots = 2 # later this becomes dynamic 
	for slot_id in range(1, unlocked_slots + 1):
		var slot = rune_slot_ref.instantiate() as OfflineRuneSlot
		var rune_name = main.game_data.get_offline_rune_slot(slot_id) # Null or String
		slot.setup(main, rune_name, self, slot_id)
		slots_container.add_child(slot)
	
	# update summary data
	update_summary_section()

func update_summary_section() -> void:
	clear_children(essence_summary_container)
	clear_children(rune_summary_container)
	
	var summary = CraftingSystem.compute_summary(main.game_data)
	var essence_summaries = summary["essence_summaries"]
	var rune_outputs = summary["rune_outputs"]
	
	if (essence_summaries.keys().size() <= 0): return
	if (rune_outputs.keys().size() <= 0): return
	### Setup Essence Labels 
	for ess_type in essence_summaries.keys():
		var lbl = my_lbl.instantiate()
		lbl.setup(
			str(ess_type.capitalize(), " production ends in ", essence_summaries[ess_type]["time_to_empty"]),
			Vector2(.2, .2)
		)
		essence_summary_container.add_child(lbl)
	
	### Setup Rune Labels
	for rune_name in rune_outputs.keys():
		var qty = rune_outputs[rune_name]
		var rune_output: String = ": 0" if (qty == 0) else str(": ~", rune_outputs[rune_name])
		var lbl = my_lbl.instantiate()
		lbl.setup(
			str(rune_name, rune_output),
			Vector2(.2, .2)
		)
		rune_summary_container.add_child(lbl)

func clear_children(node:Node) -> void:
	for child_node in node.get_children():
		child_node.queue_free()

func exit() -> void:
	Utils.animate_summary_out_and_free(self)
