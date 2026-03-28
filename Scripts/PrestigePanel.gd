extends Control
class_name PrestigePanel

@export var prestige_card:PackedScene
@export var grid_container:GridContainer
@export var title:Label
@export var back_btn:Button
@export var next_btn:Button
@export var upgrades_btn:Button
@export var blessings_btn:Button
@export var curses_btn:Button

var main:MainNode

func _ready() -> void:
	setup_blessings()
	upgrades_btn.pressed.connect(open_upgrades)
	blessings_btn.pressed.connect(open_blessings)
	curses_btn.pressed.connect(open_curses)

func setup(m:MainNode) -> void:
	main = m

func setup_blessings() -> void:
	clear_cards()
	populate_cards(main.game_data.blessings, true)

func setup_curses() -> void:
	clear_cards()
	populate_cards(main.game_data.curses, false)

func populate_cards(arr:Array, is_blessing:bool=true) -> void:
	# Arr of dictionaries
	for dict in arr:
		var card = prestige_card.instantiate()
		card.setup(main, is_blessing, dict)
		grid_container.add_child(card)

func open_upgrades()-> void:
	upgrades_btn.disabled = true
	blessings_btn.disabled = false
	curses_btn.disabled = false
	play_selected(upgrades_btn)

func open_blessings() -> void:
	upgrades_btn.disabled = false
	blessings_btn.disabled = true
	curses_btn.disabled = false
	play_selected(blessings_btn)
	setup_blessings()

func open_curses() -> void:
	upgrades_btn.disabled = false
	blessings_btn.disabled = false
	curses_btn.disabled = true
	play_selected(curses_btn)
	setup_curses()

func play_selected(btn:Button) -> void:
	var og_y_pos:float = btn.position.y
	var t := create_tween()
	t.set_parallel(false).tween_property(btn, "position:y", btn.position.y - 10, 0.15)\
		.set_trans(Tween.TRANS_CUBIC)\
		.set_ease(Tween.EASE_OUT)
	t.tween_property(btn, "position:y", og_y_pos, 0.15)\
		.set_trans(Tween.TRANS_CUBIC)\
		.set_ease(Tween.EASE_OUT)

func clear_cards() -> void:
	for card in grid_container.get_children():
		card.queue_free()
