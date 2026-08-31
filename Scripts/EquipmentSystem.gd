extends Node
class_name EquipmentSystem

@export var inventorySystem: InventorySystem
@export var chestSystem: ChestSystem

var main:MainNode
var cachedMaxHp: int = 0

const ENHANCEMENT_TABLE = [
	# { "statBonus": int, "destroyChance": float, "material": String, "qty": int, "gold": int }
	{ "statBonus": 1, "destroyChance": 0.1, "material": "Copper Bar", "qty": 0, "gold": 40  },  # +1
	{ "statBonus": 1, "destroyChance": 0.1, "material": "Copper Bar", "qty": 0, "gold": 50  },  # +2
	{ "statBonus": 1, "destroyChance": 0.2, "material": "Copper Bar", "qty": 0, "gold": 60  },  # +3
	{ "statBonus": 1, "destroyChance": 0.2, "material": "Copper Bar", "qty": 0, "gold": 70  },  # +4
	{ "statBonus": 1, "destroyChance": 0.3, "material": "Iron Bar", "qty": 0, "gold": 80 },  # +5
	{ "statBonus": 2, "destroyChance": 0.3, "material": "Iron Bar", "qty": 0, "gold": 90 },  # +6
	{ "statBonus": 2, "destroyChance": 0.4, "material": "Iron Bar", "qty": 0, "gold": 100 },  # +7
	{ "statBonus": 2, "destroyChance": 0.5, "material": "Iron Bar", "qty": 0, "gold": 100 },  # +8
	{ "statBonus": 2, "destroyChance": 0.6, "material": "Iron Bar", "qty": 0, "gold": 100 },  # +9
	{ "statBonus": 2, "destroyChance": 0.7, "material": "Iron Bar", "qty": 0, "gold": 100 },  # +10
]

const MAX_ENHANCEMENT = 10
const SAFETY_NET_ACTIVE = false  # future: set to true when minigame is implemented

func _ready() -> void:
	main = Utils.get_main()
	GameEvents.checkpointReached.connect(onCheckpointReached)
	GameEvents.tickFired.connect(onTick)
	GameEvents.itemEquipped.connect(onItemEquipped)
	GameEvents.equipmentChanged.connect(onEquipmentChanged)
	cachedMaxHp = calculateMaxHp()

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
			GameEvents.cannotEquipError.emit("twoHandedError")
			return

	if (slot == "expeditionMap"):
		var unlocksArea = instance.get("effects", {}).get("unlocksArea", "")
		if unlocksArea != "" and not main.game_data.unlockedAreas.has(unlocksArea):
			main.game_data.unlockedAreas.append(unlocksArea)
	
	# Unequip current item in slot first
	unequipSlot(slot)
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
	# Bypass weight check when returning to backpack during a swap
	main.game_data.backpack.append(current)
	var item = ItemRegistry.getItem(current.get("name", ""))
	if item:
		main.game_data.currentWeight += item.weight
	setEquippedSlot(slot, {})
	GameEvents.equipmentChanged.emit()
	GameEvents.backpackChanged.emit()

func getEquippedSlot(slot: String) -> Dictionary:
	if !(main): main = Utils.get_main()
	match slot:
		"weapon": return main.game_data.equippedWeapon
		"shield": return main.game_data.equippedShield
		"armor":  return main.game_data.equippedArmor
		"helmet": return main.game_data.equippedHelmet
		"legs":   return main.game_data.equippedLegs
		"boots":  return main.game_data.equippedBoots
		"expeditionMap":  return main.game_data.equippedExpeditionMap
		"survivalGear":   return main.game_data.equippedSurvivalGear
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
		"expeditionMap":  main.game_data.equippedExpeditionMap = instance
		"survivalGear":   main.game_data.equippedSurvivalGear = instance
		"ring":   main.game_data.equippedRing = instance
		"amulet": main.game_data.equippedAmulet = instance

func onEquipmentChanged() -> void:
	cachedMaxHp = calculateMaxHp()
	# Clamp current HP if new max is lower
	if main.game_data.hp > cachedMaxHp:
		main.game_data.hp = cachedMaxHp
	main.save_game()
	GameEvents.hpChanged.emit()

# ── STAT CALCULATIONS ─────────────────────────────────────
func getMaxHp() -> int:
	return cachedMaxHp

func getTotalAttack() -> int:
	var weapon = main.game_data.equippedWeapon
	if not weapon or weapon.is_empty():
		return 0
	return weapon.get("atkBonus", 0) + weapon.get("gradeBonus", 0)

func getTotalDefense() -> int:
	var shield = main.game_data.equippedShield
	if not shield or shield.is_empty():
		return 0
	return shield.get("defBonus", 0) + shield.get("gradeBonus", 0)

func calculateMaxHp() -> int:
	var total = main.game_data.baseHp
	var slots = [
		"equippedHelmet", "equippedArmor", "equippedLegs",
		"equippedBoots", "equippedWeapon", "equippedShield",
	]
	for slot in slots:
		var item = main.game_data.get(slot)
		if not item or item.is_empty():
			continue
		total += item.get("hpBonus", 0)
		total += item.get("gradeHpBonus", 0)
	return total

func getDodgeChance() -> float:
	return getTotalEffects().get("dodge", 0.0)

func getTotalEffects() -> Dictionary:
	var total = {}
	var slots = [
		"equippedHelmet", "equippedArmor", "equippedLegs",
		"equippedBoots", "equippedWeapon", "equippedShield"
	]
	for slot in slots:
		var item = main.game_data.get(slot)
		if not item or item.is_empty():
			continue
		for effect in item.get("effects", {}):
			total[effect] = total.get(effect, 0.0) + item["effects"][effect]
		for effect in item.get("gradeEffects", {}):
			total[effect] = total.get(effect, 0.0) + item["gradeEffects"][effect]
	return total

# ── EFFECTS ───────────────────────────────────────────────
func onCheckpointReached() -> void:
	# Ring of Vitality — heal on checkpoint
	for slot in ["equippedRing", "equippedAmulet"]:
		var item = main.game_data.get(slot)
		if not item or item.is_empty():
			continue
		if item.get("effectType") == "checkpoint_heal":
			var healPct = item.get("effectValue", 0)
			var healAmt = int(cachedMaxHp * (healPct / 100.0))
			main.game_data.hp = min(cachedMaxHp, main.game_data.hp + healAmt)
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
			if main.game_data.hp < cachedMaxHp:
				main.game_data.hp = min(cachedMaxHp, main.game_data.hp + regenAmt)
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
	var enh = instance.get("enhancement", 0)
	if enh >= MAX_ENHANCEMENT:
		return false
	var cost = ENHANCEMENT_TABLE[enh]
	if main.game_data.savedGold < cost["gold"]:
		return false
	var matCount = inventorySystem.countInBackpack(cost["material"]) + \
				   chestSystem.countMaterialAnywhere(cost["material"])
	if matCount < cost["qty"]:
		return false
	return true

func getEnhancementCost(instance: Dictionary) -> Dictionary:
	var enh = instance.get("enhancement", 0)
	if enh >= MAX_ENHANCEMENT:
		return {}
	return ENHANCEMENT_TABLE[enh]

func enhanceItem(instance: Dictionary) -> Dictionary:
	var enh = instance.get("enhancement", 0)
	if enh >= MAX_ENHANCEMENT:
		return { "result": "maxed" }

	var cost = ENHANCEMENT_TABLE[enh]

	# Consume materials and gold
	inventorySystem.consumeFromBackpack(cost["material"], cost["qty"])
	main.game_data.savedGold -= cost["gold"]

	# Destroy chance check
	var destroyChance = cost["destroyChance"]
	if not SAFETY_NET_ACTIVE and randf() < destroyChance:
		# Item destroyed — remove from backpack
		_removeInstanceFromBackpackById(instance.get("instanceId", ""))
		main.save_game()
		GameEvents.equipmentChanged.emit()
		GameEvents.eventLogged.emit(
			"%s was destroyed during enhancement!" % instance.get("name", ""),
			"danger", false
		)
		return { "result": "destroyed" }

	# Success — find and update instance in backpack
	var id = instance.get("instanceId", "")
	for stack in main.game_data.backpack:
		if stack.get("instanceId", "") == id:
			stack["enhancement"] += 1
			# Apply stat bonus based on slot
			var slot = stack.get("slot", "")
			if slot == "weapon":
				stack["atkBonus"] += cost["statBonus"]
			elif slot == "shield":
				stack["defBonus"] += cost["statBonus"]
			elif slot == "boots":
				var currentDodge = stack.get("effects", {}).get("dodge", 0.0)
				stack["effects"]["dodge"] = currentDodge + 0.005
			else:
				stack["hpBonus"] += cost["statBonus"]
			main.save_game()
			GameEvents.equipmentChanged.emit()
			GameEvents.eventLogged.emit(
				"%s enhanced to +%d!" % [stack.get("name", ""), stack["enhancement"]],
				"loot", false
			)
			return { "result": "success", "instance": stack }

	return { "result": "error" }

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

func _removeInstanceFromBackpackById(instanceId: String) -> void:
	for i in main.game_data.backpack.size():
		if main.game_data.backpack[i].get("instanceId", "") == instanceId:
			var item = ItemRegistry.getItem(main.game_data.backpack[i].get("name", ""))
			if item:
				main.game_data.currentWeight = max(
					0.0, main.game_data.currentWeight - item.weight
				)
			main.game_data.backpack.remove_at(i)
			GameEvents.backpackChanged.emit()
			return

func onItemEquipped(itemName: String) -> void:
	# Find the instance in backpack by name
	
	for stack in main.game_data.backpack:
		if stack.get("name") == itemName and stack.get("isEquipment", false):
			equipItem(stack)
			return
