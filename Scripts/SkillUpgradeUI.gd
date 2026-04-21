extends Control
class_name SkillUpgradeUI

var main:MainNode
var skill_type:String="health"
var prestige_panel:PrestigePanel
@export var icon_sprite:TextureRect
@export var sprite:Sprite2D
@export var arcane_icon:Texture
@export var earth_icon:Texture
@export var electric_icon:Texture
@export var fire_icon:Texture
@export var ice_icon:Texture

func _ready() -> void:
	$Panel/add.pressed.connect(update_skill.bind(skill_type, 1))
	$Panel/subtract.pressed.connect(update_skill.bind(skill_type, -1))
	initialize_component()

func setup(m:MainNode, parent:PrestigePanel, t:String) -> void:
	main = m
	skill_type = t
	prestige_panel = parent

func initialize_component() -> void:
	match skill_type:
		"arcane":
			icon_sprite.texture = load(arcane_icon.resource_path)
		"earth":
			icon_sprite.texture = load(earth_icon.resource_path)
		"electric":
			icon_sprite.texture = load(electric_icon.resource_path)
		"fire":
			icon_sprite.texture = load(fire_icon.resource_path)
		"ice":
			icon_sprite.texture = load(ice_icon.resource_path)
		_:
			pass
	
	var curr_lvl:int = prestige_panel.temp_upgrades[skill_type]
	if (curr_lvl >= sprite.vframes - 1): curr_lvl = sprite.vframes - 1
	if (curr_lvl < 0): curr_lvl = 0
	sprite.frame = curr_lvl

# ASK AI, how to use this so we can update the sprite based on the new temp level

func update_skill(skill:String, delta:int) -> void:
	var new_level = prestige_panel.try_adjust_upgrade(skill, delta)
	print("New Level: ", new_level)
	if (new_level == -1): return
	if (new_level >= sprite.vframes - 1): new_level = sprite.vframes - 1
	if (new_level < 0): new_level = 0
	sprite.frame = new_level
	
#func update_skill_sprite(subtract:bool=false) -> void:
	#var curr_lvl:int = prestige_panel.temp_upgrades[skill_type]
	#var sum:int = 1
	#if (subtract): sum = -1
	#
	#if (curr_lvl >= sprite.vframes - 1): curr_lvl = sprite.vframes - 1
	#if (curr_lvl < 0): curr_lvl = 0
	#print("sprite frame: ", curr_lvl)
	#sprite.frame = curr_lvl
	
