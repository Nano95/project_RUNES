extends Node
# ============================================================
#  CRAFTING SYSTEM — PURE LOGIC MODULE
#  ------------------------------------------------------------
#  Responsibilities:
#   • Convert elapsed time into rune production
#   • Handle multiple slots (1–6 or more)
#   • Handle multiple essence types (Arcane, Earth, etc.)
#   • Stop production when essence pools empty
#   • Return results for SaveData to apply
#   • Provide progress-bar info for UI
#
#  This script does NOT:
#   • Touch UI
#   • Touch scene tree
#   • Store state (all state lives in SaveData)
# ============================================================


# ------------------------------------------------------------
# Public API
# ------------------------------------------------------------
# Called by Main when the player returns to the menu or resumes the app.
# Returns a dictionary like:
#   { "Arcane Cross": 12, "Earth Burst": 5 }
#
func process_elapsed(elapsed:int, game_data) -> Dictionary:
	var produced := {}
	if elapsed <= 0:
		return produced

	var essence_pools:Dictionary = game_data.current_essences
	var slots := _load_slots(game_data)
	var slot_elapsed:int = 0

	for slot in slots:
		var slot_key:String = slot.slot_key
		var last_ts:int = game_data.offline_rune_timestamps[slot_key]

		# If this slot has never been updated, initialize it
		if last_ts == 0:
			game_data.offline_rune_timestamps[slot_key] = Time.get_unix_time_from_system()
			continue

		@warning_ignore("narrowing_conversion")
		slot_elapsed = Time.get_unix_time_from_system() - last_ts

		# How many full crafts completed?
		var cycles:int = slot_elapsed / slot.craft_time
		if cycles <= 0:
			continue
		# Check if essence pool has enough
		var pool:int = essence_pools.get(slot.essence_type, 0)
		var cycles_possible:int = min(cycles, pool / slot.essence_cost)

		if cycles_possible > 0:
			# Produce runes
			produced[slot.rune_name] = produced.get(slot.rune_name, 0) + cycles_possible

			# Subtract essences
			essence_pools[slot.essence_type] = pool - (cycles_possible * slot.essence_cost)

		# Update timestamp to reflect leftover partial progress
		var leftover_time:int = slot_elapsed % slot.craft_time
		game_data.offline_rune_timestamps[slot_key] = Time.get_unix_time_from_system() - leftover_time

	print("== Produced while away: ", " gone: ",slot_elapsed , "=== ", produced)
	return produced


# ------------------------------------------------------------
# Public helper for UI: compute per-slot preview info
# ------------------------------------------------------------
# Returns a dictionary for UI:
# {
#   "ess_per_hour": 1200,
#   "runes_per_hour": 600,
#   "time_to_empty": 3000.0,
#   "expected_output": 500
# }
#
func compute_slot_preview(slot_rune:RuneData, essence_pool:int, total_ess_per_sec:float) -> Dictionary:
	var craft_time:int = slot_rune.craft_time
	var ess_cost:int = slot_rune.essence_cost

	var ess_per_sec:float = float(ess_cost) / float(craft_time)
	var runes_per_sec := 1.0 / float(craft_time)

	var ess_per_hour := ess_per_sec * 3600.0
	var runes_per_hour := runes_per_sec * 3600.0

	var time_to_empty := INF
	if total_ess_per_sec > 0:
		time_to_empty = essence_pool / total_ess_per_sec

	var expected_output := int(runes_per_sec * time_to_empty)
	print("Expected rune output: ", expected_output)
	var data= {
		"ess_per_hour": ess_per_hour,
		"runes_per_hour": runes_per_hour,
		"time_to_empty": time_to_empty,
		"expected_output": expected_output
	}
	print("CALCULATIONS: ", data)
	return data



# ------------------------------------------------------------
# Public helper for UI: compute progress bar fill
# ------------------------------------------------------------
# Returns a float 0.0 → 1.0
#
func compute_progress(elapsed:int, craft_time:int) -> float:
	if craft_time <= 0:
		return 0.0
	return float(elapsed % craft_time) / float(craft_time)



# ------------------------------------------------------------
# INTERNAL STRUCTURE
# ------------------------------------------------------------
# Slot struct used internally for math
#
class SlotInfo:
	var rune_name:String
	var essence_type:String
	var craft_time:int
	var essence_cost:int
	var slot_key:String

	func _init(rune:RuneData, key:String):
		rune_name = rune.name
		essence_type = rune.essence_type
		craft_time = rune.craft_time
		essence_cost = rune.essence_cost
		slot_key = key


# ------------------------------------------------------------
# Load slots from SaveData
# ------------------------------------------------------------
func _load_slots(game_data) -> Array:
	var slots := []

	for i in range(1, 7):  # supports up to 6 slots
		var rune_name = game_data.get_offline_rune_slot(i)

		if rune_name == null:
			continue

		var rune:RuneData = RuneDatabase.runes.get(rune_name)
		if rune == null:
			continue

		var key := "slot%d" % i
		slots.append(SlotInfo.new(rune, key))

	print("Loaded slots: ", slots)
	return slots

# ------------------------------------------------------------
# Group slots by essence type
# ------------------------------------------------------------
func _group_by_essence(slots:Array) -> Dictionary:
	var grouped := {}

	for slot in slots:
		if not grouped.has(slot.essence_type):
			grouped[slot.essence_type] = []
		grouped[slot.essence_type].append(slot)

	return grouped
