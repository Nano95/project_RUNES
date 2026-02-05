extends Control
class_name MainMenu

@onready var inv_button:PackedScene = preload("res://Scenes/InventoryButton.tscn")
@onready var debug_panel:PackedScene = preload("res://Scenes/DebugPanel.tscn")

@export var xp_curve:Curve
@export var start_btn:Button
@export var button_group:ButtonGroup
@export var equipment_slot_group:ButtonGroup
@export var lvl_label:Label
@export var ap_label:Label
@export var btn1:Button
@export var btn10:Button
@export var btn100:Button
@export var clear_stats_btn:Button
@export var debugton:Button
@export var eq_slot_1_btn:Button
@export var eq_slot_2_btn:Button
@export var health_increase_btn:Button
@export var speed_increase_btn:Button
@export var power_increase_btn:Button
@export var luck_increase_btn:Button
@export var health_decrease_btn:Button
@export var speed_decrease_btn:Button
@export var power_decrease_btn:Button
@export var luck_decrease_btn:Button

@export var inventory_grid:GridContainer
@export var generate_btn:Button
var buttons_items_dictionary = {
	
}

enum STAT_NAMES {
	HEALTH,
	SPEED,
	POWER,
	LUCK
}

var current_equipment_slot_selected:String = "slot1"

var main:MainNode
var stats_multiplier:int = 1
var bonus_stats:Dictionary

func _ready() -> void:
	connect_buttons()
	populate_inventory()
	recalc_player_stats()

func setup(main_ref:MainNode) -> void:
	main = main_ref

func qty_button_pressed(toggled) -> void:
	if !toggled: return
	var button_pressed = button_group.get_pressed_button()
	print("Name: ", button_pressed.name)
	match button_pressed.name:
		btn1.name:
			stats_multiplier = 1
		btn10.name: 
			stats_multiplier = 10
		btn100.name:
			stats_multiplier = 100
		_:
			stats_multiplier = 1
	
	print("-stats multi: ", stats_multiplier)

func eq_slot_button_pressed(toggled) -> void:
	if !toggled: return
	var button_pressed = equipment_slot_group.get_pressed_button()
	print("Name: ", button_pressed.name)
	match button_pressed.name:
		eq_slot_1_btn.name:
			current_equipment_slot_selected = "slot1"
		eq_slot_2_btn.name: 
			current_equipment_slot_selected = "slot2"
		_:
			current_equipment_slot_selected = "slot1"

func connect_buttons() -> void:
	start_btn.pressed.connect(main.spawn_game)
	debugton.pressed.connect(spawn_debug_things)
	btn1.toggled.connect(qty_button_pressed)
	btn10.toggled.connect(qty_button_pressed)
	btn100.toggled.connect(qty_button_pressed)
	clear_stats_btn.pressed.connect(reset_all_ap)
	eq_slot_1_btn.toggled.connect(eq_slot_button_pressed)
	eq_slot_2_btn.toggled.connect(eq_slot_button_pressed)
	health_increase_btn.pressed.connect(add_subtract_stats.bind(true, STAT_NAMES.HEALTH))
	speed_increase_btn.pressed.connect(add_subtract_stats.bind(true, STAT_NAMES.SPEED))
	power_increase_btn.pressed.connect(add_subtract_stats.bind(true, STAT_NAMES.POWER))
	luck_increase_btn.pressed.connect(add_subtract_stats.bind(true, STAT_NAMES.LUCK))
	health_decrease_btn.pressed.connect(add_subtract_stats.bind(false, STAT_NAMES.HEALTH))
	speed_decrease_btn.pressed.connect(add_subtract_stats.bind(false, STAT_NAMES.SPEED))
	power_decrease_btn.pressed.connect(add_subtract_stats.bind(false, STAT_NAMES.POWER))
	luck_decrease_btn.pressed.connect(add_subtract_stats.bind(false, STAT_NAMES.LUCK))
	# Equipment
	generate_btn.pressed.connect(generate_equipment)

func generate_equipment() -> void:
	var item_path:String = Utils.items.pick_random()
	var base_item = load(item_path)
	var rarity = Utils.roll_rarity()
	var level = 10#main.game_current_level

	var item = Utils.generate_item(base_item, level, rarity)

	main.game_data.inventory.append(item)
	populate_inventory()

func populate_inventory() -> void:
	for child in inventory_grid.get_children():
		buttons_items_dictionary.clear()
		child.queue_free()
	
	for item in main.game_data.inventory:
		var btn = inv_button.instantiate() as InventoryButton
		inventory_grid.add_child(btn)
		buttons_items_dictionary[item.to_string()] = btn
		btn.equip_button_pressed.connect(equip_item.bind(btn,item))
		btn.set_item(item)

func equip_item(pressed_button:InventoryButton, item:EquipmentInstance) -> void:
	var previous_selection = main.game_data.equipped[current_equipment_slot_selected]
	if (previous_selection != null):
		var prev_btn = buttons_items_dictionary[previous_selection.to_string()]
		if (prev_btn is InventoryButton):
			prev_btn.update_button_icon(false)
	
	pressed_button.update_button_icon(true, str(current_equipment_slot_selected).right(1))
	main.game_data.equipped[current_equipment_slot_selected] = item
	var slot_path = "Equipment/Panel/Equipment/%s/icon" % current_equipment_slot_selected
	var icon_node = get_node(slot_path) as TextureRect
	icon_node.texture = item.base.icon
	recalc_player_stats()

func allocate_ap(stat: String, amount: int = 1) -> void:
	# ADDING AP
	if amount > 0:
		var can_add:int = min(amount, main.game_data.available_ap)
		if can_add <= 0:
			return 

		main.game_data.available_ap -= can_add
		main.game_data.allocated_stats[stat] += can_add
		update_ap_label()

	# REMOVING AP
	if amount < 0:
		var remove_amount:int = min(-amount, main.game_data.allocated_stats[stat])
		if remove_amount <= 0:
			return 

		main.game_data.allocated_stats[stat] -= remove_amount
		main.game_data.available_ap += remove_amount
		update_ap_label()

func add_subtract_stats(should_add:bool=false, type:int=STAT_NAMES.HEALTH) -> void:
	var stat_name:String = "health"
	match type:
		STAT_NAMES.HEALTH: stat_name = "health"
		STAT_NAMES.SPEED: stat_name = "speed"
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
			set_health_label()
		STAT_NAMES.SPEED:
			#main.player_stats.speed += number
			#main.player_stats.speed = clamp(main.player_stats.speed, 0, 1999)
			set_speed_label()
		STAT_NAMES.POWER:
			#main.player_stats.power += number
			#main.player_stats.power = clamp(main.player_stats.power, 0, 1999)
			set_power_label()
		STAT_NAMES.LUCK:
			#main.player_stats.luck += number
			#main.player_stats.luck = clamp(main.player_stats.luck, 0, 1999)
			set_luck_label()

func recalc_player_stats():
	var stats = {"health": 0, "speed": 0, "power": 0, "luck": 0}

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

func update_lvl_label() -> void:
	lvl_label.text = "Lv: " + str(main.game_data.current_level)

func update_ap_label() -> void:
	ap_label.text = "| AP: " + str(main.game_data.available_ap)

func set_all_labels() -> void:
	set_health_label()
	set_speed_label()
	set_power_label()
	set_luck_label()
	update_lvl_label()
	update_ap_label()

func set_health_label() -> void:
	%HealthRich.text = format_stat_with_bonus("Health", main.game_data.base_stats["health"] + main.game_data.allocated_stats["health"], main.bonus_stats['health'])
func set_speed_label() -> void:
	%SpeedRich.text = format_stat_with_bonus("Speed", main.game_data.base_stats["speed"] + main.game_data.allocated_stats["speed"], main.bonus_stats['speed'])
func set_power_label() -> void:
	%PowerRich.text = format_stat_with_bonus("Power", main.game_data.base_stats["power"] + main.game_data.allocated_stats["power"], main.bonus_stats['power'])
func set_luck_label() -> void:
	%LuckRich.text = format_stat_with_bonus("Luck", main.game_data.base_stats["luck"] + main.game_data.allocated_stats["luck"], main.bonus_stats['luck'])

func format_stat_with_bonus(stat_name:String, base_value: float, bonus_value: float) -> String:
	if (bonus_value == 0):
		return " %s: %d" % [
		stat_name,
		base_value
	]

	var color := Utils.PASTEL_GREEN if (bonus_value > 0) else Utils.PASTEL_RED
	var num_sign := "+" if (bonus_value > 0) else ""
	
	# Added the space at the beginning for some padding so outline does not fall outside of the size and gets trimmed off
	return " %s: %d [color=%s](%s%d)[/color]" % [
		stat_name,
		base_value,
		color.to_html(),
		num_sign,
		bonus_value
	]

func spawn_debug_things() -> void:
	var deb = debug_panel.instantiate()
	deb.setup(self, main)
	main.spawn_to_top_ui_layer(deb)

func add_xp(amount: float) -> void:
	main.game_data.current_exp += amount
	main.game_data.total_exp += amount

	var lvled_up = false
	while true:
		var needed = xp_required_for_level(main.game_data.current_level + 1)
		if main.game_data.current_exp < needed:
			break

		# subtract the XP needed for this level
		main.game_data.current_exp -= needed
		lvled_up = true
		on_level_up()
	
	if (lvled_up):
		main.save_game()


func on_level_up():
	main.game_data.current_level += 1
	main.game_data.available_ap += 5

	update_lvl_label()
	update_ap_label()
	# apply stat bonuses, show UI, etc.

func xp_required_for_level(level: int) -> float:
	return xp_curve.sample(level)
