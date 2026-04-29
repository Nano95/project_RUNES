extends Control
class_name PrestigePanel

@export var skill_upgrade_ui:PackedScene
@export var prestige_card:PackedScene
@export var confirmation_panel:PackedScene
@export var upgrades_v_container:VBoxContainer
@export var grid_container:GridContainer
@export var title:Label
@export var info_panel:Panel
@export var upgrades_panel:Panel
@export var buff_debuff_panel:Panel

@export_category("Initial")
@export var requirement_label:Label
@export var begin_ascension_btn:Button

@export_category("Upgrades")
@export var count_lbl:RichTextLabel
@export_category("Blessings")
@export var blessings_container:Control
@export var ap_count_lbl:RichTextLabel
@export var undo_blessings_btn:Button
@export var blessing_bottom_info:Label
@export_category("Curse")
@export var curses_container:Control
@export var complete_ascension_btn:Button
@export var curse_bottom_info:Label

@export_category("Nav")
@export var upgrades_btn:Button
@export var blessings_btn:Button
@export var curses_btn:Button

var prestige_in_process:bool = false
var in_debug_mode:bool = false
var main:MainNode
var TOTAL_UPGRADE_COUNT_AVAILABLE:int
var temp_upgrades:Dictionary = {
	"arcane": 0,
	"earth": 0,
	"electric": 0,
	"fire": 0,
	"ice": 0
}
var temp_blessings:Array = []
var temp_curses:Array = []
var blessing_coins_available:int
var blessing_coins_spent:int = 0

func _ready() -> void:
	upgrades_btn.pressed.connect(open_upgrades)
	blessings_btn.pressed.connect(open_blessings)
	curses_btn.pressed.connect(open_curses)
	undo_blessings_btn.pressed.connect(setup_blessings.bind(true))
	complete_ascension_btn.pressed.connect(complete_ascension)
	
	if (in_debug_mode): 
		open_upgrades() # No need to see info panel in debug mode.
		return
	
	init_temp_upgrades()
	initialize_temp_blessings()
	initialize_temp_curses()
	if (check_prestige_requirements()):
		info_panel.visible = true
		upgrades_panel.visible = false
		buff_debuff_panel.visible = false
		disable_all_nav_buttons()
		begin_ascension_btn.pressed.connect(open_upgrades)
		TOTAL_UPGRADE_COUNT_AVAILABLE = get_invested_points() + (3 * (main.game_data.prestige_level + 1))
	else:
		# Need to allow the menu to be seen without being interacted with.
		open_upgrades()

func setup(m:MainNode, is_debug:bool=false) -> void:
	main = m
	in_debug_mode = is_debug

func check_prestige_requirements() -> bool:
	var required = main.game_data.get_ascension_level()
	var requirements_met:bool = main.game_data.prestige_unlocked
	if (requirements_met):
		# Player can begin the prestige sequence
		requirement_label.text = "Level %d has been reached!" % required
		begin_ascension_btn.pressed.connect(begin_ascension_process)
	else:
		requirement_label.text = "Reach level %d to prestige" % required
	
	begin_ascension_btn.disabled = !requirements_met
	return requirements_met

func begin_ascension_process() -> void:
	prestige_in_process = true
	upgrades_panel.visible = true
	info_panel.visible = false

func update_count_label() -> void:
	if (!main.game_data.prestige_unlocked):
		count_lbl.hide()
		return
	var spent := 0
	for key in temp_upgrades.keys():
		spent += main.game_data.element_upgrades[key] + temp_upgrades[key]
	var remaining := TOTAL_UPGRADE_COUNT_AVAILABLE - spent
	
	if (remaining > 0):
		count_lbl.text = "[center]You have [color=#7CFF7C]%d[/color] point(s) left[/center]" % remaining
		blessings_btn.disabled = true
		curses_btn.disabled = true
	else:
		count_lbl.text = "[center]When you're ready, continue![/center]"
		blessings_btn.disabled = false

func setup_blessings(reset:bool=false) -> void:
	clear_cards()
	if (in_debug_mode):
		populate_cards(main.game_data.blessings, true)
	else:
		if (reset): initialize_temp_blessings() # Will reset things.
		populate_cards(temp_blessings, true)
	
	if (!main.game_data.prestige_unlocked):
		ap_count_lbl.hide()
		blessing_bottom_info.hide()
		undo_blessings_btn.hide()

func setup_curses() -> void:
	clear_cards()
	if (in_debug_mode):
		populate_cards(main.game_data.curses, false)
	else:
		populate_cards(temp_curses, false)
	
	if (!main.game_data.prestige_unlocked):
		curse_bottom_info.hide()
		complete_ascension_btn.hide()

func populate_cards(arr:Array, is_blessing:bool=true) -> void:
	# Arr of dictionaries
	var i:int=0
	for dict in arr:
		var card = prestige_card.instantiate()
		card.setup(main, self, is_blessing, dict, i)
		grid_container.add_child(card)
		i += 1

func open_upgrades()-> void:
	upgrades_btn.disabled = false
	play_selected(upgrades_btn)
	setup_upgrades()
	update_count_label()
	info_panel.visible = false
	upgrades_panel.visible = true
	buff_debuff_panel.visible = false

func open_blessings() -> void:
	play_selected(blessings_btn)
	info_panel.visible = false
	upgrades_panel.visible = false
	buff_debuff_panel.visible = true
	blessings_container.visible = true
	curses_container.visible = false
	setup_blessings()
	curses_btn.disabled = false

func open_curses() -> void:
	play_selected(curses_btn)
	upgrades_panel.visible = false
	info_panel.visible = false
	buff_debuff_panel.visible = true
	blessings_container.visible = false
	curses_container.visible = true
	setup_curses()

func setup_upgrades() -> void:
	clear_upgrades()
	var elements:Array=["arcane", "earth", "electric", "fire", "ice"]
	for element in elements:
		var upgrades = skill_upgrade_ui.instantiate()
		upgrades.setup(main, self, element, in_debug_mode)
		upgrades_v_container.add_child(upgrades)

func try_adjust_upgrade(element:String, delta:int) -> int:
	var current_total_spent := 0

	# Calculate total spent including temp upgrades
	for key in temp_upgrades.keys():
		current_total_spent += main.game_data.element_upgrades[key] + temp_upgrades[key]

	var new_total_spent := current_total_spent + delta

	# Prevent going below zero for this element
	if (main.game_data.element_upgrades[element] + temp_upgrades[element] + delta < 0):
		return -1

	# Prevent exceeding total allowed
	if (new_total_spent > TOTAL_UPGRADE_COUNT_AVAILABLE):
		return -1

	# Apply the change
	temp_upgrades[element] += delta
	update_count_label()
	return temp_upgrades[element]

func get_invested_points() -> int:
	var points:int = 0
	for key in main.game_data.element_upgrades.keys():
		points += main.game_data.element_upgrades[key]
	return points

func disable_all_nav_buttons() -> void:
	upgrades_btn.disabled = true
	blessings_btn.disabled = true
	curses_btn.disabled = true

func init_temp_upgrades() -> void:
	for key in main.game_data.element_upgrades.keys():
		temp_upgrades[key] += main.game_data.element_upgrades[key]

func initialize_temp_blessings() -> void:
	temp_blessings = []
	for b in main.game_data.blessings:
		temp_blessings.append(b.duplicate(true)) # deep copy - does not modify the og data
	# Blessing currency = permanent + current level
	blessing_coins_available = main.game_data.blessing_coins + main.game_data.current_level
	blessing_coins_spent = 0
	update_blessing_coins_label()

func initialize_temp_curses() -> void:
	temp_curses = []
	for b in main.game_data.curses:
		temp_curses.append(b.duplicate(true)) # deep copy - does not modify the og data

func blessing_coins_left() -> int:
	return blessing_coins_available - blessing_coins_spent

func update_blessing_coins_label() -> void:
	var remaining:int = blessing_coins_left()
	if (remaining > 0):
		ap_count_lbl.text = "[center]You have [color=#7CFF7C]%d[/color] AP(s)[/center]" % remaining
	else:
		ap_count_lbl.text = "[center]You have %d APs[/center]" % remaining

func try_purchase_blessing(id:String) -> bool:
	var blessing = get_temp_blessing(id)
	if (blessing.cost > blessing_coins_left()):
		Utils.warn_shake_node(ap_count_lbl)
		return false
	
	blessing.locked = false
	blessing_coins_spent += blessing.cost
	update_blessing_coins_label()
	return true

func get_temp_blessing(id:String) -> Dictionary:
	for b in temp_blessings:
		if b.id == id:
			return b
	return {}

func complete_ascension() -> void:
	var pnl = confirmation_panel.instantiate()
	var pnl_title:String = "Are you sure?"
	var desc:String = "You cannot modify your upgrades and blessings until your next ascension!\
	\n\nNext ascension level at: Lv. %d" % main.game_data.get_ascension_level(1)
	pnl.setup(commit_and_ascend, pnl_title, desc, true)
	main.spawn_to_top_ui_layer(pnl)
	# No actually pop open a modal saying ARE YOU SURE YOU ARE DONE? Next ASC is at max lvl x

func commit_and_ascend() -> void:
	commit_upgrades()
	commit_blessings()
	commit_curses()
	main.game_data.ascension_restart_data()
	main.save_game()
	call_deferred("restart_scene")

func restart_scene() -> void:
	get_tree().reload_current_scene()

# When prestige is complete, commit all of the upgrades!
func commit_upgrades():
	for key in temp_upgrades.keys():
		main.game_data.element_upgrades[key] = temp_upgrades[key]

func commit_blessings():
	for i in temp_blessings.size():
		main.game_data.blessings[i] = temp_blessings[i]
	# Update permanent blessing currency
	main.game_data.blessing_coins = blessing_coins_left()

func commit_curses():
	for i in temp_curses.size():
		main.game_data.curses[i] = temp_curses[i]
	
func clear_cards() -> void:
	for card in grid_container.get_children():
		card.queue_free()

func clear_upgrades() -> void:
	for upgrade in upgrades_v_container.get_children():
		upgrade.queue_free()

func play_selected(btn:Button) -> void:
	var og_y_pos:float = btn.position.y
	var t := create_tween()
	t.set_parallel(false).tween_property(btn, "position:y", btn.position.y - 10, 0.15)\
		.set_trans(Tween.TRANS_CUBIC)\
		.set_ease(Tween.EASE_OUT)
	t.tween_property(btn, "position:y", og_y_pos, 0.15)\
		.set_trans(Tween.TRANS_CUBIC)\
		.set_ease(Tween.EASE_OUT)
