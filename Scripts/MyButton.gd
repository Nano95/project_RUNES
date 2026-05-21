extends Control
class_name MyButton



func setup(area:String, is_monster:bool, callable:Callable, new_scale:Vector2=Vector2(1.0, 1.0), show_cost:bool=false) -> void:
	var btn_txt:String = area if (is_monster) else MonsterDatabase.area_names[area]
	$Button.text = str(btn_txt)
	$Button.pressed.connect(callable)
	scale = new_scale
	
	$RichTextLabel.visible = show_cost
	if (!show_cost): return
	var cost:String = str(MonsterDatabase.monster_stage_cost[area])
	$RichTextLabel.text = "[center][img=65]res://Sprites/GOLD_ICON.png[/img]"+cost+"[/center]"
