extends Node
class_name EquipmentSystem

@export var inventorySystem: InventorySystem
@export var chestSystem: ChestSystem

var main:MainNode

func _ready() -> void:
	main = Utils.get_main()
	GameEvents.checkpointReached.connect(onCheckpointReached)
	GameEvents.tickFired.connect(onTick)
	GameEvents.itemEquipped.connect(onItemEquipped)

# ── EQUIP / UNEQUIP ───────────────────────────────────────
func equipItem(instance: Dictionary) -> void:
	
	var slot = instance.get("slot", "")
	if slot == "":
		return

	# Two handed weapon check
	if instance.get("twoHanded", false):
		# Unequip shield if equipping two handed
		if not main.game_data.equippedShield.is_empty():
			unequipSlot("shield")

	# Shield check — cant equip shield with two handed weapon
	if slot == "shield":
		var weapon = main.game_data.equippedWeapon
		if not weapon.is_empty() and weapon.get("twoHanded", false):
			GameEvents.eventLogged.emit(
				"Can't equip a shield with a two-handed weapon.", "system", false
			)
			return

	# Unequip current item in slot first
	unequipSlot(slot)

	# Remove from backpack
	removeInstanceFromBackpack(instance)

	# Equip
	setEquippedSlot(slot, instance)
	main.save_game()
	GameEvents.eventLogged.emit(
		"Equipped %s." % instance["name"], "loot", false
	)
	GameEvents.equipmentChanged.emit()

func unequipSlot(slot: String) -> void:
	
	var current = getEquippedSlot(slot)
	if current.is_empty():
		return
	# Return to backpack
	inventorySystem.addEquipmentToBackpack(current)
	setEquippedSlot(slot, {})
	GameEvents.equipmentChanged.emit()

func getEquippedSlot(slot: String) -> Dictionary:
	
	match slot:
		"weapon": return main.game_data.equippedWeapon
		"shield": return main.game_data.equippedShield
		"armor":  return main.game_data.equippedArmor
		"helmet": return main.game_data.equippedHelmet
		"legs":   return main.game_data.equippedLegs
		"boots":  return main.game_data.equippedBoots
		"ring":   return main.game_data.equippedRing
		"amulet": return main.game_data.equippedAmulet
	return {}

func setEquippedSlot(slot: String, instance: Dictionary) -> void:
	
	match slot:
		"weapon": main.game_data.equippedWeapon = instance
		"shield": main.game_data.equippedShield = instance
		"armor":  main.game_data.equippedArmor = instance
		"helmet": main.game_data.equippedHelmet = instance
		"legs":   main.game_data.equippedLegs = instance
		"boots":  main.game_data.equippedBoots = instance
		"ring":   main.game_data.equippedRing = instance
		"amulet": main.game_data.equippedAmulet = instance

# ── STAT CALCULATIONS ─────────────────────────────────────
func getTotalAttack() -> int:
	var base = 5 + (main.game_data.level)
	var bonus = 0
	for slot in ["equippedWeapon", "equippedRing", "equippedAmulet"]:
		var item = main.game_data.get(slot)
		if not item or item.is_empty():
			continue
		if item.get("statType") == "attack":
			bonus += item.get("statBonus", 0) + item.get("enhancement", 0)
	return base + bonus

func getTotalDefense() -> int:
	var base = 2 + int(main.game_data.level * .3)
	var bonus = 0
	for slot in ["equippedShield", "equippedArmor", "equippedHelmet",
				 "equippedBoots", "equippedLegs", "equippedRing", "equippedAmulet"]:
		var item = main.game_data.get(slot)
		if not item or item.is_empty():
			continue
		if item.get("statType") == "defense":
			bonus += item.get("statBonus", 0) + item.get("enhancement", 0)
	return base + bonus

# ── EFFECTS ───────────────────────────────────────────────
func onCheckpointReached() -> void:
	# Ring of Vitality — heal on checkpoint
	for slot in ["equippedRing", "equippedAmulet"]:
		var item = main.game_data.get(slot)
		if not item or item.is_empty():
			continue
		if item.get("effectType") == "checkpoint_heal":
			var healPct = item.get("effectValue", 0)
			var healAmt = int(main.game_data.maxHp * (healPct / 100.0))
			main.game_data.hp = min(main.game_data.maxHp, main.game_data.hp + healAmt)
			GameEvents.eventLogged.emit(
				"%s pulses. Restored %d HP." % [item["name"], healAmt], "gather", false
			)
			GameEvents.hpChanged.emit()

func onTick() -> void:
	
	if not main.game_data.inArea:
		return
	# Amulet of Regen — heal per tick
	for slot in ["equippedRing", "equippedAmulet"]:
		var item = main.game_data.get(slot)
		if (not item or item.is_empty()):
			continue
		if (item.get("effectType") == "regen"):
			var regenAmt = item.get("effectValue", 0)
			if main.game_data.hp < main.game_data.maxHp:
				main.game_data.hp = min(main.game_data.maxHp, main.game_data.hp + regenAmt)
				GameEvents.hpChanged.emit()

func applyWeaponEffectOnHit() -> void:
	
	var weapon = main.game_data.equippedWeapon
	if weapon.is_empty():
		return
	var effectType = weapon.get("effectType", "none")
	if effectType == "none":
		return
	var effectChance = weapon.get("effectChance", 0.0)
	if randf() > effectChance:
		return
	match effectType:
		"poison":
			GameEvents.poisonApplied.emit(weapon.get("effectValue", 0))
		"stun":
			GameEvents.stunApplied.emit()
		"lifesteal":
			GameEvents.lifeStealApplied.emit(weapon.get("effectValue", 0))

func applyCursedShieldOnHit(incomingDamage: int) -> int:
	
	var shield = main.game_data.equippedShield
	if shield.is_empty() or shield.get("effectType") != "cursed_block":
		return incomingDamage
	if randf() * 100 < shield.get("effectValue", 0):
		GameEvents.eventLogged.emit("Cursed Shield blocks the hit!", "gather", false)
		return 0
	else:
		GameEvents.eventLogged.emit("The curse backfires!", "danger", false)
		return incomingDamage * 2

# ── ENHANCEMENT ───────────────────────────────────────────
func canEnhance(instance: Dictionary) -> bool:
	
	print("_ maxed out? ", instance.get("enhancement", 0) >= 3)
	print("- enough gold? ", main.game_data.savedGold < getEnhancementCost(instance)["gold"])
	if instance.get("enhancement", 0) >= 3:
		return false
	var cost = getEnhancementCost(instance)
	if main.game_data.savedGold < cost["gold"]:
		return false
	for mat in cost["materials"]:
		if inventorySystem.countInBackpack(mat) + \
			chestSystem.countMaterialAnywhere(mat) < cost["materials"][mat]:
			print(str(inventorySystem.countInBackpack(mat)), " + ", str(chestSystem.countMaterialAnywhere(mat)), " < ", str(cost["materials"][mat]))
			return false
	return true

func getEnhancementCost(instance: Dictionary) -> Dictionary:
	match instance.get("enhancement", 0):
		0: return { "gold": 200, "materials": { "Iron Bar": 1 } }
		1: return { "gold": 500, "materials": { "Gold Bar": 2 } }
		2: return { "gold": 1000, "materials": { "Dark Essence": 3 } }
	return {}

func enhanceItem(instance: Dictionary) -> void:
	if not canEnhance(instance):
		GameEvents.eventLogged.emit("Cannot enhance this item.", "system", false)
		return
	
	var cost = getEnhancementCost(instance)
	main.game_data.savedGold -= cost["gold"]
	for mat in cost["materials"]:
		var needed = cost["materials"][mat]
		needed = inventorySystem.consumeFromBackpack(mat, needed)
		if needed > 0:
			chestSystem.consumeFromChests(mat, needed)
	instance["enhancement"] += 1
	main.save_game()
	GameEvents.eventLogged.emit(
		"%s enhanced to +%d!" % [instance["name"], instance["enhancement"]], 
		"discover", false
	)
	GameEvents.equipmentChanged.emit()

# ── HELPERS ───────────────────────────────────────────────
func removeInstanceFromBackpack(instance: Dictionary) -> void:
	
	var id = instance.get("instanceId", "")
	for i in main.game_data.backpack.size():
		if main.game_data.backpack[i].get("instanceId", "") == id:
			main.game_data.backpack.remove_at(i)
			var item = ItemRegistry.getItem(instance["name"])
			if item:
				main.game_data.currentWeight = max(
					0.0, main.game_data.currentWeight - item.weight
				)
			GameEvents.backpackChanged.emit()
			return

func onItemEquipped(itemName: String) -> void:
	# Find the instance in backpack by name
	
	for stack in main.game_data.backpack:
		if stack.get("name") == itemName and stack.get("isEquipment", false):
			equipItem(stack)
			return
