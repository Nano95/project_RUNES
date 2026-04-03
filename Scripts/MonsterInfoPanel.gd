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
	var mod_hp:int = Utils.calculate_monster_hp(monster.max_hp)
	hp_lbl.text = str(mod_hp)
	xp_lbl.text = str(Utils.calculate_reward(monster.exp_reward, "exp"))
	atk_lbl.text = str(monster.power)
	var min_gold_mod = Utils.calculate_reward(monster.min_gold_reward, "gold")
	var max_gold_mod = Utils.calculate_reward(monster.max_gold_reward, "gold")
	gold_lbl.text = str(min_gold_mod, "-", max_gold_mod)
	var min_essence_mod = Utils.calculate_reward(monster.min_essence_amount, "essences")
	var max_essence_mod = Utils.calculate_reward(monster.max_essence_amount, "essences")
	essence_lbl.text = str(min_essence_mod, "-", max_essence_mod)
	name_lbl.text = monster.name
	var essence_type:String = "res://Sprites/" + monster.essence_type + "_ESSENCE_ICON.png"
	essence_icon.texture = load(essence_type)
	#desc_lbl.text = monster.description
	#loot_lbl.text = monster.loot_lbl
