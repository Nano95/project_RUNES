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
	var now = Time.get_unix_time_from_system()
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
		if (last_ts == 0):
			game_data.offline_rune_timestamps[slot_key] = now
			continue

		@warning_ignore("narrowing_conversion")
		slot_elapsed = now - last_ts

		# How many full crafts completed?
		var cycles:int = slot_elapsed / slot.craft_time
		if cycles <= 0:
			continue
		# Check if essence pool has enough
		var pool:int = essence_pools.get(slot.essence_type, 0)
		var cycles_possible:int = min(cycles, pool / slot.essence_cost)

		if (cycles_possible > 0):
			# Produce runes
			produced[slot.rune_name] = produced.get(slot.rune_name, 0) + cycles_possible
			# Subtract essences
			essence_pools[slot.essence_type] = pool - (cycles_possible * slot.essence_cost)

		# Update timestamp to reflect leftover partial progress
		var leftover_time:int = slot_elapsed % slot.craft_time
		game_data.offline_rune_timestamps[slot_key] = now - leftover_time

	return produced


func compute_summary(game_data) -> Dictionary:
	var essence_pools:Dictionary = game_data.current_essences
	var slots := _load_slots(game_data)

	var essence_groups := {}  # essence_type -> list of SlotInfo
	var rune_outputs := {}    # rune_name -> expected output

	# Group slots by essence type -- suchas if multiple alots have the same essence type
	for slot in slots:
		if not essence_groups.has(slot.essence_type):
			essence_groups[slot.essence_type] = []
		essence_groups[slot.essence_type].append(slot)

	var essence_summaries := {}

	# Process each essence type
	for essence_type in essence_groups.keys():
		
		var slot_list:Array = essence_groups[essence_type]
		# Total ess/sec and runes/sec for this essence type
		var total_ess_per_sec:float = 0.0
		var total_runes_per_sec:float = 0.0
		var min_cost := INF
		for slot in slot_list:
			if (slot.essence_cost < min_cost): 
				min_cost = slot.essence_cost

			total_ess_per_sec += float(slot.essence_cost) / float(slot.craft_time)
			total_runes_per_sec += 1.0 / float(slot.craft_time)

		var pool:int = essence_pools.get(essence_type, 0)
		var time_to_empty:float
		if pool < min_cost:
			# Not enough essence to complete even one craft
			time_to_empty = 0.0
			# And all expected_output for this essence type should be 0
			for slot in slot_list:
				rune_outputs[slot.rune_name] = 0
			# You can early-continue here if you want
			essence_summaries[essence_type] = {
				"time_to_empty": time_to_empty,
				"ess_per_hour": total_ess_per_sec * 3600.0,
				"runes_per_hour": total_runes_per_sec * 3600.0
			}
			continue
		elif pool <= 0:
			time_to_empty = 0.0
		elif total_ess_per_sec <= 0.0:
			time_to_empty = INF
		else:
			time_to_empty = float(pool) / float(total_ess_per_sec)
		
		print("Essence type:", essence_type, "pool:", pool, "slots:", slot_list.size())
		# Expected output per rune
		for slot in slot_list:
			var expected := int(time_to_empty * (1.0 / slot.craft_time))
			rune_outputs[slot.rune_name] = expected
		
		# Save essence summary
		essence_summaries[essence_type] = {
			"time_to_empty": time_to_empty,
			"ess_per_hour": total_ess_per_sec * 3600.0,
			"runes_per_hour": total_runes_per_sec * 3600.0
		}

	return {
		"essence_summaries": essence_summaries,
		"rune_outputs": rune_outputs
	}

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
