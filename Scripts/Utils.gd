extends Node

@onready var my_label: = load("res://Scenes/MyLabel.tscn")

var main_node:MainNode
var items: Array[String] = [
	"res://Scripts/Resources/Equipment/BootsOfHaste.tres",
	"res://Scripts/Resources/Equipment/RingOfMight.tres"
]

const RARITY_COLORS := {
	"uncommon": Color(0.6, 1.0, 0.6),   # pastel green
	"rare":     Color(0.4, 0.6, 1.0),   # soft blue
	"legendary": Color(1.0, 0.8, 0.3)   # gold-ish
}
const HP_GREEN = Color(0.238, 0.734, 0.208, 1.0)
const HP_YELLOW = Color(0.985, 0.924, 0.31, 1.0)
const PASTEL_GREEN = Color(0.6, 1.0, 0.6)
const PASTEL_RED   = Color(1.0, 0.6, 0.6)
const RED   = Color(0.966, 0.0, 0.252, 1.0)
const STATUS_MESSAGE_VICTORY:String = "Victory!"

const all_runes:Array = ["single", "plus", "aoe3"] # temporary until we figure out how runes become available

func setup(main:MainNode) -> void:
	main_node = main

func get_main() -> MainNode:
	return main_node

func get_stat_for_ui(stat_name: String) -> int:
	return main_node.game_data.base_stats[stat_name] + main_node.game_data.allocated_stats[stat_name]

############
# NUMERIZE #
############
func numberize(number: float):
	if number == null:
		return ""

	if number >= 1_000_000_000_000_000.0:
		return "%.2fQ" % (number / 1_000_000_000_000_000.0)
	elif number >= 1_000_000_000_000.0:
		return "%.2fT" % (number / 1_000_000_000_000.0)
	elif number >= 1_000_000_000.0:
		return "%.2fB" % (number / 1_000_000_000.0)
	elif number >= 1_000_000.0:
		return "%.2fM" % (number / 1_000_000.0)
	elif number >= 1_000.0:
		return "%.2fK" % (number / 1_000.0)
	else:
	# Below 1000 → no decimals
		return str(int(number))


func roll_rarity() -> String:
	var roll := randf()

	if (roll < 0.05):
		return "legendary"
	elif (roll < 0.20):
		return "rare"
	elif (roll < 0.50):
		return "uncommon"
	else:
		return "common"

func generate_item(base: EquipmentBase, level: int, rarity: String) -> EquipmentInstance:
	var inst := EquipmentInstance.new()
	inst.base = base
	inst.level = level
	inst.rarity = rarity
	
	var mod_count :int = 0
	match rarity:
		"uncommon": mod_count = 1
		"rare": mod_count = 2
		"legendary": mod_count = 3
		_ : mod_count = 0
	
	for i in mod_count:
		var stat = base.allowed_mods.pick_random()
		var amount = roll_mod_amount(stat, level, rarity)
		inst.rolled_mods[stat] = inst.rolled_mods.get(stat, 0) + amount
	
	return inst

func roll_mod_amount(stat: String, level: int, rarity: String) -> float:
	var rarity_mult:float = 0
	match rarity:
		"uncommon": rarity_mult = 1.0
		"rare": rarity_mult = 1.5
		"legendary": rarity_mult = 2.0
		_ : rarity_mult = 1.0

	# Assuming we want some of the stats to scale differently 
	var stat_mult:float = 1.0
	match stat:
		"health": stat_mult = 1.0
		"focus": stat_mult = 1.0
		"power": stat_mult = 2.0
		"luck": stat_mult = 3.0
		_ : stat_mult = 1.0

	return (level * 0.5 + randi_range(5, 15)) * rarity_mult * stat_mult

func spawn_reward_label(pos: Vector2, amount: int) -> void:
	# Instance the label
	var label: Label = my_label.instantiate()
	add_child(label)

	# Set initial properties
	label.text = "+" + str(amount)
	label.size = Vector2(800, 0)
	label.pivot_offset = Vector2(400, 0)
	label.position = pos
	label.scale = Vector2(0.8, 0.8) # start slightly smaller

	# Create tween
	var tween := create_tween()

	# Bounce scale up
	tween.tween_property(label, "scale", Vector2(1.2, 1.2), 0.2).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	# Return to normal scale
	tween.tween_property(label, "scale", Vector2(1, 1), 0.15).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_IN_OUT)

	# Move upward while fading out
	tween.parallel().tween_property(label, "position", pos + Vector2(0, -40), 0.6).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	tween.parallel().tween_property(label, "modulate:a", 0.0, 0.6).set_trans(Tween.TRANS_LINEAR).set_ease(Tween.EASE_IN)

	# Cleanup after animation
	tween.tween_callback(label.queue_free)

func animate_modal_entry(node: CanvasItem, duration := 0.15, offset := 10.0):
	if not node:
		return

	var tween := node.get_tree().create_tween().set_parallel(true)
	node.show()
	node.modulate.a = 0.0
	node.position.y -= offset  # Start slightly above

	tween.tween_property(node, "modulate:a", 1.0, duration).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	tween.tween_property(node, "position:y", node.position.y + offset, duration).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)

func animate_modal_exit(node: CanvasItem, duration := 0.15, offset := 10.0, should_free:bool=false):
	if not node:
		return

	var tween := node.get_tree().create_tween().set_parallel(true)

	tween.tween_property(node, "modulate:a", 0.0, duration).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	tween.tween_property(node, "position:y", node.position.y - offset, duration).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	tween.set_parallel(false) # need to do this for some reason the below things will get called immediately otherwise
	
	if (should_free):
		tween.tween_callback(node.queue_free)  # delete after anim completes
	else:
		tween.tween_callback(Callable(node, "hide"))  # Hide after animation completes

func get_rarity_color(rarity: String) -> Color:
	return RARITY_COLORS.get(rarity, Color.WHITE) # Defaults to white if not found

func get_time_gone() -> Dictionary:
	print_debug("_TIME GONE IS NOTHING_")
	return {}
	#var time_format = {}
	#if player_data.first_time_opened:
		#time_format["days"] = 0
		#time_format["hours"] = 0
		#time_format["minutes"] = 0
		#time_format["seconds"] = 0
		#time_format["total_amount_seconds"] = 0
		#return time_format
	#
	## error handle last seen being a negative number.
	#if ("last_seen" in player_data):
		#if (int(player_data.last_seen) < 0):
			#player_data.last_seen = str(Time.get_unix_time_from_system())
	#
	#var time_gone = ceil(Time.get_unix_time_from_system()) - int(player_data.last_seen)
	#time_format = {
		#"days": floor(time_gone / 86400),
		#"hours": floor((int(time_gone) % 86400) / 3600.0),
		#"minutes": floor((int(time_gone) % 3600) / 60.0),
		#"seconds": int(time_gone) % 60,
		#"total_amount_seconds": int(time_gone)
	#}
	#
	#return time_format


func animate_summary_in_happy(panel):
	# Start invisible and slightly small
	panel.modulate.a = 0.0
	panel.scale = Vector2(0.85, 0.85)

	var tween := create_tween()

	# --- FADE IN ---
	tween.tween_property(panel, "modulate:a", 1.0, 0.25)\
		.set_trans(Tween.TRANS_SINE)\
		.set_ease(Tween.EASE_OUT)

	# --- SCALE UP WITH BOUNCE ---
	tween.parallel().tween_property(panel, "scale", Vector2(1.05, 1.05), 0.18)\
		.set_trans(Tween.TRANS_CUBIC)\
		.set_ease(Tween.EASE_OUT)

	# --- SETTLE BACK TO NORMAL SIZE ---
	tween.tween_property(panel, "scale", Vector2(1.0, 1.0), 0.12)\
		.set_trans(Tween.TRANS_CIRC)\
		.set_ease(Tween.EASE_OUT)

func animate_summary_out_and_free(panel):
	var tween := create_tween()

	# --- FADE OUT ---
	tween.tween_property(panel, "modulate:a", 0.0, 0.22)\
		.set_trans(Tween.TRANS_SINE)\
		.set_ease(Tween.EASE_IN)

	# --- SCALE DOWN SLIGHTLY ---
	tween.parallel().tween_property(panel, "scale", Vector2(0.9, 0.9), 0.22)\
		.set_trans(Tween.TRANS_CUBIC)\
		.set_ease(Tween.EASE_IN)

	# --- SLIDE DOWN (or up if you prefer) ---
	tween.parallel().tween_property(panel, "position:y", panel.position.y + 40, 0.28)\
		.set_trans(Tween.TRANS_SINE)\
		.set_ease(Tween.EASE_IN)

	# --- CLEANUP ---
	tween.tween_callback(panel.queue_free)

func warn_shake_node(node) -> void:
	if !(is_instance_valid(node)):
		return
	if not node.has_meta("original_position"):
		node.set_meta("original_position", node.position)
	var original_position = node.get_meta("original_position")  # Capture it *now*, so it's consistent for this whole tween
	# Always reset to original first in case of overlap
	node.position = original_position
	
	var shake_amount: float = 4.0
	var shake_time: float = 0.05
	
	var tween = node.create_tween()
	tween.tween_property(node, "position", original_position + Vector2(-shake_amount, 0), shake_time).set_trans(Tween.TRANS_SINE)
	tween.tween_property(node, "position", original_position + Vector2(shake_amount, 0), shake_time).set_trans(Tween.TRANS_SINE)
	tween.tween_property(node, "position", original_position + Vector2(-shake_amount / 2.0, 0), shake_time).set_trans(Tween.TRANS_SINE)
	tween.tween_property(node, "position", original_position + Vector2(shake_amount / 2.0, 0), shake_time).set_trans(Tween.TRANS_SINE)
	tween.tween_property(node, "position", original_position, shake_time).set_trans(Tween.TRANS_SINE)
