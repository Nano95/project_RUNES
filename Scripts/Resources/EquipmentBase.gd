extends Resource
class_name EquipmentBase

@export var name: String
@export var base_stats := {
	"health": 0,
	"focus": 0,
	"power": 0,
	"luck": 0,
}

@export var allowed_mods := ["health", "focus", "power", "luck"]
@export var icon: Texture2D
@export var synergy_tags := []  # e.g. ["fire", "focus", "boots"]
"""
if item1.base.synergy_tags.has("focus") and item2.base.synergy_tags.has("focus"):
    # apply synergy bonus
"""
