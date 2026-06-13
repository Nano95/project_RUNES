extends Node

var monsters = {
	"area1": area1,
	"area2": area2,
	"area3": area3,
	"area4": area4,
	"area5": area5
}
var area1:Array = [
	preload("res://Scripts/Resources/Monsters/a1_1.tres"),
	preload("res://Scripts/Resources/Monsters/a1_2.tres"),
	preload("res://Scripts/Resources/Monsters/a1_3.tres"),
	preload("res://Scripts/Resources/Monsters/a1_4.tres")
]
var area2:Array = [
	preload("res://Scripts/Resources/Monsters/a2_1.tres"),
	preload("res://Scripts/Resources/Monsters/a2_2.tres"),
	preload("res://Scripts/Resources/Monsters/a2_3.tres"),
	preload("res://Scripts/Resources/Monsters/a2_4.tres")
]
var area3:Array = [
	preload("res://Scripts/Resources/Monsters/a3_1.tres"),
	preload("res://Scripts/Resources/Monsters/a3_2.tres"),
	preload("res://Scripts/Resources/Monsters/a3_3.tres"),
	preload("res://Scripts/Resources/Monsters/a3_4.tres")
]
var area4:Array = [
	preload("res://Scripts/Resources/Monsters/a4_1.tres"),
	preload("res://Scripts/Resources/Monsters/a4_2.tres"),
	preload("res://Scripts/Resources/Monsters/a4_3.tres"),
	preload("res://Scripts/Resources/Monsters/a4_4.tres")
]
var area5:Array = [
	preload("res://Scripts/Resources/Monsters/a5_1.tres"),
	preload("res://Scripts/Resources/Monsters/a5_2.tres"),
	preload("res://Scripts/Resources/Monsters/a5_3.tres"),
	preload("res://Scripts/Resources/Monsters/a5_4.tres"),
]

func get_monster(family:String, index) -> MonsterBase:
	return monsters[family][index]

func get_monsters_for_family(family:String) -> Array:
	return monsters[family]

var monster_stage_cost = {
	"area1": 0,
	"area2": 1500,
	"area3": 5000,
	"area4": 12000,
	"area5": 28000
}

var monster_colors = {
	"area1": {
		"col1": Vector3(.516, .691, .473),
		"col2": Vector3(.633, .793, .543),
	},
	"area2": {
		"col1": Vector3(.297, .211, .09),
		"col2": Vector3(.355, .285, .133),
	},
	"area3": {
		"col1": Vector3(.445, .488, .449),
		"col2": Vector3(.664, .723, .602),
	},
	"area4": {
		"col1": Vector3(0.0, .88, 1.0),
		"col2": Vector3(.6, 1.0, 1.0),
	},	
	"area5": {
		"col1": Vector3(0.22, 0.28, 0.34),
		"col2": Vector3(0.32, 0.40, 0.48),
	},
}

var area_names = {
	"area1": "Dewdrop Fields",
	"area2": "Cave Depths",
	"area3": "Dark Mire",
	"area4": "Frost Ridge",
	"area5": "Storm Cliffs",
}
