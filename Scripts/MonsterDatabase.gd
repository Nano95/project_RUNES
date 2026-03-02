extends Node

var monsters = {
	"slimes": slimes,
	"orcs": orcs,
	"sandlings": sandlings,
	"dwarves": dwarves
}
var slimes := [
	preload("res://Scripts/Resources/Monsters/Slime1.tres"),
	preload("res://Scripts/Resources/Monsters/Slime2.tres"),
	preload("res://Scripts/Resources/Monsters/Slime3.tres"),
	preload("res://Scripts/Resources/Monsters/Slime4.tres")	
]
var orcs := [
	preload("res://Scripts/Resources/Monsters/Orc1.tres"),
	preload("res://Scripts/Resources/Monsters/Orc2.tres"),
	preload("res://Scripts/Resources/Monsters/Orc3.tres"),
	preload("res://Scripts/Resources/Monsters/Orc4.tres")
]
var sandlings := [
	preload("res://Scripts/Resources/Monsters/Sandling1.tres"),
	preload("res://Scripts/Resources/Monsters/Sandling2.tres"),
	preload("res://Scripts/Resources/Monsters/Sandling3.tres"),
	preload("res://Scripts/Resources/Monsters/Sandling4.tres")
]
var dwarves := [
	preload("res://Scripts/Resources/Monsters/Dwarf1.tres"),
	preload("res://Scripts/Resources/Monsters/Dwarf2.tres"),
	preload("res://Scripts/Resources/Monsters/Dwarf3.tres"),
	preload("res://Scripts/Resources/Monsters/Dwarf4.tres")
]

func get_monster(family:String, index) -> MonsterBase:
	return monsters[family][index]

func get_monsters_for_family(family:String) -> Array:
	return monsters[family]

var monster_stage_cost = {
	"slimes": 0,
	"orcs": 300,
	"sandlings": 1800,
	"dwarves": 10000
}

var monster_colors = {
	"slimes": {
		"col1": Vector3(.516, .691, .473),
		"col2": Vector3(.633, .793, .543),
	},
	"orcs": {
		"col1": Vector3(.445, .488, .449),
		"col2": Vector3(.664, .723, .602),
	},
	"sandlings": {
		"col1": Vector3(.875, .652, .367),
		"col2": Vector3(.973, .836, .535
		),
	},
	"dwarves": {
		"col1": Vector3(.297, .211, .09),
		"col2": Vector3(.355, .285, .133),
	},
}
