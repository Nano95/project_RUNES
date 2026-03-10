extends Panel
class_name MonsterInfoPanel

@export var hp_lbl:Label
@export var xp_lbl:Label
@export var atk_lbl:Label
@export var gold_lbl:Label
@export var essence_lbl:Label
@export var name_lbl:Label
@export var desc_lbl:Label
@export var loot_lbl:Label
@export var essence_icon:TextureRect

func update_panel(monster:MonsterBase) -> void:
	hp_lbl.text = str(monster.max_hp)
	xp_lbl.text = str(monster.exp_reward)
	atk_lbl.text = str(monster.power)
	gold_lbl.text = str(monster.min_gold_reward, "-", monster.max_gold_reward)
	essence_lbl.text = str(monster.min_essence_amount, "-", monster.max_essence_amount)
	name_lbl.text = monster.name
	var essence_type:String = "res://Sprites/" + monster.essence_type + "_ESSENCE_ICON.png"
	essence_icon.texture = load(essence_type)
	#desc_lbl.text = monster.description
	#loot_lbl.text = monster.loot_lbl
