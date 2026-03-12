extends Control
class_name MainNode

@onready var game_controller:PackedScene = load("res://Scenes/GameController.tscn")
@onready var game_ui:PackedScene = load("res://Scenes/GameUI.tscn")
@onready var main_menu_ui:PackedScene = load("res://Scenes/MainMenu.tscn")
@export var reward_pop_up:PackedScene
@export var info_pop_up:PackedScene

@export_category("UI")
@export var top_layer:CanvasLayer
@export var mid_layer:Control
@export var back_layer:CanvasLayer
@export var shader_bg:TextureRect

@export_category("Misc")
var save_data_path: String = "user://save/"
var save_data_name: String = "SaveData.tres"
var backup_data_path: String = "user://save/backup/"
var backup_game_data:SaveData
var game_data:SaveData

var active_menu_ref
var game_ui_ref: GameUI
var game_current_level:int = 0
var bonus_stats:Dictionary

var battle_data:Dictionary = {
	"family": "slimes",
	"index": 1,
	"selected_runes": [] # Eventually be coming from save file.
}

func _ready() -> void:
	game_data = SaveData.new()
	backup_game_data = SaveData.new()
	verify_save_directory(save_data_path)
	verify_save_directory(backup_data_path) #and for backup
	load_game()
	
	# Now game things
	Utils.setup(self)
	spawn_main_menu()

func spawn_main_menu() -> void:
	if (is_instance_valid(active_menu_ref)):
		active_menu_ref.queue_free()
	active_menu_ref = main_menu_ui.instantiate() as MainMenu
	active_menu_ref.setup(self)
	spawn_to_top_ui_layer(active_menu_ref)

func spawn_game() -> void:
	delete_all_top_ui_children()
	
	if (is_instance_valid(game_ui_ref)):
		game_ui_ref.queue_free()
	game_ui_ref = game_ui.instantiate() as GameUI
	game_ui_ref.setup(self)
	spawn_to_top_ui_layer(game_ui_ref)
	
	if (is_instance_valid(active_menu_ref)):
		active_menu_ref.queue_free()
	active_menu_ref = game_controller.instantiate() as GameController
	active_menu_ref.setup(self, game_ui_ref)
	spawn_to_mid_ui_layer(active_menu_ref)
	
	game_ui_ref.setup_game_controller(active_menu_ref)
	var colors = MonsterDatabase.monster_colors[battle_data["family"]]
	set_background_colors(colors["col1"], colors["col2"])

func spawn_to_top_ui_layer(node) -> void:
	top_layer.add_child(node)

func spawn_to_mid_ui_layer(node) -> void:
	mid_layer.add_child(node)

func spawn_to_bottom_layer(node) -> void:
	back_layer.add_child(node)

func delete_all_top_ui_children() -> void:
	for child in $FRONT.get_children():
		child.queue_free()

func purchase_successful_update_ui() -> void:
	if !(active_menu_ref is MainMenu): return
	active_menu_ref.update_info_panel()

func set_background_colors(col1:Vector3, col2:Vector3) -> void:
	shader_bg.material.set("shader_parameter/color_one", col1)
	shader_bg.material.set("shader_parameter/color_two", col2)

#########################
# NOTIFICATION HANDLING #
#########################
func _notification(what):
	if (what == NOTIFICATION_WM_WINDOW_FOCUS_IN):
		# IOS and PC
		if !(OS.get_name() == "Android"):
			print("- OS.get_name(): ", OS.get_name())
			focus_in_notification()
	
	if (what == NOTIFICATION_APPLICATION_RESUMED):
		if (OS.get_name() == "Android"):
			print("- OS.get_name()2 ", OS.get_name())
			focus_in_notification()
	
	elif (what == NOTIFICATION_WM_WINDOW_FOCUS_OUT):
		# IOS and PC
		if !(OS.get_name() == "Android"):
			focus_out_notification()
	
	elif (what == NOTIFICATION_APPLICATION_PAUSED):
		# ANDROID
		if (OS.get_name() == "Android"):
			focus_out_notification()
	
	elif (what == NOTIFICATION_WM_CLOSE_REQUEST):
		# calculates total time played - app closed
		#latest_timestamp_player_focused_out = Time.get_unix_time_from_system()
		#if (latest_timestamp_player_focused_in):
			#if (latest_timestamp_player_focused_in <= latest_timestamp_player_focused_in):
				#var time_calculation = latest_timestamp_player_focused_out - latest_timestamp_player_focused_in
				#player_data.total_time_played += int(time_calculation)
			
		save_game()
		get_tree().quit() # default behavior


func focus_in_notification() -> void:
	# gets most recent time to calculate total time played
	@warning_ignore("narrowing_conversion")
	var now:int = Time.get_unix_time_from_system()
	var last:int = game_data.last_crafting_timestamp

	if (last > 0):
		var elapsed:int = now - last
		print("FOCUS IN — elapsed: ", Utils.format_time(elapsed))
		var info = info_pop_up.instantiate() as InfoPopup
		spawn_to_top_ui_layer(info)
		info.show_info(str("Gone: ", Utils.format_time(elapsed)))
		var results = CraftingSystem.process_elapsed(elapsed, game_data)
		game_data.add_crafted_runes_by_name(results)
		if (results.keys().size() > 0):
			show_reward_popups(results)

		if (active_menu_ref is MainMenu):
			active_menu_ref.update_info_panel()
	game_data.last_crafting_timestamp = now

func focus_out_notification() -> void:
	# calculates total time played - app on but out of focus
	@warning_ignore("narrowing_conversion")
	game_data.last_crafting_timestamp = Time.get_unix_time_from_system()
	# NEW: update per-slot timestamps so they don't drift 
	for slot in game_data["offline_rune_timestamps"].keys():
		if (game_data["offline_rune_timestamps"][slot] == 0): continue
		game_data["offline_rune_timestamps"][slot] = Time.get_unix_time_from_system()
	save_game()
	print("-debug: FOCUS OUT")


func show_reward_popups(results: Dictionary) -> void:
	for rune_name in results.keys():
		var rune = RuneDatabase.runes[rune_name]
		var qty = results[rune_name]

		var popup = reward_pop_up.instantiate() as RewardPopup
		spawn_to_top_ui_layer(popup)

		popup.show_reward(rune, qty)

		# Delay before spawning the next popup
		await get_tree().create_timer(1.0).timeout


########### SAVE THINGS ##############

# Create a path if it does not exist (really only used for the save folders)
func verify_save_directory(path: String):
	if not DirAccess.dir_exists_absolute(path):
		DirAccess.make_dir_recursive_absolute(path)

func save_game() -> void:
	# Always check the path exists before saving -- will make the path if it does not.
	verify_save_directory(save_data_path)
	ResourceSaver.save(game_data, save_data_path + save_data_name)

func save_backup_game() -> void:
	backup_game_data = game_data.duplicate(true)
	verify_save_directory(backup_data_path)
	ResourceSaver.save(backup_game_data, backup_data_path + save_data_name)

func load_game() -> void:
	
	# load existing save file
	var path = save_data_path + save_data_name
	if ResourceLoader.exists(path):
		
		var loaded = ResourceLoader.load(path)
		if loaded != null:
			game_data = loaded.duplicate(true)
			
			# Patch missing data + achievemnts for old saves
			# MAY HAVE TO DO THIS FOR ANY FUTURE UPDATES?
			#if !game_data.key_item_patch:
				#patch_inventory_frames()
				#
			#if !game_data.new_achievement_patch:
				#add_hard_mode_achievements(game_data, path)
			
		else:
			# CODE TO COPY BACKUP DATA TO PLAYER DATA GOES IN THIS ELSE
			backup_game()
			
	# create a save file if one does NOT exist
	else:
		save_game()

func backup_game() -> void:
	var backup_path = backup_data_path + save_data_name
	if ResourceLoader.exists(backup_path):
		var backup = ResourceLoader.load(backup_path)
		if backup != null:
			game_data = backup.duplicate(true)
			save_game() # Save it back as the main file
			print("Restored from backup.")
		else:
			print("Backup file exists but couldn't be loaded. TRYING AGAIN")
			backup = ResourceLoader.load(backup_path)
			if backup != null:
				game_data = backup.duplicate(true)
				save_game() # Save it back as the main file
				print("Restored from backup.")
			else:
				# wellp.
				reset_data()
	else:
		print("No save or backup found. Creating new player data.")
		reset_data()

func reset_data() -> void:
	# create new 'player_data' object and replace the previous save data
	game_data = SaveData.new()
	verify_save_directory(save_data_path)
	ResourceSaver.save(game_data, save_data_path + save_data_name)
