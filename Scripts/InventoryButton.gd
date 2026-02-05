extends Panel
class_name InventoryButton

@warning_ignore("unused_signal")
signal equip_button_pressed

func _ready() -> void:
	$Button.pressed.connect(emit_signal.bind('equip_button_pressed'))

func update_button_icon(equip_on:bool = false, slot_num:String="1") -> void:
	$Button.text = slot_num if (equip_on) else "N"

func set_item(item: EquipmentInstance) -> void:
	var rarity_color = Utils.get_rarity_color(item.rarity)
	$Name.modulate = rarity_color
	$Name.text = item.base.name
	$Rarity.text = item.rarity
	$Rarity.modulate = rarity_color
	$Level.text = "Lv. %d" % item.level
	$Icon.texture = item.base.icon

	var stats = item.get_total_stats()
	var parts: Array[String] = []

	for stat_name in stats.keys():
		var value = stats[stat_name]
		if value != 0:
			parts.append(format_stat(stat_name, value))

	# Join with commas
	$Description.text = String(", ").join(parts)

func format_stat(stat_name: String, value: float) -> String:
	var color = Utils.PASTEL_GREEN if (value >= 0) else Utils.PASTEL_RED
	@warning_ignore("shadowed_global_identifier")
	var sign = "+" if (value >= 0) else ""

	# returns [color=#99ff99]+20 Power[/color] as an example 
	return "[color=%s]%s%s %s[/color]" % [
		color.to_html(),
		sign,
		value,
		stat_name.capitalize()
	]
