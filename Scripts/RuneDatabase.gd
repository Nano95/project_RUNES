extends Node

var runes: Dictionary = {}

func _ready():
	_load_runes()

func _load_runes():
	# Attack runes
	runes["single"] = preload("res://Scripts/Resources/Runes/SinglePhysicalRune.tres")

	runes["plus"] = preload("res://Scripts/Resources/Runes/PlusPhysicalRune.tres")

	runes["aoe3"] = preload("res://Scripts/Resources/Runes/Aoe3PhysicalRune.tres")

	# Healing rune
	runes["heal"] = preload("res://Scripts/Resources/Runes/GreatHealingRune.tres")
