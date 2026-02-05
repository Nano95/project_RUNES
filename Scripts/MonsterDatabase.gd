extends Node

var monsters = {
	"orcs": orcs
}
var orcs := [
	preload("res://Scripts/Resources/Monsters/Orc1.tres"),
	preload("res://Scripts/Resources/Monsters/Orc2.tres"),
	preload("res://Scripts/Resources/Monsters/Orc3.tres"),
	preload("res://Scripts/Resources/Monsters/Orc4.tres")
]

func get_monster(family:String, index) -> MonsterBase:
	return monsters[family][index]
