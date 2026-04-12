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

func process_elapsed(game_data) -> Dictionary:
	var produced := {}
	var now = Time.get_unix_time_from_system()

	# Global elapsed time
	var last_ts = game_data.last_crafting_timestamp
	if last_ts == 0:
		game_data.last_crafting_timestamp = now
		return produced

	var elapsed = float(now - last_ts)
	print("=== Offline crafting start ===")
	print("Elapsed: ", elapsed)
	if elapsed <= 0:
		return produced

	var max_elapsed = 24 * 3600.0  # 24 hours in seconds

	if elapsed > max_elapsed:
		elapsed = max_elapsed

	var slots = _load_slots(game_data)
	var essence_pools = game_data.current_essences
	var blocked_slots = {}

	# Ensure progress dictionary exists
	if not game_data.slot_progress:
		game_data.slot_progress = {}

	# Initialize missing progress entries
	for slot in slots:
		if not game_data.slot_progress.has(slot.slot_key):
			game_data.slot_progress[slot.slot_key] = 0.0

		print("%s: craft_time=%.3f, start_progress=%.3f" %
			[slot.slot_key, slot.craft_time, game_data.slot_progress[slot.slot_key]])

	var remaining = elapsed

	while remaining > 0:
		var next_event_time = INF
		var active_slots = 0

		# Determine next event time
		for slot in slots:
			if blocked_slots.has(slot.slot_key):
				continue

			active_slots += 1
			var progress = game_data.slot_progress[slot.slot_key]
			var time_left = slot.craft_time - progress

			if time_left < next_event_time:
				next_event_time = time_left

		# If no active slots remain, break
		if active_slots == 0:
			print("All slots blocked. Ending early.")
			break

		# If next event is beyond remaining time, advance and exit
		if next_event_time > remaining:
			for slot in slots:
				if not blocked_slots.has(slot.slot_key):
					game_data.slot_progress[slot.slot_key] += remaining
			remaining = 0
			break


		# Advance progress
		for slot in slots:
			if not blocked_slots.has(slot.slot_key):
				game_data.slot_progress[slot.slot_key] += next_event_time

		remaining -= next_event_time

		# Process crafts
		for slot in slots:
			var key = slot.slot_key
			if blocked_slots.has(key):
				continue

			if game_data.slot_progress[key] >= slot.craft_time:
				var pool = essence_pools.get(slot.essence_type, 0)

				if pool >= slot.essence_cost:
					essence_pools[slot.essence_type] = pool - slot.essence_cost
					produced[slot.rune_name] = produced.get(slot.rune_name, 0) + 1
					game_data.slot_progress[key] -= slot.craft_time

					#print("%s crafted %s (cost=%d). New essence=%d" %
						#[key, slot.rune_name, slot.essence_cost, essence_pools[slot.essence_type]])

				else:
					blocked_slots[key] = true
					game_data.slot_progress[key] = slot.craft_time
					print("%s blocked (not enough essence)" % key)

			#print("%s: new_progress=%.3f" %
				#[key, game_data.slot_progress[key]])

	game_data.last_crafting_timestamp = now
	print("Produced: ", produced)
	print("=== Offline crafting end ===")

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
		var slot_info:SlotInfo = SlotInfo.new(rune, key)
		slot_info.craft_time = max(2, int(rune.craft_time * Utils.crafting_speed_mult)) # cannot go below 2s
		slots.append(slot_info)

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
