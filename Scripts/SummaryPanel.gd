extends Control

var main:MainNode
var game_controller: GameController
@export var back_btn: Button
@export var retry_btn: Button
@export var loot_labels: PackedScene

func _ready() -> void:
	setup_labels()
	
	back_btn.pressed.connect(main.delete_all_top_ui_children)
	back_btn.pressed.connect(main.spawn_main_menu)
	retry_btn.pressed.connect(restart_game)
	Utils.animate_summary_in_happy(self)

func restart_game() -> void:
	game_controller.start_game(true)
	Utils.animate_summary_out_and_free(self)

func setup(game: GameController, main_node: MainNode, message:String="Victory!") -> void:
	main = main_node
	game_controller = game
	$ColorRect/Panel/Title.set_text(message)

func setup_labels() -> void:
	$ColorRect/Panel/EnemiesDead.text = "Enemies pulverized: " + str(game_controller.enemies_killed)
	$ColorRect/Panel/RunesUsed.text = "Runes used: " + str(game_controller.runes_used)
	setup_loot()

func setup_loot() -> void:
	var all_loot = game_controller.loot_summary
	print("all LOot: ", all_loot)
	for loot in all_loot.keys():
		print("printing loot: ", loot)
		var data = ItemsDatabase.loot_data[loot]
		var lbl = loot_labels.instantiate()
		lbl.scale *= 2
		lbl.setup(data.name, data.icon, all_loot[loot])
		$ColorRect/Panel/LootContainer.add_child(lbl)
