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
	# Clear existing except title
	var children = tasksVBox.get_children()
	for i in range(2, children.size()):
		children[i].queue_free()

	# Empty for now — tasks coming later
	var lbl = Label.new()
	lbl.text = "Coming soon..."
	lbl.add_theme_color_override("font_color", Color("#888888"))
	lbl.add_theme_font_size_override("font_size", 16)
	lbl.add_theme_font_size_override("outline_size", 14)
	tasksVBox.add_child(lbl)
