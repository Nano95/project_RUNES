extends Control

var rune: RuneData
var main:MainNode
var main_menu:MainMenu
var shop_panel:ShopPanel
func setup(r: RuneData, main_node:MainNode, main_menu_node:MainMenu, shop:ShopPanel):
	rune = r
	main = main_node
	main_menu = main_menu_node
	shop_panel = shop
	$Button/RuneTexture.texture = r.icon
	$Button/RuneTexture/Label.text = str(r.buy_cost)
	$Button/RuneTexture/owned.text = str("Owned: ", main.game_data.get_rune_count(r.name))
	$Button.pressed.connect(buy_rune.bind(rune))

func buy_rune(r:RuneData) -> void:
	shop_panel.buy_rune(r)
	# Next update the owned label
	$Button/RuneTexture/owned.text = str("Owned: ", main.game_data.get_rune_count(r.name))
