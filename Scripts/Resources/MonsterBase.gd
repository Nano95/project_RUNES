extends Resource
class_name MonsterBase

@export var name: String
@export var max_hp: int
@export var power: int  # contributes to turn-attack damage
@export var exp_reward: int
@export var gold_reward: int

@export var essence_type: String  # "fire", "earth", etc.
@export var min_essence_amount: int
@export var max_essence_amount: int

@export var attack_speed: int = 3  # normal monsters default to 3
@export var is_elite: bool = false
@export var is_boss: bool = false

@export var anim_offset_y:int
@export var anim_name: String
@export var rarity: int = 1  # 1=common, 2=elite, 3=boss
