extends HBoxContainer
class_name ExpeditionGearPanel

@export var mapBtn: Button
@export var mapTexture: TextureRect
@export var survivalGearBtn: Button
@export var survivalGearTexture: TextureRect
@export var itemModal: EquipmentItemModal
@export var equipmentSystem: EquipmentSystem

var main:MainNode

func _ready() -> void:
	main = Utils.get_main()
	GameEvents.equipmentChanged.connect(refresh)
	mapBtn.pressed.connect(func(): onSlotPressed("expeditionMap", mapBtn))
	survivalGearBtn.pressed.connect(func(): onSlotPressed("survivalGear", survivalGearBtn))
	refresh()

func refresh() -> void:
	_updateSlot(mapBtn, mapTexture, "expeditionMap")
	_updateSlot(survivalGearBtn, survivalGearTexture, "survivalGear")

func _updateSlot(btn: Button, textureRect: TextureRect, slot: String) -> void:
	var equipped = equipmentSystem.getEquippedSlot(slot)
	if not equipped or equipped.is_empty():
		btn.text = "[empty]"
		btn.modulate = Color(1, 1, 1, 0.4)
		textureRect.texture = null
	else:
		var grade = equipped.get("grade", "")
		var gradeStr = " [%s]" % grade if grade != "" else ""
		var enh = equipped.get("enhancement", 0)
		var enhStr = " +%d" % enh if enh > 0 else ""
		btn.text = "%s%s%s" % [equipped.get("name", ""), gradeStr, enhStr]
		btn.modulate = Color(1, 1, 1, 1.0)
		@warning_ignore("static_called_on_instance")
		textureRect.texture = ItemRegistry.getSprite(equipped.get("name", ""))

func onSlotPressed(slot: String, btn: Button) -> void:
	Utils.animateButtonPress(btn)
	if (main.game_data.isExpeditionActive):
		GameEvents.expeditionEventFired.emit({
			"type": "empty",
			"title": "Cannot change gear during an expedition.",
			"description": "",
			"damage": 0,
			"gold": 0,
			"item": "",
			"qty": 0,
			"dungeon": false,
			"showNumber": false
		})
		return
	itemModal.open(slot)
