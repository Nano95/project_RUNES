extends Resource
class_name EquipmentBase

@export var name: String
@export var base_stats := {
	"health": 0,
	"speed": 0,
	"power": 0,
	"luck": 0,
}

@export var allowed_mods := ["health", "speed", "power", "luck"]
@export var icon: Texture2D
@export var synergy_tags := []  # e.g. ["fire", "speed", "boots"]
"""
if item1.base.synergy_tags.has("speed") and item2.base.synergy_tags.has("speed"):
    # apply synergy bonus
"""
