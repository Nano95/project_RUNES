extends ColorRect
class_name DebugDisplay

@export var equipmentSystem:EquipmentSystem
@export var debugText: RichTextLabel
@export var closeButton: Button

func _ready() -> void:
	closeButton.pressed.connect(onHide)
	hide()

func onHide() -> void:
	Utils.animate_modal_exit(self)

func open() -> void:
	debugText.bbcode_enabled = true
	debugText.text = buildDebugText()
	Utils.animate_modal_entry(self)

func buildDebugText() -> String:
	var main = Utils.get_main()
	var gd = main.game_data
	var text = ""
	var kills = main.game_data.stats.get("kills", {})
	var areaNames = {
		"Hunting Grounds": "Orcs",
		"Slime Swamps": "Slimes",
		"Sandling Dunes": "Sandlings",
		"Dwarf Stronghold": "Dwarves",
	}

	text += "[color=#f8d034][b]PLAYER[/b][/color]\n"
	text += "Gold: %d | Saved: %d\n" % [gd.gold, gd.savedGold]
	text += "Weight: %.1f/%.1f\n" % [gd.currentWeight, gd.maxWeight]
	text += "\n[color=#f8d034][b]STATS[/b][/color]\n"
	text += "Deaths: %d\n" % main.game_data.stats.get("deaths", 0)
	text += "Total Gold Earned: %d\n" % main.game_data.stats.get("totalGoldEarned", 0)
	text += "\n[color=#f8d034]Kills:[/color]\n"
	
	# Total race kills
	text += "[color=#c2a73e][b]RACE TOTALS[/b][/color]\n"
	for area in areaNames:
		var total = 0
		var monsters = MonsterRegistry.getMonstersForArea(area)
		for monsterName in monsters:
			total += kills.get(monsterName, 0)
		text += "%s: %d\n" % [areaNames[area], total]
	text += "\n"
	
	# Individual monster kills
	for monster in main.game_data.stats.get("kills", {}):
		text += "  %s: %d\n" % [monster, main.game_data.stats["kills"][monster]]

	text += "\n[color=#f8d034][b]BACKPACK[/b][/color] (%d items)\n" % gd.backpack.size()
	for stack in gd.backpack:
		if stack.get("isEquipment", false):
			var grade = stack.get("grade", "")
			grade = " [%s]" % grade if (grade != "") else ""
			text += "  [color=#e74c3c]%s%s[/color] +%d\n" % [
				stack.get("name", "?"),
				grade,
				stack.get("enhancement", 0)
			]
		else:
			text += "  %s x%d\n" % [stack.get("name", "?"), stack.get("qty", 1)]

	text += "\n[color=#f8d034][b]CHESTS[/b][/color]\n"
	for chest in gd.chests:
		text += "Chest %d — unlocked:%s items:%d/%d\n" % [
			chest.id,
			str(chest.unlocked),
			chest.items.size(),
			15 + (chest.upgradeLevel * 5)
		]
		for stack in chest.items:
			if stack.get("isEquipment", false):
				var grade = stack.get("grade", "")
				grade = " [%s]" % grade if (grade != "") else ""
				text += "  [color=#e74c3c]%s%s[/color] +%d\n" % [
					stack.get("name", "?"),
					grade,
					stack.get("enhancement", 0)
				]
			else:
				text += "  %s x%d\n" % [stack.get("name", "?"), stack.get("qty", 1)]

	text += "\n[color=#f8d034][b]EQUIPPED[/b][/color]\n"
	var slots = ["equippedWeapon", "equippedShield", "equippedArmor", 
				 "equippedHelmet", "equippedLegs", "equippedBoots",
				 "equippedRing", "equippedAmulet"]
	for slot in slots:
		var item = gd.get(slot)
		if item and not item.is_empty():
			text += "  %s: [color=#e74c3c]%s[/color] +%d\n" % [
				slot.replace("equipped", ""),
				item.get("name", "?"),
				item.get("statBonus", 0) + item.get("enhancement", 0)
			]

	text += "\n[color=#f8d034][b]UNLOCKED AREAS[/b][/color]\n"
	for area in gd.unlockedAreas:
		text += "  %s\n" % area

	return text
	
