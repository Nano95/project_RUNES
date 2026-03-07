extends Control
class_name ShopPanel

var cost_labels:Dictionary = {}
var owned_labels:Dictionary = {}
var rune_buy_buttons:Dictionary = {}
@export var button_group:ButtonGroup
@export var btn1:Button
@export var btn10:Button
@export var btn100:Button
@export var rune_button:PackedScene
var buy_multiplier:int = 1
var main:MainNode
var main_menu:MainMenu
var shop_current_element:String = "arcane"

func setup(main_node:MainNode, main_menu_node:MainMenu) -> void:
	main = main_node
	main_menu = main_menu_node
	setup_shop()

func setup_shop() -> void:
	show_runes_for_element(shop_current_element)

	btn1.toggled.connect(qty_button_pressed)
	btn10.toggled.connect(qty_button_pressed)
	btn100.toggled.connect(qty_button_pressed)
	$Panel/TypesContainer/arcane.pressed.connect(show_runes_for_element.bind("arcane"))
	$Panel/TypesContainer/healing.pressed.connect(show_runes_for_element.bind("life"))
	$Panel/TypesContainer/earth.pressed.connect(show_runes_for_element.bind("earth"))

func show_runes_for_element(element: String):
	# clear them first
	if (%VBoxContainer.get_children()):
		for child in %VBoxContainer.get_children():
			child.queue_free()
	# Now instantiate them
	for rune in RuneDatabase.runes.values():
		if rune.rune_type == element:
			var item = rune_button.instantiate()
			item.setup(rune, main, main_menu, self)
			%VBoxContainer.add_child(item)


func qty_button_pressed(toggled) -> void:
	if !toggled: return
	var button_pressed = button_group.get_pressed_button()
	match button_pressed.name:
		btn1.name:
			buy_multiplier = 1
		btn10.name: 
			buy_multiplier = 10
		btn100.name:
			buy_multiplier = 100
		_:
			buy_multiplier = 1

func buy_rune(rune:RuneData) -> void:
	var player_total_gold = main.game_data.current_gold
	var individual_cost = rune.buy_cost
	
	# How many the player *can afford*
	var can_afford = int(player_total_gold / individual_cost)
	# Final quantity is whichever is lowest -- can be 0. which is how we know they didnt have money
	var to_buy = min(buy_multiplier, can_afford)
	var final_cost = to_buy * individual_cost
	var partial_buy = (individual_cost * buy_multiplier) > player_total_gold
	
	if (to_buy >= 1):
		player_total_gold -= final_cost
		main.game_data.current_gold -= final_cost
		main_menu.update_info_panel()
		main.game_data.add_rune_to_inv(rune, to_buy)
		main.save_game()
		if (partial_buy):
			#npcRef.partial_transaction_successful()
			print("Partial buy: ", partial_buy, " for: ", final_cost )
		else:
			#npcRef.dialogue_successful_purchase()
			print("Success! Bought: ", to_buy, " for: ", final_cost )
	else:
		print("Not enough gold")
