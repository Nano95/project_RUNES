extends Node
class_name BlacksmithSystem

@export var equipmentSystem: EquipmentSystem
@export var inventorySystem: InventorySystem

var main:MainNode

func _ready() -> void:
	main = Utils.get_main()
	#GameEvents.areaExited  # no connections needed, purely functional

func craft(recipe: BlacksmithRecipe) -> bool:
	if not BlacksmithRegistry.canCraft(recipe):
		GameEvents.eventLogged.emit(
			"Not enough materials to craft %s." % recipe.recipeName, "system", false
		)
		return false

	# Consume ingredients from backpack
	for mat in recipe.ingredients:
		var needed = recipe.ingredients[mat]
		inventorySystem.removeFromBackpack(mat, needed)

	# Add result — equipment gets a rolled instance
	var def = ItemRegistry.getEquipmentDef(recipe.resultItem)
	if def:
		var instance = ItemRegistry.rollEquipmentInstance(recipe.resultItem)
		var success = inventorySystem.addEquipmentToBackpack(instance)
		if not success:
			# Backpack full — refund materials
			for mat in recipe.ingredients:
				inventorySystem.addToBackpack(mat, recipe.ingredients[mat])
			GameEvents.eventLogged.emit(
				"Backpack too heavy or full to receive %s." % recipe.resultItem, "system", false
			)
			return false
	else:
		var success = inventorySystem.addToBackpack(recipe.resultItem, 1)
		if not success:
			for mat in recipe.ingredients:
				inventorySystem.addToBackpack(mat, recipe.ingredients[mat])
			GameEvents.eventLogged.emit(
				"Backpack too heavy or full to receive %s." % recipe.resultItem, "system", false
			)
			return false

	main.save_game()
	GameEvents.eventLogged.emit(
		"Crafted %s." % recipe.resultItem, "loot", false
	)
	return true

func enhance(instance: Dictionary) -> bool:
	if not equipmentSystem.canEnhance(instance):
		GameEvents.eventLogged.emit(
			"Cannot enhance %s." % instance.get("name", ""), "system", false
		)
		return false
	equipmentSystem.enhanceItem(instance)
	return true
