extends Resource
class_name MonsterBase

@export var name: String
@export var max_hp: int
@export var power: int  # contributes to turn-attack damage
@export var exp_reward: int

@export var gold_chance: float = 0.75
@export var min_gold_reward: int
@export var max_gold_reward: int

'''arcane > electric > fire > ice > earth > arcane
Arcane beats Lightning (order beats chaos)
electric beats Fire (energy overloads flame)
Fire beats Ice (melts it)
Ice beats Poison (freezing stops toxins)
earth beats Arcane (corruption beats purity)
'''
@export var essence_type: String  # "fire", "earth", etc.
@export var min_essence_amount: int
@export var max_essence_amount: int

@export var attack_speed: int = 4  # normal monsters default to 4
@export var is_elite: bool = false
@export var is_boss: bool = false

@export var anim_offset_y:int
@export var anim_name: String
@export var rarity: int = 1  # 1=common, 2=elite, 3=boss

@export var equipment_chance: float = 0.02
@export var equipment_pool: Array[String] = []

@export var weaknesses: Array[String] = [""]
@export var resistances: Array[String] = [""]
@export var immunities: Array[String] = [""]
