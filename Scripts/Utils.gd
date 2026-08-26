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
const HP_GREEN:Color = Color(0.238, 0.734, 0.208, 1.0)
const HP_YELLOW:Color = Color(0.985, 0.924, 0.31, 1.0)
const PASTEL_GREEN:Color = Color(0.6, 1.0, 0.6)
const PASTEL_RED:Color   = Color(1.0, 0.6, 0.6)
const RED:Color   = Color(0.966, 0.0, 0.252, 1.0)
const STATUS_MESSAGE_VICTORY:String = "Victory!"
const STATUS_MESSAGE_LOST:String = "You ded :("
const MODALS_POSITION:Vector2 = Vector2(0, 38)
var crafting_speed_mult:float = 1.0

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
		return "%.2fq" % (number / 1_000_000_000_000_000.0)
	elif number >= 1_000_000_000_000.0:
		return "%.2ft" % (number / 1_000_000_000_000.0)
	elif number >= 1_000_000_000.0:
		return "%.2fb" % (number / 1_000_000_000.0)
	elif number >= 1_000_000.0:
		return "%.2fm" % (number / 1_000_000.0)
	elif number >= 9999.0:
		return "%.2fk" % (number / 1_000.0)
	else:
	# Below 1000 → no decimals
		return str(int(number))

func format_time(value) -> String:
	var total := int(value)

	@warning_ignore("integer_division")
	var hours := total / 3600
	@warning_ignore("integer_division")
	var minutes := (total % 3600) / 60
	var seconds := total % 60

	var parts := []

	if hours > 0:
		if (hours >= 24):
			return "Max 24H+"
		else:
			parts.append("%02d" % hours)

	if minutes > 0 or hours > 0:
		parts.append("%02d" % minutes)

	parts.append("%02ds" % seconds)

	return ":".join(parts)

func get_unlocked_number_of_families() -> int:
	if (!main_node):
		return 0
	
	var fams:Dictionary = main_node.game_data['unlocked_monster_families']
	var counter:int = 0
	for fam_unlocked in fams.values():
		if (fam_unlocked):
			counter += 1
	
	return counter

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

func calculate_reward(base_amount: float, reward_type: String) -> int:
	var bonus := 0.0

	# Blessings ADD
	for b in main_node.game_data.blessings:
		if not b["toggled"]:
			continue

		if b["id"].begins_with("mod_%s-" % reward_type):
			var parts = b["id"].split("-")
			var percent = parts[1].to_float()
			bonus += percent / 100.0

	# Curses SUBTRACT
	for c in main_node.game_data.curses:
		if not c["toggled"]:
			continue

		if c["id"].begins_with("mod_%s-" % reward_type):
			var parts = c["id"].split("-")
			var percent = parts[1].to_float()
			bonus -= percent / 100.0

	return int(ceil(base_amount * (1.0 + bonus)))

func calculate_monster_hp(base_hp: float) -> int:
	var bonus := 0.0
#
	## Blessings ADD
	#for b in blessings:
		#if b["toggled"] and b["id"].begins_with("monster_hp-"):
			#var percent = b["id"].split("-")[1].to_float()
			#bonus -= percent / 100.0

	# Curses SUBTRACT
	for c in main_node.game_data.curses:
		if c["toggled"] and c["id"].begins_with("mod_hp-"):
			var percent = c["id"].split("-")[1].to_float()
			bonus += percent / 100.0

	# Equipment (can be positive or negative)
	#for e in equipment_mods:
		#if e["id"].begins_with("monster_hp-"):
			#var percent = e["id"].split("-")[1].to_float()
			#bonus += (percent / 100.0) * (e.get("sign", 1)) # sign = +1 or -1

	# Final HP (always round up)
	return int(ceil(base_hp * (1.0 + bonus)))

func find_blessing_curse(is_blessing:bool, id_to_find:String) -> Dictionary:
	var arr = main_node.game_data.blessings if (is_blessing) else main_node.game_data.curses
	for item in arr:
		if (item.id == id_to_find):
			return item
	
	return {}

func is_blessing_curse_toggled(is_blessing:bool, id_to_find:String) -> bool:
	var arr = main_node.game_data.blessings if (is_blessing) else main_node.game_data.curses
	for item in arr:
		if (item.id == id_to_find):
			return item.toggled
	
	return false

func get_blessing_curse_amount(is_blessing:bool, id_to_find:String) -> int:
	var arr = main_node.game_data.blessings if (is_blessing) else main_node.game_data.curses
	for item in arr:
		if (item.id != id_to_find):
			continue
		if (!item.toggled):
			continue
		return int(item.id.split("-")[1]) # split 'monster_elites-10'
	
	return 0

func update_crafting_speed():
	var blessing_bonus = get_blessing_curse_amount(true, "mod_offline_production-20") # returns 20
	crafting_speed_mult = 1.0 - (blessing_bonus * 0.01)

func spawnFloatingLabel(text: String, color: Color, sourceNode: Control, shake: bool = false) -> void:
	var lbl = RichTextLabel.new()
	lbl.bbcode_enabled = true
	lbl.text = "[color=#%s]%s[/color]" % [color.to_html(false), text]
	lbl.fit_content = true
	lbl.scroll_active = false
	lbl.size = Vector2(300, 60)
	lbl.custom_minimum_size = Vector2(150, 60)
	lbl.pivot_offset_ratio = Vector2(.5, .5)
	lbl.add_theme_constant_override("outline_size", 10)
	lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	lbl.mouse_filter = Control.MOUSE_FILTER_IGNORE

	# Convert source node position to global then to top layer local
	main_node.spawn_to_top_ui_layer(lbl)
	var globalPos = sourceNode.get_global_rect().get_center()
	lbl.position = globalPos - Vector2(lbl.size.x / 2, 0)
	
	var tween = lbl.create_tween().set_parallel(true)

	if shake:
		# Shake then fade
		lbl.text = "[shake rate=20 level=5][color=#%s][font_size=28]%s[/font_size][/color][/shake]" % [color.to_html(false), text]
		tween.tween_property(lbl, "position:y", lbl.position.y - 40, 0.6) \
			.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
		tween.tween_property(lbl, "scale", Vector2(1.5, 1.5), 0.15) \
			.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
		tween.chain().tween_property(lbl, "scale", Vector2(0.0, 0.0), 0.3) \
			.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
		tween.tween_property(lbl, "modulate:a", 0.0, 0.3).set_delay(0.3)
	else:
		lbl.text = "[wave amp=20 freq=10][color=#%s][font_size=28]%s[/font_size][/color][/wave]" % [color.to_html(false), text]
		# Float up, scale up then shrink to nothing
		tween.tween_property(lbl, "position:y", lbl.position.y - 40, 0.6) \
			.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
		tween.tween_property(lbl, "scale", Vector2(1.5, 1.5), 0.15) \
			.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
		tween.chain().tween_property(lbl, "scale", Vector2(0.0, 0.0), 0.3) \
			.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
		tween.tween_property(lbl, "modulate:a", 0.0, 0.3).set_delay(0.3)

	# Free after animation completes
	tween.set_parallel(false)
	tween.tween_callback(lbl.queue_free)

func animateButtonPress(btn: Control) -> void:
	if (is_instance_valid(btn)):
		if not btn.has_meta("original_position"):
			btn.set_meta("original_position", btn.position)
		
		var original_pos = btn.get_meta("original_position")
		var tween = btn.create_tween()
		tween.set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_BACK)

		# Animate scale down and Y movement up
		tween.tween_property(btn, "position", original_pos + Vector2(0, -6), 0.1)

		# Return to original
		tween.set_trans(Tween.TRANS_BOUNCE).set_ease(Tween.EASE_OUT)
		tween.tween_property(btn, "position", original_pos, 0.15)

# used for panels
func animateButtonBounce(node: Control) -> void:
	if not is_instance_valid(node):
		return
	
	# Force layout recalculation before reading position
	if not node.has_meta("originalY"):
		# Wait one frame for layout to settle if node was hidden
		await node.get_tree().process_frame
		node.set_meta("originalY", node.position.y)
	
	var originalY = node.get_meta("originalY")
	var tween = node.create_tween()
	tween.set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_BACK)
	tween.tween_property(node, "position:y", originalY - 6, 0.1)
	tween.set_trans(Tween.TRANS_BOUNCE).set_ease(Tween.EASE_OUT)
	tween.tween_property(node, "position:y", originalY, 0.15)

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

	var original_y = node.position.y  # capture BEFORE moving
	var tween := node.get_tree().create_tween().set_parallel(true)
	node.modulate.a = 0.0
	node.position.y = original_y - offset  # start above
	node.visible = true
	tween.tween_property(node, "modulate:a", 1.0, duration).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	tween.tween_property(node, "position:y", node.position.y + offset, duration).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)

func animate_modal_exit(node: CanvasItem, duration := 0.15, offset := 10.0, should_free:bool=false):
	if not node:
		return
	
	var original_y = node.position.y  # capture BEFORE moving
	var tween := node.get_tree().create_tween().set_parallel(true)

	tween.tween_property(node, "modulate:a", 0.0, duration).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	tween.tween_property(node, "position:y", original_y - offset, duration).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	tween.set_parallel(false) # need to do this for some reason the below things will get called immediately otherwise
	
	if (should_free):
		tween.tween_callback(node.queue_free)  # delete after anim completes
	else:
		tween.tween_callback(func():
			node.hide()
			node.position.y = original_y  # restore position after hiding
		)

func get_rarity_color(rarity: String) -> Color:
	return RARITY_COLORS.get(rarity, Color.WHITE) # Defaults to white if not found


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
	
	var shake_amount: float = 8.0
	var shake_time: float = 0.05
	
	var tween = node.create_tween()
	tween.tween_property(node, "position", original_position + Vector2(-shake_amount, 0), shake_time).set_trans(Tween.TRANS_SINE)
	tween.tween_property(node, "position", original_position + Vector2(shake_amount, 0), shake_time).set_trans(Tween.TRANS_SINE)
	tween.tween_property(node, "position", original_position + Vector2(-shake_amount / 2.0, 0), shake_time).set_trans(Tween.TRANS_SINE)
	tween.tween_property(node, "position", original_position + Vector2(shake_amount / 2.0, 0), shake_time).set_trans(Tween.TRANS_SINE)
	tween.tween_property(node, "position", original_position, shake_time).set_trans(Tween.TRANS_SINE)

func set_rainbow_text(label: RichTextLabel, text: String) -> void:
	label.clear()
	var colors := [
		Color.RED,
		Color.ORANGE,
		Color.YELLOW,
		Color.GREEN,
		Color.BLUE,
		Color(0.29, 0, 0.51), # indigo
		Color.VIOLET
	]

	var index := 0
	var rainbow_text := ""
	for _char in text:
		var color = colors[index % colors.size()]
		rainbow_text += "[color=%s]%s[/color]" % [color.to_html(), _char]
		index += 1
	
	label.text = "[center][wave amp=50 freq=6]%s[/wave][/center]" % rainbow_text
##=========================
# ── COLOR MAP ────────────────────────────────────────────
const LOG_COLORS = {
	"combat":  "#e74c3c",
	"loot":    "#c8880a",
	"gather":  "#27ae60",
	"discover":"#5dade2",
	"system":  "#888888",
	"omen":    "#9b59b6",
	"town":    "#c8880a",
	"danger":  "#e74c3c",
}
# For buttons
func getColorForType(itemType: String) -> Color:
	match itemType:
		"equipment":  return Color("#e74c3c")
		"part":       return Color("82b6bfff")
		"forageable": return Color("#27ae60")
		"ore":        return Color("a5997eff")
		"potion":     return Color("#8e44ad")
		_:            return Color("#cccccc")

# ── BBCode HELPERS ────────────────────────────────────────
func format_log(text: String, style: String) -> String:
	var color = LOG_COLORS.get(style, "#cccccc")
	return "[color=%s]%s[/color]" % [color, text]

func format_log_line(number: int, text: String, style: String) -> String:
	return "%s %s\n" % [
		format_log("#%d" % number, "system"),
		format_log(text, style)
	]
