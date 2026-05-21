extends Node

var monsters = {
	"area1": area1,
	"area2": area2,
	"area3": area3,
	"area4": area4,
	"area5": area5
}
var area1:Array = [
	preload("res://Scripts/Resources/Monsters/Slime1.tres"),
	preload("res://Scripts/Resources/Monsters/Slime2.tres"),
	preload("res://Scripts/Resources/Monsters/Slime3.tres"),
	preload("res://Scripts/Resources/Monsters/Slime4.tres")	
]
var area2:Array = [
	preload("res://Scripts/Resources/Monsters/Orc1.tres"),
	preload("res://Scripts/Resources/Monsters/Orc2.tres"),
	preload("res://Scripts/Resources/Monsters/Orc3.tres"),
	preload("res://Scripts/Resources/Monsters/Orc4.tres")
]
var area3:Array = [
	preload("res://Scripts/Resources/Monsters/Sandling1.tres"),
	preload("res://Scripts/Resources/Monsters/Sandling2.tres"),
	preload("res://Scripts/Resources/Monsters/Sandling3.tres"),
	preload("res://Scripts/Resources/Monsters/Sandling4.tres")
]
var area4:Array = [
	preload("res://Scripts/Resources/Monsters/Dwarf1.tres"),
	preload("res://Scripts/Resources/Monsters/Dwarf2.tres"),
	preload("res://Scripts/Resources/Monsters/Dwarf3.tres"),
	preload("res://Scripts/Resources/Monsters/Dwarf4.tres")
]
var area5:Array = [
	preload("res://Scripts/Resources/Monsters/Jungles1.tres"),
	preload("res://Scripts/Resources/Monsters/Jungles2.tres"),
	preload("res://Scripts/Resources/Monsters/Jungles3.tres"),
	preload("res://Scripts/Resources/Monsters/Jungles4.tres"),
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
		"col1": Vector3(.445, .488, .449),
		"col2": Vector3(.664, .723, .602),
	},
	"area3": {
		"col1": Vector3(.875, .652, .367),
		"col2": Vector3(.973, .836, .535
		),
	},
	"area4": {
		"col1": Vector3(.297, .211, .09),
		"col2": Vector3(.355, .285, .133),
	},	
	"area5": {
		"col1": Vector3(.223, .386, .266),
		"col2": Vector3(.305, .482, .313),
	},
}

var area_names = {
	"area1": "Dewdrop Fields",
	"area2": "Orc Plains",
	"area3": "Sandling Dunes",
	"area4": "Royal Caves",
	"area5": "Forbidden Jungle",
}
