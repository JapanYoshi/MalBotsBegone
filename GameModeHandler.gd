extends Control

var GameRoot: Control
var phase: int = 0
var level: int = 0

var input_node: Control
var button_node: Control
var Pause: CanvasLayer
var rng = RandomNumberGenerator.new()
var colors_allowed: int = 3

# Called when the node enters the scene tree for the first time.
func _ready():
	bind(find_node("GameRoot"))
	Root.preload_sfx("move")
	Root.preload_sfx("move_fail")
	Root.preload_sfx("rotate")
	Root.preload_sfx("rotate_fail")
	Root.preload_sfx("harddrop")
	Root.preload_sfx("lock")
	Root.preload_sfx("empty")
	Root.preload_sfx("land", 4)
	Root.preload_sfx("combo01")
	Root.preload_sfx("combo02")
	Root.preload_sfx("combo03")
	Root.preload_sfx("combo04")
	Root.preload_sfx("combo05")
	Root.preload_sfx("combo06")
	Root.preload_sfx("combo07")
	Root.preload_sfx("combo08")
	Root.preload_sfx("combo09")
	Root.preload_sfx("combo10")
	Root.preload_sfx("combo11")
	Root.preload_sfx("combo12")
	Root.preload_sfx("combo13")
	Root.preload_sfx("combo14")
	Root.preload_sfx("cry0")
	Root.preload_sfx("cry1")
	Root.preload_sfx("cry2")
	Root.preload_sfx("cry3")
	Root.preload_sfx("cry4")
	Root.preload_sfx("cry5")
	
	if Root.get_config("ctrl","type") == 1:
		# Gesture pad
		input_node = (load("res://InputGesture.tscn") as PackedScene).instance()
	else:
		# Button pad
		input_node = (load("res://InputButton.tscn") as PackedScene).instance()
	add_child(input_node)
# warning-ignore:return_value_discarded
	input_node.connect("move_left",       GameRoot, "_on_move_left")
# warning-ignore:return_value_discarded
	input_node.connect("move_right",      GameRoot, "_on_move_right")
# warning-ignore:return_value_discarded
	input_node.connect("rotate_left",     GameRoot, "_on_rotate_left")
# warning-ignore:return_value_discarded
	input_node.connect("rotate_right",    GameRoot, "_on_rotate_right")
# warning-ignore:return_value_discarded
	input_node.connect("soft_drop_start", GameRoot, "_on_soft_drop_start")
# warning-ignore:return_value_discarded
	input_node.connect("soft_drop_end",   GameRoot, "_on_soft_drop_end")
# warning-ignore:return_value_discarded
	input_node.connect("hard_drop_start", GameRoot, "_on_hard_drop_start")
# warning-ignore:return_value_discarded
	input_node.connect("warp_left",       GameRoot, "_on_warp_left")
# warning-ignore:return_value_discarded
	input_node.connect("warp_right",      GameRoot, "_on_warp_right")
	# bind joystick inputs
	button_node = (GameRoot.find_node("InputJoyKey") as Control)
# warning-ignore:return_value_discarded
	button_node.connect("move_left",       GameRoot, "_on_move_left")
# warning-ignore:return_value_discarded
	button_node.connect("move_right",      GameRoot, "_on_move_right")
# warning-ignore:return_value_discarded
	button_node.connect("rotate_left",     GameRoot, "_on_rotate_left")
# warning-ignore:return_value_discarded
	button_node.connect("rotate_right",    GameRoot, "_on_rotate_right")
# warning-ignore:return_value_discarded
	button_node.connect("soft_drop_start", GameRoot, "_on_soft_drop_start")
# warning-ignore:return_value_discarded
	button_node.connect("soft_drop_end",   GameRoot, "_on_soft_drop_end")
# warning-ignore:return_value_discarded
	button_node.connect("hard_drop_start", GameRoot, "_on_hard_drop_start")
# warning-ignore:return_value_discarded
	button_node.connect("warp_left",       GameRoot, "_on_warp_left")
# warning-ignore:return_value_discarded
	button_node.connect("warp_right",      GameRoot, "_on_warp_right")
	# add pause modal
	Pause = (load("res://PauseModal.tscn") as PackedScene).instance();
	add_child(Pause, true)
	pass

func bind(game_root):
	GameRoot = game_root
	if !GameRoot:
		print("GameObserver: No GameRoot found.")
		return
	else:
# warning-ignore:return_value_discarded
		GameRoot.connect("enter_phase_drop",  self, "enter_phase_drop")
# warning-ignore:return_value_discarded
		GameRoot.connect("enter_phase_erase", self, "enter_phase_erase")
# warning-ignore:return_value_discarded
		GameRoot.connect("enter_phase_spawn", self, "enter_phase_spawn")
# warning-ignore:return_value_discarded
		GameRoot.connect("enter_phase_move", self, "enter_phase_move")
# warning-ignore:return_value_discarded
		GameRoot.connect("game_over", self, "game_over")
# warning-ignore:return_value_discarded
		GameRoot.connect("game_clear", self, "game_clear")
# warning-ignore:return_value_discarded
		GameRoot.connect("pause_on", self, "pause_on")
		print("GameObserver: Connected to GameRoot.")

func enter_phase_drop(placed_domino: bool = false, x: int = -1, y: int = -1, direction: int = -1):
	print("GameObserver: About to enter drop phase.")
	phase = 1
	GameRoot.call_deferred("on_phase_drop")

func enter_phase_erase(_blocks_to_erase: int, _colors_to_erase: int, _enemies_to_erase: int, _blob_sizes: Array):
	print("GameObserver: About to enter erase phase.")
	phase = 2
	GameRoot.call_deferred("on_phase_erase")

func enter_phase_spawn():
	print("GameObserver: About to enter spawn phase.")
	phase = 3
	GameRoot.call_deferred("on_phase_spawn")

func enter_phase_move():
	print("GameObserver: About to enter move phase.")
	phase = 4
	GameRoot.call_deferred("on_phase_move")

func game_over():
	print("GameObserver: Game over!")
	phase = 5
	GameRoot.call_deferred("on_game_over")

func game_clear():
	print("GameObserver: Game cleared!")
	phase = 6
	GameRoot.call_deferred("on_game_clear")

func pause_on():
# warning-ignore:unsafe_method_access
	input_node.pause()
# warning-ignore:unsafe_method_access
	Pause.pause()
# warning-ignore:unsafe_method_access
	button_node.set_active(false)

func unpause():
	print("unpause")
	call_deferred("restart_input")

func restart_input():
	print("restart_input")
# warning-ignore:unsafe_method_access
	button_node.set_active(true)
# warning-ignore:unsafe_method_access
	input_node.unpause()

func bit_mask_from_colors(color_count):
	rng.randomize()
	match color_count:
		5:
			return 0x1F
		4:
			return 0x1F & ~(1 << rng.randi_range(0, 4))
		3:
			var veto0 = rng.randi_range(0, 4)
			var veto1 = rng.randi_range(0, 3)
			if veto1 >= veto0:
				veto1 += 1
			return 0x1F & ~(1 << veto0) & ~(1 << veto1)
