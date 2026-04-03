extends HBoxContainer
class_name SideButtonsContainer

@export var side_buttons_group:ButtonGroup
@export var side_button_ref:PackedScene
var main_menu:MainMenu
var side_buttons_data:Array
var side_buttons:Array = [] # Array of the buttons
var main:MainNode

func setup(m:MainNode, menu:MainMenu) -> void:
	main = m
	main_menu = menu
	side_buttons_data = [
		{
			"icon": preload("res://Sprites/SWORD_LARGE_ICON.png"),
			"callable": main_menu.open_stats 
		},
		{
			"icon": preload("res://Sprites/MONSTER_ICON.png"),
			"callable": main_menu.open_fight_menu 
		},
		{
			"icon": preload("res://Sprites/Runes/ARCANE_CROSS_RUNE.png"),
			"callable": main_menu.open_offline_runes
		},
		{
			"icon": preload("res://Sprites/SHOPS_ICON.png"),
			"callable": main_menu.open_shop
		},
		{
			"icon": preload("res://Sprites/PRESTIGE_ICON.png"),
			"callable": main_menu.open_prestige
		},
		{
			"icon": preload("res://Sprites/BUG_ICON.png"),
			"callable": main_menu.open_debug_things
		}
	]
	populate_buttons()

func populate_buttons() -> void:
	var v_id=0
	for btn_data in side_buttons_data:
		var btn = side_button_ref.instantiate()
		btn.setup(btn_data["icon"], btn_data["callable"], Vector2.ZERO, v_id, side_buttons_group)
		add_child(btn)
		side_buttons.append(btn)
		v_id += 1
	
	side_buttons[0].emit_my_cta()
	for i in range(side_buttons.size()):
		var btn = side_buttons[i]
		btn.play_slide_in(i * 0.1) # cascading delay
