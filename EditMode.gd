extends "res://GameModeHandler.gd"
enum MODES {
	MAIN,
	OBJECTIVE,
	BOARD,
	NEXT,
	TEST,
	SHARE
}

var mode = 0
var solved: bool = false
var solution = []

signal ready_finished
# Called when the node enters the scene tree for the first time.
func _ready():
	$PauseModal.free()
	pause_on()
	assert(input_node.paused == true)
	emit_signal("ready_finished")

func vec2_min(vec2: Vector2) -> float:
	return min(vec2.x, vec2.y)
func vec2_max(vec2: Vector2) -> float:
	return max(vec2.x, vec2.y)

func _test():
	print("EditMode - Unpaused")
	$EditResize.hide()
	solved = false
	solution = []
	mode = MODES.TEST
	input_node.set_active(true)
	GameRoot.grab_focus()
	$GameRoot/InputJoyKey.paused = false
	var new_queue = $EditResize/EditNext.dominoes + [$EditResize/EditNext.last_domino]
	GameRoot.reset($EditResize/EditObjective.objective, $EditResize/EditPlayfield.playfield_data, new_queue, $EditResize/EditObjective.rng_seed)
	print("EditMode, %s, %s" % [new_queue, $EditResize/EditPlayfield.playfield_data])
	GameRoot.show()
	GameRoot.set_title(TranslationServer.translate("I18N_EDIT_PLAYTEST"))
	GameRoot.start_game()
	set_input_active(true)

func set_input_active(input_active:bool):
	input_node.set_active(input_active)
	$GameRoot/InputJoyKey.paused = !input_active

func pause_on():
	print("EditMode - Paused")
	GameRoot.reset()
	GameRoot.hide()
	$EditResize.show()
	set_input_active(false)
	back_to_menu()

func back_to_menu():
	print("EditMode - Back to menu")
	mode = MODES.MAIN
	$EditResize/EditMain.show()

func _on_ButtonObjective_pressed():
	mode = MODES.OBJECTIVE
	$EditResize/EditMain.hide()
	$EditResize/EditObjective.set_active(true)

func _on_ButtonPlayfield_pressed():
	mode = MODES.BOARD
	$EditResize/EditMain.hide()
	$EditResize/EditPlayfield.set_active(true)

func _on_ButtonNext_pressed():
	mode = MODES.NEXT
	$EditResize/EditMain.hide()
	$EditResize/EditNext.set_active(true)

func _on_ButtonShare_pressed():
	mode = MODES.SHARE
	$EditResize/EditMain.hide()
	$EditResize/EditShare.set_active(true)

func _on_ButtonTest_pressed():
	_test()

func game_over():
	$Timer.wait_time = 1
	$Timer.start()

func _on_Timer_timeout():
	pause_on()

func _on_ButtonExit_pressed():
	Root.back_scene()
	pass # Replace with function body.

func _on_textbox_gui_input(event):
	if event is InputEventJoypadButton and event.is_action_pressed("ui_accept"):
		OS.show_virtual_keyboard()

func _on_ButtonRestart_pressed():
	Root.show_confirm(
		"I18N_EDIT_RESTART", #text
		null, #icon
		self, #bind to object
		"_on_dialog_result", #bind to method
		"default" #identifier for multiple confirm dialogs
	)

func _on_dialog_result(confirmed, id):
	match id:
		"default":
			if confirmed:
				$EditResize/EditShare.reset_data()

func enter_phase_drop(placed_domino: bool = false, x: int = -1, y: int = -1, direction: int = -1):
	if placed_domino:
		# store the solution
		solution.append({
			"x": x,
			"y": y,
			"rot": direction
		})
	.enter_phase_drop(placed_domino, x, y, direction)

func game_clear():
	solved = true
	.game_clear()
