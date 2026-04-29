extends Control
class_name MainMenu

@onready var inv_button:PackedScene = preload("res://Scenes/InventoryButton.tscn")
@onready var debug_panel:PackedScene = preload("res://Scenes/DebugPanel.tscn")
@export var fight_menu:PackedScene
@export var offline_rune_panel:PackedScene
@export var shop_panel:PackedScene
@export var prestige_panel:PackedScene
@export var stats_panel:PackedScene

@export var xp_curve:Curve
@export var equipment_slot_group:ButtonGroup

@export var eq_slot_1_btn:Button
@export var eq_slot_2_btn:Button

@export var nav_buttons_container:HBoxContainer
@export var inventory_grid:GridContainer
@export var generate_btn:Button
var buttons_items_dictionary = {
	
}

var current_equipment_slot_selected:String = "slot1"
var active_menu_ref
var main:MainNode


func _ready() -> void:
	connect_buttons()
	#populate_inventory()
	update_info_panel()
	setup_side_buttons()

func setup(main_ref:MainNode) -> void:
	main = main_ref

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

func open_fight_menu() -> void:
	if (is_instance_valid(active_menu_ref)):
		active_menu_ref.queue_free()
	active_menu_ref = fight_menu.instantiate()
	active_menu_ref.setup(main)
	main.spawn_to_top_ui_layer(active_menu_ref)

func connect_buttons() -> void:
	eq_slot_1_btn.toggled.connect(eq_slot_button_pressed)
	eq_slot_2_btn.toggled.connect(eq_slot_button_pressed)

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

# SIDE BUTTONS
func setup_side_buttons() -> void:
	nav_buttons_container.setup(main, self)

func open_prestige(is_debug:bool=false) -> void:
	if (is_instance_valid(active_menu_ref)):
		active_menu_ref.queue_free()
	
	active_menu_ref = prestige_panel.instantiate()
	active_menu_ref.setup(main, is_debug)
	main.spawn_to_top_ui_layer(active_menu_ref)

func open_stats() -> void:
	if (is_instance_valid(active_menu_ref)):
		active_menu_ref.queue_free()
	
	active_menu_ref = stats_panel.instantiate()
	active_menu_ref.setup(main)
	main.spawn_to_top_ui_layer(active_menu_ref)

func open_debug_things() -> void:
	if (is_instance_valid(active_menu_ref)):
		active_menu_ref.queue_free()
	
	active_menu_ref = debug_panel.instantiate()
	active_menu_ref.setup(self, main)
	main.spawn_to_top_ui_layer(active_menu_ref)

func add_xp(amount: float) -> void:
	print("Adding exp: ", amount)
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
	#main.game_data.current_exp = 0 # do not do this. it prevents bulk leveling
	main.game_data.available_ap += 5
	main.game_data.check_prestige_unlocked()

func xp_required_for_level(level: int) -> float:
	return xp_curve.sample(level)

func open_offline_runes() -> void:
	if (is_instance_valid(active_menu_ref)):
		active_menu_ref.queue_free()
	active_menu_ref = offline_rune_panel.instantiate()
	active_menu_ref.setup(main)
	main.spawn_to_top_ui_layer(active_menu_ref)

func open_shop() -> void:
	if (is_instance_valid(active_menu_ref)):
		active_menu_ref.queue_free()
	active_menu_ref = shop_panel.instantiate()
	active_menu_ref.setup(main, self)
	main.spawn_to_top_ui_layer(active_menu_ref)

func update_info_panel() -> void:
	var total_gold = main.game_data.current_gold
	var total_essence = main.game_data.current_essences
	$BottomInfoPanel/Panel/RichTextLabel.text = build_loot_summary_bbcode(total_gold, total_essence)

func build_loot_summary_bbcode(total_gold: int, total_essences: Dictionary) -> String:
	var gold_icon := "res://Sprites/GOLD_ICON.png"

	# Map essence types to their icons
	var essence_icons := {
		"arcane": "res://Sprites/arcane_ESSENCE_ICON.png",
		"earth": "res://Sprites/earth_ESSENCE_ICON.png",
		"electric": "res://Sprites/electric_ESSENCE_ICON.png",
		"fire": "res://Sprites/fire_ESSENCE_ICON.png",
		"ice": "res://Sprites/ice_ESSENCE_ICON.png"
	}

	var bb := ""

	# GOLD
	bb += "[img=40]" + gold_icon + "[/img] "
	bb += str(Utils.numberize(total_gold))

	bb += "  |  "

	# ESSENCES
	var essence_parts := []

	for essence_type in total_essences.keys():
		var amount = total_essences[essence_type]
		if amount > 0:
			var icon_path = essence_icons.get(essence_type, "")
			if icon_path != "":
				essence_parts.append("[img=40]" + icon_path + "[/img] " + str(Utils.numberize(amount)))

	bb += "   ".join(essence_parts)

	return bb
