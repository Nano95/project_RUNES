extends TextureProgressBar
class_name XpBar

@export var xp_curve:Resource
@export var xp_lbl:Label
var main:MainNode
var game_controller:GameController
var xp_tween:Tween
var initial_prog_scale:Vector2 = Vector2.ZERO

func _ready() -> void:
	initial_prog_scale = scale

func setup(main_node:MainNode, gc:GameController) -> void:
	game_controller = gc
	main = main_node
	game_controller.gained_exp.connect(award_xp)
	update_xp_label()
	animate_xp_gain(0)

func award_xp(xp_gained:int=1) -> void:
	animate_xp_gain(xp_gained) # NOTE WE DO NOT ADD XP HERE

func add_xp(amount: float) -> void:
	main.game_data.current_exp = max(0, main.game_data.current_exp + amount)
	main.game_data.total_exp = max(0, main.game_data.total_exp + amount)
	while (main.game_data.current_exp >= xp_required_for_level(main.game_data.current_level + 1)):
		on_level_up()
	
	update_xp_label()

func animate_xp_gain(amount: float) -> void:
	var current_xp = main.game_data.current_exp
	var new_xp = max(0, current_xp + amount)
	var from_percent: float = xp_to_percent(main.game_data.current_exp, main.game_data.current_level)
	var to_percent: float = xp_to_percent(new_xp, main.game_data.current_level)
	# If XP is decreasing, just tween backwards and apply immediately
	if amount < 0:
		tween_xp_bar(from_percent, to_percent)
		await xp_tween.finished
		add_xp(amount)  # amount is negative
		return

	var xp_to_next = xp_required_for_level(main.game_data.current_level + 1) - main.game_data.current_exp
	# Case 1: Not enough XP to level up
	if (amount < xp_to_next):

		tween_xp_bar(from_percent, to_percent)
		add_xp(amount)
		return
	
	# Case 2: Enough XP to level up
	tween_xp_bar(from_percent, to_percent)

	await xp_tween.finished

	# Apply the xp to level up 
	add_xp(xp_to_next)

	# Continue with leftover XP
	animate_xp_gain(amount - xp_to_next)

func update_xp_label():
	var current = main.game_data.current_exp
	var needed = xp_required_for_level(main.game_data.current_level + 1)
	$XpLabel.text = str(int(current)) + " / " + str(int(needed))

func tween_xp_bar(from: float, to: float) -> void:
	value = from  # explicitly set the start
	xp_tween = create_tween()
	xp_tween.tween_property(self, "value", to, 0.2)

func on_level_up():
	main.game_data.current_level += 1
	main.game_data.current_exp = 0
	main.game_data.available_ap += 5
	main.game_data.check_prestige_unlocked()

	if (main.game_ui_ref.has_method('play_level_up_flash')):
		main.game_ui_ref.play_level_up_flash()
	
	xp_lbl.self_modulate = Color(1.0, 0.988, 0.322, 1.0)
	# apply stat bonuses, show UI, etc.

func xp_required_for_level(level: int) -> float:
	return xp_curve.sample(level)

func xp_to_percent(xp: float, level: int) -> float:
	var required = xp_required_for_level(level + 1)
	return (xp / required) * 100.0

func play_level_up_flash() -> void:
	var t := create_tween()

	# Scale punch (subtle)
	t.tween_property(self, "scale", Vector2(initial_prog_scale.x + 1.2, initial_prog_scale.y + 1.2), 0.15).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_BOUNCE)
	t.tween_property(self, "scale", initial_prog_scale, 0.3).set_delay(0.1).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_BOUNCE)
