extends Control
class_name RewardPopup

@export var ctrl:Control
@export var lbl:RichTextLabel

var duration := 2.0  # seconds
var rise_distance := 140  # pixels upward

func show_reward(rune:RuneData, rune_qty:int) -> void:
	# Build BBCode string
	var essence_qty :int = rune_qty * rune.essence_cost
	var essence_icon = "res://Sprites/" + rune.essence_type + "_ESSENCE_ICON.png"
	var text := ""
	text += "[img=128x128]%s[/img]" % rune.icon.resource_path
	text += "[color=%s]+%d[/color]   " % [Utils.PASTEL_GREEN.to_html(), rune_qty]
	text += "[img=128x128]%s[/img]" % essence_icon
	text += "[color=%s]-%d[/color]" % [Utils.PASTEL_RED.to_html(), essence_qty]
	text = "[center]" + text + "[/center]"
	lbl.text = text

	# Start animation
	animate_popup()


func animate_popup() -> void:
	var tween := create_tween()

	# Move upward
	tween.tween_property(ctrl, "global_position:y", global_position.y - rise_distance, duration - (duration*.3)).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_CUBIC)

	# Fade out
	tween.parallel().tween_property(lbl, "modulate:a", 0.0, duration + .5)

	# Free when done
	tween.tween_callback(Callable(self, "queue_free"))
