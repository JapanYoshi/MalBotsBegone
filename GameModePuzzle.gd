extends "res://GameModeHandler.gd"
var lvdat
var lvscript
var keyconfig = preload("res://KeyConfig.gd")
var turn: int = 0
var Cursor: PackedScene = preload("res://PuzzleCursor.tscn")
var cursors: Array = []
var Bubble: PackedScene = preload("res://PuzzleText.tscn")
onready var bubble: Node2D = Bubble.instance()
onready var ok_elem: Button = $ok
var waiting_for_input: bool = false

func _ready():
	#._ready()
	if !(Root.pass_between.has("level")):
		Root.show_error("An error occurred: No puzzle is loaded.")
		return
	GameRoot.connect("rejected_input", self, "_on_rejected_input")
	turn = 0
	bubble.hide()
	GameRoot.add_child(bubble)
	lvdat = Root.pass_between.level.data
	lvscript = Root.pass_between.level.script
# warning-ignore:unsafe_method_access
	GameRoot.set_title(lvdat.name)
# warning-ignore:unsafe_method_access
	GameRoot.reset(
		lvdat.mission,
		lvdat.field,
		lvdat.next,
		lvdat.seed
	)
	# todo: script
	enter_phase_spawn()
	# todo: hints
	
func enter_phase_spawn():
	GameRoot.set_paused(true)
# warning-ignore:unsafe_method_access
	button_node.set_active(false)
# warning-ignore:unsafe_method_access
	input_node.pause()
	while len(lvscript):
		if lvscript[0].turn <= turn:
			ok_elem.show()
			var this_script = lvscript.pop_front()
			if this_script.has("condition"):
				var result
				if typeof(this_script.condition) == TYPE_BOOL:
					result = this_script.condition
				else:
					var xprs = Expression.new()
					var parsed = xprs.parse(this_script.condition, PoolStringArray(["self"]))
					if parsed != OK:
						printerr("Could not parse expression: " + this_script.condition + " (%s)" % xprs.get_error_text())
						continue
					result = xprs.execute()
					if xprs.has_execute_failed():
						printerr("Could not execute expression: " + this_script.condition)
						continue
				if result == false:
					continue
			if this_script.has("cursor"):
				while len(cursors) < len(this_script.cursor):
					var new_cursor = Cursor.instance()
					cursors.push_back(new_cursor)
# warning-ignore:unsafe_property_access
					GameRoot.board.add_child(new_cursor)
				if len(cursors) > len(this_script.cursor):
					for i in range(len(this_script.cursor), len(cursors)):
						cursors[i].hide()
				for i in range(len(this_script.cursor)):
					cursors[i].point_to(this_script.cursor[i])
					cursors[i].show()
			if this_script.has("text"):
# warning-ignore:unsafe_method_access
				bubble.set_bbcode(this_script.text)
				bubble.show()
				if this_script.has("text_position"):
					bubble.position = Vector2(this_script.text_position[0], this_script.text_position[1])
			else:
				bubble.hide()
			waiting_for_input = true
			return
		else:
			start_turn()
			return
	start_turn()
	return

func start_turn():
	turn += 1
# warning-ignore:unsafe_method_access
	button_node.set_active(true)
# warning-ignore:unsafe_method_access
	input_node.unpause()
	bubble.hide()
	ok_elem.hide()
	.enter_phase_spawn()

func _on_Hint_pressed():
	Root.show_message("Hints are not implemented yet", 0)

func _input(event):
	if waiting_for_input:
		if event.is_action_pressed("ui_accept"):
			accept_event()
			enter_phase_spawn()
			return

func _on_rejected_input(id):
	print("Rejected input %d" % id)

func _on_ok_pressed():
	enter_phase_spawn()

func game_clear():
	print("Your score is %08d" % GameRoot.score)
	var save = Root.save_dict[Root.pass_between.world]
	if typeof(save.cleared) == TYPE_STRING:
		save.cleared = save.cleared.hex_to_int()
	save.cleared = save.cleared | (1 << Root.pass_between.level_index)
	Root.save_dict[\
		Root.pass_between.world\
	].cleared = "0x%x" % save.cleared
	var highscore = 0
	if save.highscores.has(Root.pass_between.level_index):
		highscore = save.highscores[Root.pass_between.level_index]
	if highscore < GameRoot.score:
		GameRoot.show_highscore(highscore)
		Root.save_dict[\
			Root.pass_between.world\
		].highscores[\
			Root.pass_between.level_index\
		] = GameRoot.score
	GameRoot.call_deferred("on_game_clear")
	Root.save_game()
