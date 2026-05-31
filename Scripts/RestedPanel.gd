extends Control
class_name RestedPanel

var main:MainNode
@export var gone_for:Label
@export var gained:Label
@export var info:Label
@export var reset_info:Label
@export var hp_btn:Button
@export var power_btn:Button
@export var focus_btn:Button
@export var xp_btn:Button
@export var outside_btn:Button

signal rested_buff_selected

func _ready() -> void:
	Utils.animate_summary_in_happy(self)
	# Connect all buttons to the same handler
	hp_btn.pressed.connect(func(): select_buff("health"))
	power_btn.pressed.connect(func(): select_buff("power"))
	focus_btn.pressed.connect(func(): select_buff("focus"))
	xp_btn.pressed.connect(func(): select_buff("xp"))
	setup_labels()
	# Reset buff because player will choose a new one
	var rested := main.game_data.rested_data
	rested.active_buff = ""
	rested.battles_left = 0

func setup(m:MainNode) -> void:
	main = m

func setup_labels() -> void:
	var rested := main.game_data.rested_data

	# Time gone (already calculated earlier)
	var last = rested.last_logout_time
	var now := Time.get_unix_time_from_system()
	var elapsed = now - last
	print("Elapsed: ", elapsed)
	var formatted_time := Utils.format_time(elapsed)
	print("Formatted: ", formatted_time)
	# Charges gained (0–10)
	var calc_charges:int = rested.charges

	# Fill labels
	gone_for.text = "You were gone for:  " + formatted_time
	if (calc_charges >= rested.max_charges):
		calc_charges = rested.max_charges
		gained.text = "You gained:  " + str(calc_charges) + " (maxed) Rested Charges"
	else:
		gained.text = "You gained:  " + str(calc_charges) + " Rested Charges"
	
	info.text = "Choose a Rested Blessing (+50%) for your next " + str(calc_charges) + " battles:"
	reset_info.text = "If you're gone for " + str(rested.minutes_per_charge) + " minutes or more, your current blessing will reset."

func select_buff(type:String) -> void:
	# Update save data
	main.game_data.rested_data.active_buff = type
	main.game_data.rested_data.battles_left = main.game_data.rested_data.charges
	main.game_data.rested_data.charges = 0
	
	emit_signal("rested_buff_selected")
	# Close the panel
	Utils.animate_summary_out_and_free(self)

func warn_player() -> void:
	Utils.warn_shake_node(self)
