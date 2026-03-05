extends Control
class_name OfflineRunesPanel

@export var rune_slot_ref:PackedScene
@export var close_btn:Button
@export var slots_container:VBoxContainer

var main:MainNode
func _ready() -> void:
	Utils.animate_summary_in_happy(self)
	populate_container()

func setup(m:MainNode) -> void:
	main = m
	close_btn.pressed.connect(exit)

func populate_container() -> void:
	for child in slots_container.get_children():
		child.queue_free()
	
	# For now just two, no need to worry about unlockable slots
	var unlocked_slots = 2 # later this becomes dynamic 
	for slot_id in range(1, unlocked_slots + 1):
		print(slot_id)
		var slot = rune_slot_ref.instantiate() as OfflineRuneSlot
		var rune_name = main.game_data.get_offline_rune_slot(slot_id) # Null or String
		slot.setup(main, rune_name, self, slot_id)
		slots_container.add_child(slot)

func exit() -> void:
	Utils.animate_summary_out_and_free(self)
