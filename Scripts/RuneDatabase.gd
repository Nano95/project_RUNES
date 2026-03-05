extends Node

var runes: Dictionary = {}

func _ready():
	_load_runes()

func _load_runes():
	# Attack runes
	runes["Arcane Strike"] = preload("res://Scripts/Resources/Runes/ArcaneStrikeRune.tres")

	runes["Arcane Cross"] = preload("res://Scripts/Resources/Runes/ArcaneCrossRune.tres")

	runes["Arcane Explosion"] = preload("res://Scripts/Resources/Runes/ArcaneExplosionRune.tres")

	# Healing rune
	runes["Great Healing"] = preload("res://Scripts/Resources/Runes/GreatHealingRune.tres")
