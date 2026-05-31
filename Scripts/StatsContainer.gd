extends Control
class_name StatsContainer

@export var btn1:Button
@export var btn10:Button
@export var btn100:Button
@export var clear_stats_btn:Button
@export var health_increase_btn:Button
@export var focus_increase_btn:Button
@export var power_increase_btn:Button
@export var luck_increase_btn:Button
@export var health_decrease_btn:Button
@export var focus_decrease_btn:Button
@export var power_decrease_btn:Button
@export var luck_decrease_btn:Button
@export var button_group:ButtonGroup

enum STAT_NAMES {
	HEALTH,
	FOCUS,
	POWER,
	LUCK
}
var stats_multiplier:int = 1
var bonus_stats:Dictionary

var main:MainNode
func _ready() -> void:
	Utils.animate_summary_in_happy(self)
	btn1.toggled.connect(qty_button_pressed)
	btn10.toggled.connect(qty_button_pressed)
	btn100.toggled.connect(qty_button_pressed)
	health_increase_btn.pressed.connect(add_subtract_stats.bind(true, STAT_NAMES.HEALTH))
	focus_increase_btn.pressed.connect(add_subtract_stats.bind(true, STAT_NAMES.FOCUS))
	power_increase_btn.pressed.connect(add_subtract_stats.bind(true, STAT_NAMES.POWER))
	luck_increase_btn.pressed.connect(add_subtract_stats.bind(true, STAT_NAMES.LUCK))
	health_decrease_btn.pressed.connect(add_subtract_stats.bind(false, STAT_NAMES.HEALTH))
	focus_decrease_btn.pressed.connect(add_subtract_stats.bind(false, STAT_NAMES.FOCUS))
	power_decrease_btn.pressed.connect(add_subtract_stats.bind(false, STAT_NAMES.POWER))
	luck_decrease_btn.pressed.connect(add_subtract_stats.bind(false, STAT_NAMES.LUCK))
	clear_stats_btn.pressed.connect(reset_all_ap)
	recalc_player_stats()

func qty_button_pressed(toggled) -> void:
	if !toggled: return
	var button_pressed = button_group.get_pressed_button()
	match button_pressed.name:
		btn1.name:
			stats_multiplier = 1
		btn10.name: 
			stats_multiplier = 10
		btn100.name:
			stats_multiplier = 100
		_:
			stats_multiplier = 1

func setup(m:MainNode) -> void:
	main = m

func allocate_ap(stat: String, amount: int = 1) -> void:
	# ADDING AP
	if (amount > 0):
		var can_add:int = min(amount, main.game_data.available_ap)
		if can_add <= 0:
			return 

		main.game_data.available_ap -= can_add
		main.game_data.allocated_stats[stat] += can_add
		update_level_ap_richtext()

	# REMOVING AP
	if (amount < 0):
		var remove_amount:int = min(-amount, main.game_data.allocated_stats[stat])
		if remove_amount <= 0:
			return 

		main.game_data.allocated_stats[stat] -= remove_amount
		main.game_data.available_ap += remove_amount
		update_level_ap_richtext()

func add_subtract_stats(should_add:bool=false, type:int=STAT_NAMES.HEALTH) -> void:
	var stat_name:String = "health"
	match type:
		STAT_NAMES.HEALTH: stat_name = "health"
		STAT_NAMES.FOCUS: stat_name = "focus"
		STAT_NAMES.POWER: stat_name = "power"
		STAT_NAMES.LUCK: stat_name = "luck"
		_: stat_name = "health"
	
	var number = 1 if (should_add) else -1
	number *= stats_multiplier
	allocate_ap(stat_name, number)
	match type:
		STAT_NAMES.HEALTH:
			#main.player_stats.health += number
			#main.player_stats.health = clamp(main.player_stats.health, 0, 1999)
			set_label("health")
		STAT_NAMES.FOCUS:
			#main.player_stats.focus += number
			#main.player_stats.focus = clamp(main.player_stats.focus, 0, 1999)
			set_label("focus")
		STAT_NAMES.POWER:
			#main.player_stats.power += number
			#main.player_stats.power = clamp(main.player_stats.power, 0, 1999)
			set_label("power")
		STAT_NAMES.LUCK:
			#main.player_stats.luck += number
			#main.player_stats.luck = clamp(main.player_stats.luck, 0, 1999)
			set_label("luck")

func recalc_player_stats():
	var stats = {"health": 0, "focus": 0, "power": 0, "luck": 0}

	for slot in main.game_data.equipped.keys():
		var item = main.game_data.equipped[slot]
		if (item == null): continue # or should this be return? Though causing bug on start up since set_all_labels not called
		var item_stats = item.get_total_stats()
		for key in item_stats.keys():
			stats[key] += item_stats[key]
	
	main.bonus_stats = stats
	set_all_labels()

func reset_all_ap() -> void:
	for stat in main.game_data.allocated_stats.keys():
		main.game_data.available_ap += main.game_data.allocated_stats[stat]
		main.game_data.allocated_stats[stat] = 0
		set_all_labels()

func update_level_ap_richtext() -> void:
	var lvl := main.game_data.current_level
	var ap := main.game_data.available_ap

	var ap_text := str(ap)

	# Color AP if player has points to allocate
	if (ap > 0):
		ap_text = "[color=green][wave amp=25 freq=6]" + ap_text + "[/wave][/color]"

	# Build final centered RichText
	var final_text := "[center]Lv: " + str(lvl) + " | AP: " + ap_text + "[/center]"

	%lvlApStatsRich.bbcode_enabled = true
	%lvlApStatsRich.text = final_text

func close() -> void:
	Utils.animate_summary_out_and_free(self)

func set_all_labels() -> void:
	set_label("health")
	set_label("focus")
	set_label("power")
	set_label("luck")
	update_level_ap_richtext()
	
	$Panel/Labels/restedBuffInfo.visible = main.game_data.rested_data.active_buff != ""

func set_label(type:String="health") -> void:
	var base_val = main.game_data.base_stats[type] + main.game_data.allocated_stats[type]
	var equip_bonus = main.bonus_stats[type]
	var rested_bonus = get_rested_bonus(type, base_val)
	
	var lbl:RichTextLabel
	match type:
		"health":
			lbl = %HealthRich
		"focus":
			lbl = %FocusRich
		"power":
			lbl = %PowerRich
		"luck":
			lbl = %LuckRich
	lbl.text = format_stat_with_bonus(type.capitalize(), base_val, equip_bonus + rested_bonus)

func format_stat_with_bonus(stat_name:String, base_value: float, bonus_value: float) -> String:
	if (bonus_value == 0):
		return " %s: %d" % [
		stat_name,
		base_value
	]

	var color := Utils.HP_YELLOW if (bonus_value > 0) else Utils.PASTEL_RED
	var num_sign := "+" if (bonus_value > 0) else ""
	
	# Added the space at the beginning for some padding so outline does not fall outside of the size and gets trimmed off
	return " %s: %d [color=%s](%s%d)[/color]" % [
		stat_name,
		base_value,
		color.to_html(),
		num_sign,
		bonus_value
	]
func get_rested_bonus(stat:String, value:int) -> int:
	var buff:String = main.game_data.rested_data.active_buff

	match buff:
		"health":
			return ceil(value * 0.5) if (stat == "health") else 0
		"focus":
			return ceil(value * 0.5) if (stat == "focus") else 0
		"power":
			return ceil(value * 0.5) if (stat == "power") else 0
		_:
			return 0
