extends Control
class_name MainNode

@onready var game_controller = load("res://Scenes/GameController.tscn")
@onready var game_ui = load("res://Scenes/GameUI.tscn")
@onready var main_menu_ui = load("res://Scenes/MainMenu.tscn")

@export_category("UI")
@export var top_layer:CanvasLayer
@export var mid_layer:Node2D
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
var player_stats:StatsData
var bonus_stats:Dictionary

func _ready() -> void:
	game_data = SaveData.new()
	backup_game_data = SaveData.new()
	player_stats = StatsData.new()
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
	


func spawn_to_top_ui_layer(node) -> void:
	top_layer.add_child(node)

func spawn_to_mid_ui_layer(node) -> void:
	mid_layer.add_child(node)

func spawn_to_bottom_layer(node) -> void:
	back_layer.add_child(node)

func delete_all_top_ui_children() -> void:
	for child in $FRONT.get_children():
		child.queue_free()

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
			focus_in_notification()
	
	if (what == NOTIFICATION_APPLICATION_RESUMED):
		if (OS.get_name() == "Android"):
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
	#latest_timestamp_player_focused_in = Time.get_unix_time_from_system()
	#total_time_gone = get_time_gone() -> IN UTILS
	print("-debug: FOCUS IN")
	pass

func focus_out_notification() -> void:
	# calculates total time played - app on but out of focus
	#latest_timestamp_player_focused_out = Time.get_unix_time_from_system()
	#if (latest_timestamp_player_focused_in):
		#if (latest_timestamp_player_focused_in <= latest_timestamp_player_focused_in):
			#var time_calculation = latest_timestamp_player_focused_out - latest_timestamp_player_focused_in
			#player_data.total_time_played += int(time_calculation)
#
	#player_data.last_seen = str(ceil(Time.get_unix_time_from_system()))
	print("-debug: FOCUS OUT")
	save_game()


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
