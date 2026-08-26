extends Panel
class_name AreaDisplay

@export var areaNameLabel: Label
@export var bestRunLabel: Label
@export var deathsLabel: Label
@export var killsVBox: VBoxContainer
@export var tasksVBox: VBoxContainer

var main:MainNode

func _ready() -> void:
	main = Utils.get_main()
	hide()

func showArea(area: String) -> void:
	areaNameLabel.text = area

	var stats = main.game_data.areaStats.get(area, {})
	bestRunLabel.text = "Best Run: Event #%d" % stats.get("bestRun", 0)
	deathsLabel.text = "Deaths: %d" % stats.get("deaths", 0)

	refreshKills(area)
	refreshTasks(area)

func refreshKills(area: String) -> void:
# Clear existing except title
	var children = killsVBox.get_children()
	for i in range(2, children.size()):
		children[i].free()

	var areaMonsters = MonsterRegistry.getMonstersForArea(area)
	if areaMonsters.is_empty():
		return

	var kills = main.game_data.stats.get("kills", {})
	for monsterName in areaMonsters:
		var count = kills.get(monsterName, 0)
		if count <= 0:
			continue  # only show encountered monsters
		var row = HBoxContainer.new()
		var nameLabel = Label.new()
		nameLabel.text = monsterName
		nameLabel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		nameLabel.add_theme_font_size_override("font_size", 22)
		nameLabel.add_theme_constant_override("outline_size", 14)
		
		var countLabel = Label.new()
		countLabel.text = str(count)
		countLabel.add_theme_color_override("font_color", Color("#c8880a"))
		countLabel.add_theme_font_size_override("font_size", 22)
		countLabel.add_theme_constant_override("outline_size", 14)
		row.add_child(nameLabel)
		row.add_child(countLabel)
		killsVBox.add_child(row)

func refreshTasks(area: String) -> void:
	var children = tasksVBox.get_children()
	for i in range(2, children.size()):
		children[i].queue_free()

	var tasks = TaskRegistry.getTasksForArea(area)
	
	# Sort — unclaimed completed first, then in progress, then claimed
	var unclaimed = tasks.filter(func(t): return TaskRegistry.isCompleted(t) and not TaskRegistry.isClaimed(t))
	var inProgress = tasks.filter(func(t): return not TaskRegistry.isCompleted(t) and not TaskRegistry.isClaimed(t))
	var claimed = tasks.filter(func(t): return TaskRegistry.isClaimed(t))
	
	for task in unclaimed + inProgress + claimed:
		tasksVBox.add_child(_makeTaskRow(task))

func _makeTaskRow(task: Dictionary) -> VBoxContainer:
	var container = VBoxContainer.new()
	var progress = TaskRegistry.getProgress(task)
	var target = task["target"]
	var completed = TaskRegistry.isCompleted(task)
	var claimed = TaskRegistry.isClaimed(task)

	# Rich text label — desc + ratio
	var rtl = RichTextLabel.new()
	rtl.bbcode_enabled = true
	rtl.fit_content = true
	rtl.scroll_active = false
	rtl.custom_minimum_size = Vector2(0, 32)
	rtl.add_theme_font_size_override("normal_font_size", 24)
	rtl.add_theme_constant_override("outline_size", 14)
	rtl.mouse_filter = Control.MOUSE_FILTER_IGNORE

	var ratio = float(progress) / float(target)
	var ratioColor = ""
	if completed:
		ratioColor = "#27ae60"  # green when done
	elif ratio < 0.33:
		ratioColor = "#e74c3c"  # red — first third
	elif ratio < 0.66:
		ratioColor = "#e67e22"  # orange — second third
	else:
		ratioColor = "#f1c40f"  # yellow — third third

	var descColor = "#555555" if claimed else "#ffffff"
	var capped = min(progress, target)
	rtl.text = "[color=%s]%s[/color]  [color=%s]%d/%d[/color]" % [
		descColor, task["desc"], ratioColor, capped, target
	]
	container.add_child(rtl)

	# Progress bar with matching color
	if not claimed:
		var progressBar = ProgressBar.new()
		progressBar.min_value = 0
		progressBar.max_value = target
		progressBar.value = capped
		progressBar.custom_minimum_size = Vector2(0, 10)
		progressBar.show_percentage = false
		progressBar.mouse_filter = Control.MOUSE_FILTER_IGNORE

		# Color the fill via StyleBox
		var fillStyle = StyleBoxFlat.new()
		if completed:
			fillStyle.bg_color = Color("#27ae60")
		elif ratio < 0.33:
			fillStyle.bg_color = Color("#e74c3c")
		elif ratio < 0.66:
			fillStyle.bg_color = Color("#e67e22")
		else:
			fillStyle.bg_color = Color("#f1c40f")
		progressBar.add_theme_stylebox_override("fill", fillStyle)
		container.add_child(progressBar)

	# Claim button or claimed label
	if completed and not claimed:
		var rewardDesc = _getRewardDesc(task)
		var claimBtn = Button.new()
		claimBtn.text = "Claim: %s" % rewardDesc
		claimBtn.pressed.connect(func():
			Utils.animateButtonPress(claimBtn)
			TaskRegistry.claimReward(task)
			refreshTasks(task["area"])
		)
		container.add_child(claimBtn)
	elif claimed:
		var claimedRtl = RichTextLabel.new()
		claimedRtl.bbcode_enabled = true
		claimedRtl.fit_content = true
		claimedRtl.scroll_active = false
		claimedRtl.text = "[color=#555555]✓ Claimed — %s[/color]" % _getRewardDesc(task)
		claimedRtl.mouse_filter = Control.MOUSE_FILTER_IGNORE
		
		container.mouse_filter = Control.MOUSE_FILTER_IGNORE
		container.add_child(claimedRtl)

	# Separator
	var sep = HSeparator.new()
	container.add_child(sep)

	return container

func _getRewardDesc(task: Dictionary) -> String:
	match task["reward"]:
		"gold":       return "+%dg" % task["rewardValue"]
		"weight":     return "+%d max weight" % task["rewardValue"]
		"hp":         return "+%d base HP" % task["rewardValue"]
		"allocation": return "+%d allocation points" % task["rewardValue"]
	return ""
