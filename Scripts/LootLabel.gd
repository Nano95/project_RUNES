extends Control


func setup(loot_name:String, loot_icon:Texture, qty:int) -> void:
	$TextureRect.texture = loot_icon
	custom_minimum_size = Vector2(232, 61)
	$Label.text = loot_name + str(" x", qty)
