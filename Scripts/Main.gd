extends Control
class_name MainNode

#@onready var game_controller:PackedScene = load("res://Scenes/GameController.tscn")
@onready var game_controller
#@onready var game_ui:PackedScene = load("res://Scenes/GameUI.tscn")
@onready var game_ui
#@onready var main_menu_ui:PackedScene = load("res://Scenes/MainMenu.tscn")
@onready var main_menu_ui
#@onready var focus_chamber:PackedScene = load("res://Scenes/FocusChamber.tscn")
@onready var focus_chamber
@onready var main_controller:PackedScene = load("res://Scenes/MainController.tscn")
@export var reward_pop_up:PackedScene
@export var info_pop_up:PackedScene
@export var rested_panel_ref:PackedScene

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
var rested_popup: RestedPanel
var game_ui_ref: GameUI
var game_current_level:int = 0
var bonus_stats:Dictionary

var battle_data:Dictionary = {
	"family": "area1",
	"index": 1
}

func _ready() -> void:
	game_data = SaveData.new()
	backup_game_data = SaveData.new()
	verify_save_directory(save_data_path)
	verify_save_directory(backup_data_path) #and for backup
	load_game()
	# SaveData is a pure data resource with no initialization logic.
	# We handle first-time setup here in Main to avoid Resource lifecycle
	# quirks — Resources don't guarantee _ready() or _init() timing when
	# loaded from disk, so bootstrapping here is safer and more explicit.
	_bootstrapSaveData() # For Adventure game
	
	# Now game things
	Utils.setup(self)
	Utils.update_crafting_speed()
	#spawn_main_menu()
	spawn_new_game()
	var helmet = ItemRegistry.rollEquipmentInstance("Slimy Helmet", true)
	var armor = ItemRegistry.rollEquipmentInstance("Slimy Armor", true)
	var legs = ItemRegistry.rollEquipmentInstance("Slimy Legs", true)
	
	game_data.equippedHelmet = helmet
	game_data.equippedArmor = armor
	game_data.equippedLegs = legs
	
	# GIVE PLAYER REWARDS
	if !(OS.get_name() == "Windows"):
		call_deferred("check_offline_time_and_rewards")

func _bootstrapSaveData() -> void:
	if game_data.chests.size() == 0:
		for i in range(6):
			var chest = ChestData.new()
			chest.id = i + 1
			chest.unlocked = i == 0  # only chest 1 unlocked by default
			# ARray does not need to be assigned on start.. empty by default and that's what we want
			chest.upgradeLevel = 0
			game_data.chests.append(chest)
		save_game()

#func spawn_main_menu() -> void:
	#if (is_instance_valid(active_menu_ref)):
		#active_menu_ref.queue_free()
	#active_menu_ref = main_menu_ui.instantiate() as MainMenu
	#active_menu_ref.setup(self)
	#spawn_to_top_ui_layer(active_menu_ref)
#
#func spawn_game() -> void:
	#delete_all_top_ui_children()
	#
	#if (is_instance_valid(game_ui_ref)):
		#game_ui_ref.queue_free()
	#game_ui_ref = game_ui.instantiate() as GameUI
	#game_ui_ref.setup(self)
	#spawn_to_top_ui_layer(game_ui_ref)
	#
	#if (is_instance_valid(active_menu_ref)):
		#active_menu_ref.queue_free()
	#active_menu_ref = game_controller.instantiate() as GameController
	#active_menu_ref.setup(self, game_ui_ref)
	#spawn_to_mid_ui_layer(active_menu_ref)
	#
	#game_ui_ref.setup_game_controller(active_menu_ref)
	#var colors = MonsterDatabase.monster_colors[battle_data["family"]]
	#set_background_colors(colors["col1"], colors["col2"])
#
#func spawn_focus_chamber(is_practice:bool, mode:String) -> void:
	#delete_all_top_ui_children()
	#if (is_instance_valid(active_menu_ref)):
		#active_menu_ref.queue_free()
	#active_menu_ref = focus_chamber.instantiate() as FocusChamber
	#active_menu_ref.setup(self, is_practice, mode)
	#spawn_to_top_ui_layer(active_menu_ref)

func spawn_new_game() -> void:
	active_menu_ref = main_controller.instantiate() as MainController
	spawn_to_top_ui_layer(active_menu_ref)

func spawn_to_top_ui_layer(node) -> void:
	top_layer.add_child(node)

func spawn_to_mid_ui_layer(node) -> void:
	mid_layer.add_child(node)

func spawn_to_bottom_layer(node) -> void:
	back_layer.add_child(node)

func delete_all_top_ui_children() -> void:
	for child in $FRONT.get_children():
		child.queue_free()

#func purchase_successful_update_ui() -> void:
	#if !(active_menu_ref is MainMenu): return
	#active_menu_ref.update_info_panel()

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
			print("DONE HERE")
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
		onHardExit() # SAVE IN THIS FUNCTION
		# calculates total time played - app closed
		#latest_timestamp_player_focused_out = Time.get_unix_time_from_system()
		#if (latest_timestamp_player_focused_in):
			#if (latest_timestamp_player_focused_in <= latest_timestamp_player_focused_in):
				#var time_calculation = latest_timestamp_player_focused_out - latest_timestamp_player_focused_in
				#player_data.total_time_played += int(time_calculation)
			
		get_tree().quit() # default behavior
	elif (what == NOTIFICATION_CRASH):
		onHardExit() # SAVE IN THIS FUNCTION

func focus_in_notification() -> void:
	check_offline_time_and_rewards()
	onAppResumed()

func focus_out_notification() -> void:
	# calculates total time played - app on but out of focus
	@warning_ignore("narrowing_conversion")
	game_data.last_crafting_timestamp = Time.get_unix_time_from_system()
	game_data.rested_data.last_logout_time = Time.get_unix_time_from_system()
	onAppPaused()

func onAppPaused() -> void:
	# Just stop ticks while in background
	# State is preserved in memory
	if (active_menu_ref is MainController):
		active_menu_ref.tickTimer.stop()

func onAppResumed() -> void:
	# Resume ticks only if player was mid-run
	if (active_menu_ref is not MainController):
			return
	active_menu_ref.tickTimer.start()

func onHardExit() -> void:
	if game_data.inArea:
		# Lose the run
		game_data.inArea = false
		game_data.currentArea = ""
		game_data.eventCount = 0
		game_data.gold = 0
		game_data.backpack = []
		game_data.currentWeight = 0.0
		game_data.inCombat = false
		game_data.isFleeing = false
		game_data.fleeTicks = 0
	get_tree().quit()

func check_offline_time_and_rewards() -> void:
	# gets most recent time to calculate total time played
	@warning_ignore("narrowing_conversion")
	var now:int = Time.get_unix_time_from_system()
	var last:int = game_data.last_crafting_timestamp
	
	# --- RESTED CHECK ---
	#check_rested_state()
	#if (game_data.rested_data.charges > 0):
		#if (is_instance_valid(rested_popup)):
			#rested_popup.queue_free()
		#rested_popup = rested_panel_ref.instantiate()
		#rested_popup.setup(self)
		#spawn_to_top_ui_layer(rested_popup)

	if (last > 3):
		#Utils.update_crafting_speed()
		var elapsed:int = now - last
		var info = info_pop_up.instantiate() as InfoPopup
		spawn_to_top_ui_layer(info)
		info.show_info(str("Gone: ", Utils.format_time(elapsed)))
		
		## NOW ADD to the HP without going above maxhp if not in area
		if (game_data.inArea): return
		var previousHp = game_data.hp
		game_data.hp = min(active_menu_ref.equipmentSystem.getMaxHp(), game_data.hp + elapsed)
		var actualHealed = game_data.hp - previousHp
		if (actualHealed > 0):
			GameEvents.hpChanged.emit()
			GameEvents.eventLogged.emit(
				"You rested while away. Restored %d HP." % actualHealed, "town", false
			)
		#var results = CraftingSystem.process_elapsed(game_data)
		#game_data.add_crafted_runes_by_name(results)
		#if (results.keys().size() > 0):
			#show_reward_popups(results)

		#if (active_menu_ref is MainMenu):
			#active_menu_ref.update_info_panel()
	game_data.last_crafting_timestamp = now

func show_reward_popups(results: Dictionary) -> void:
	for rune_name in results.keys():
		var rune = RuneDatabase.runes[rune_name]
		var qty = results[rune_name]

		var popup = reward_pop_up.instantiate() as RewardPopup
		spawn_to_top_ui_layer(popup)

		popup.show_reward(rune, qty)

		# Delay before spawning the next popup
		await get_tree().create_timer(1.0).timeout

func check_rested_state() -> void:
	var now := Time.get_unix_time_from_system()
	var rested := game_data.rested_data
	var last = rested.get("last_logout_time", 0)

	if last <= 0:
		rested.last_logout_time = now
		game_data.rested_data.charges = 0
		return

	var elapsed = now - last

	# Pull upgradeable values
	game_data.rested_data.minutes_per_charge = 20
	game_data.rested_data.max_charges = 10

	if (Utils.is_blessing_curse_toggled(true, "mod_rested-battle-4")):
		game_data.rested_data.max_charges += 4
	if (Utils.is_blessing_curse_toggled(true, "mod_rested-battle-6")):
		game_data.rested_data.max_charges += 6
	# Convert elapsed time into minutes
	var minutes_offline:int = int(elapsed / 60)

	# Calculate charges gained
	var gained:int = int(minutes_offline / game_data.rested_data.minutes_per_charge)
	gained = clamp(gained, 0, game_data.rested_data.max_charges)

	game_data.rested_data.charges = gained


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
			print_debug("Restored from backup.")
		else:
			print_debug("Backup file exists but couldn't be loaded. TRYING AGAIN")
			backup = ResourceLoader.load(backup_path)
			if backup != null:
				game_data = backup.duplicate(true)
				save_game() # Save it back as the main file
				print_debug("Restored from backup.")
			else:
				# wellp.
				reset_data()
	else:
		print_debug("No save or backup found. Creating new player data.")
		reset_data()

# ⚠️ Do NOT replace the entire game_data resource.
# Reloading the scene does NOT reset autoloads, so any script holding a
# reference to the old game_data will keep pointing to that stale object.
# This causes dangling references, broken signals, and UI desync.
# Instead, reset the existing game_data fields in-place to keep all references valid.
# which may explain the bug in Idle Expedition when resetting and muting the game or something
func reset_data() -> void:
	# create new 'game_data' object and replace the previous save data
	game_data = SaveData.new()
	verify_save_directory(save_data_path)
	ResourceSaver.save(game_data, save_data_path + save_data_name)
