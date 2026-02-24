extends Control
class_name MyButton



func setup(fam:String, callable:Callable, new_scale:Vector2=Vector2(1.0, 1.0), show_cost:bool=false) -> void:
	$Button.text = str(fam.capitalize())
	$Button.pressed.connect(callable)
	scale = new_scale
	
	$RichTextLabel.visible = show_cost
	if (!show_cost): return
	var cost:String = str(MonsterDatabase.monster_stage_cost[fam])
	$RichTextLabel.text = "[center][img=65]res://Sprites/GOLD_ICON.png[/img]"+cost+"[/center]"
