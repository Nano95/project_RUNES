extends Node

var runes: Dictionary = {}

func _ready():
	_load_runes()

func _load_runes():
	# Attack runes
	runes["Arcane Strike"] = preload("res://Scripts/Resources/Runes/ArcaneStrikeRune.tres")
	runes["Arcane Cross"] = preload("res://Scripts/Resources/Runes/ArcaneCrossRune.tres")
	runes["Arcane Explosion"] = preload("res://Scripts/Resources/Runes/ArcaneExplosionRune.tres")
	runes["Earth Strike"] = preload("res://Scripts/Resources/Runes/EarthStrikeRune.tres")
	runes["Earth Cross"] = preload("res://Scripts/Resources/Runes/EarthCrossRune.tres")
	runes["Earth Explosion"] = preload("res://Scripts/Resources/Runes/EarthExplosionRune.tres")
	runes["Electric Strike"] = preload("res://Scripts/Resources/Runes/ElectricStrikeRune.tres")
	runes["Electric Cross"] = preload("res://Scripts/Resources/Runes/ElectricCrossRune.tres")
	runes["Electric Explosion"] = preload("res://Scripts/Resources/Runes/ElectricExplosionRune.tres")
	# Healing rune
	runes["Light Healing"] = preload("res://Scripts/Resources/Runes/LightHealingRune.tres")
	runes["Great Healing"] = preload("res://Scripts/Resources/Runes/GreatHealingRune.tres")
