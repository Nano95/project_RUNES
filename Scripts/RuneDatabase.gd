extends Node

var runes: Dictionary = {}

func _ready():
	_load_runes()

func _load_runes():
	# Attack runes
	runes["arcane_strike"] = preload("res://Scripts/Resources/Runes/ArcaneStrikeRune.tres")

	runes["arcane_cross"] = preload("res://Scripts/Resources/Runes/ArcaneCrossRune.tres")

	runes["arcane_explosion"] = preload("res://Scripts/Resources/Runes/ArcaneExplosionRune.tres")

	# Healing rune
	runes["great_healing"] = preload("res://Scripts/Resources/Runes/GreatHealingRune.tres")
