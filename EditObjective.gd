extends Control

var active = false
var time_format = TranslationServer.translate("I18N_TIME_FORMAT")
var objective: PoolByteArray

var time_box: Node
var value_box: Node
var color_box: Node
var score_box: Node

var title: String
var title_as_utf16_bytes: PoolByteArray
var title_length: int = 0

var author: String
var author_as_utf16_bytes: PoolByteArray
var author_length: int = 0

var level: int = 0
var difficulty: int = 0
const max_difficulty: int = 5

var rng_seed: int = 0

var objective_list: Array

func set_active(x: bool):
	active = x
	if x:
		show()
		$S/A/Objective.grab_focus()
	else:
		hide()
	time_box = $S/A/TabContainer/Time
	value_box = $S/A/TabContainer/Page2/Number
	color_box = $S/A/TabContainer/Page2/Color
	score_box = $S/A/TabContainer/Score/Value

# Called when the node enters the scene tree for the first time.
func _ready():
	var parent_elem = find_parent("EditMode")
	objective_list = parent_elem.find_node("GameRoot", true).find_node("ObjectiveBox", true).objective_list
	for obj in objective_list:
		var text = TranslationServer.translate(obj).replace("[b]", "").replace("[/b]", "")
		if obj.ends_with("_COLOR_COUNT"):
			text = text.replace("{1}", TranslationServer.translate("I18N_OBJECTIVE_PLACEHOLDER_COLOR")).replace("{0}", TranslationServer.translate("I18N_OBJECTIVE_PLACEHOLDER_NUMBER"))
		elif obj.ends_with("_COLOR"):
			text = text.replace("{0}", TranslationServer.translate("I18N_OBJECTIVE_PLACEHOLDER_COLOR"))
		elif obj.ends_with("_TIME"):
			text = text.replace("{0}", TranslationServer.translate("I18N_OBJECTIVE_PLACEHOLDER_TIME"))
		else:
			text = text.replace("{0}", TranslationServer.translate("I18N_OBJECTIVE_PLACEHOLDER_NUMBER"))
		print("EditObjective - text = %s" % text)
		$S/A/Objective.add_item(text)
	$S/A/Objective.select(0)
	_on_time_changed()

func _on_ButtonExit_pressed():
	set_active(false)
	find_parent("EditMode").back_to_menu()

func _on_time_changed(_temp = null):
	$S/A/TabContainer/Time/Label.text = time_format % [$S/A/TabContainer/Time/H/Minutes.value, $S/A/TabContainer/Time/H/Seconds.value]
	recalculate()

func _on_Objective_item_selected(index):
	recalculate()
		
func recalculate():
	match $S/A/Objective.selected:
		0: # zen
			objective = [0x00]
		1: # survive
			objective = [0x01, 0, 0]
		2: # survive time
			var time = int(time_box.find_node("Minutes").value * 60 + time_box.find_node("Seconds").value)
			objective = [0x01, time / 256, time % 256]
		3: # enemy
			objective = [0x7F, 0]
		4: # enemy count
			objective = [0x7F, value_box.find_node("Value").value]
		5: # enemy color
			objective = [0x40 ^ color_box.value, 0]
		6: # enemy color count
			objective = [0x40 ^ color_box.value, value_box.find_node("Value").value]
		7: # block
			objective = [0xBF, 0]
		8: # block count
			objective = [0xBF, value_box.find_node("Value").value]
		9: # block color
			objective = [0x80 ^ color_box.value, 0]
		10: # block color count
			objective = [0x80 ^ color_box.value, value_box.find_node("Value").value]
		11: # chain count
			objective = [0x1F + value_box.find_node("Value").value]
		12: # chain count exact
			objective = [0x2F + value_box.find_node("Value").value]
		13: # high score
			objective = [0x06]
			var temp_array = []
			var score = int(score_box.value)
			for i in range(0, 4):
				temp_array.push_front(score & 0xFF)
				score = score >> 8
			objective.append_array(temp_array)
		14: # colors
			if value_box.find_node("Value").value < 2 or\
			   value_box.find_node("Value").value > 5:
				objective = [0x02]
			else:
				objective = [value_box.find_node("Value").value]
	get_parent().get_parent().get_node("GameRoot/ObjectiveBox").parse_objective(objective)
	# $A/Label.text = ("%X" % objective[0]) + " (%s)" % str(objective)

func _on_Title_text_changed(new_text):
	title = new_text
	title_as_utf16_bytes = Root.text_to_utf16_bytes(new_text)
	title_length = len(title_as_utf16_bytes) / 2
	$S/A/TitleBox/TitleLength.text = "%2d/%2d" % [title_length, 64] # max length

func _on_level_changed(new_level):
	set_level(int(round(new_level)))

func _on_difficulty_changed(new_difficulty):
	set_difficulty(int(round(new_difficulty)))

func set_title(new_text):
	$S/A/TitleBox/Title.text = new_text
	_on_Title_text_changed(new_text)

func set_author(new_text):
	$S/A/AuthorBox/Author.text = new_text
	_on_Author_text_changed(new_text)

func set_level(new_level: int):
	level = new_level
	print(TranslationServer.translate("I18N_EDIT_LEVEL_HELP"))
	find_parent("EditMode").find_node("GameRoot").set_difficulty(level)
	$S/A/LevelHelp.text = TranslationServer.translate("I18N_EDIT_LEVEL_HELP") % find_parent("EditMode").find_node("GameRoot").moving_domino_speed
	$S/A/HBoxContainer/Level.value = level
	
func set_seed(new_seed: int):
	rng_seed = new_seed
	
func set_difficulty(new_difficulty: int):
	difficulty = new_difficulty;

func _on_Author_text_changed(new_text):
	author = new_text
	author_as_utf16_bytes = Root.text_to_utf16_bytes(new_text)
	author_length = len(author_as_utf16_bytes) / 2
	$S/A/AuthorBox/AuthorLength.text = "%2d/%2d" % [author_length, 64] # max length

func _on_Random_pressed():
	var rng = RandomNumberGenerator.new()
	rng.seed = OS.get_ticks_usec()
	$S/A/HBoxContainer3/Seed.value = rng.randi()

func _on_seed_changed(new_seed):
	set_seed(int(round(new_seed)))
