extends "res://GameModeHandler.gd"

const bgs = [
	preload("res://bg/bg_000.tscn"),
	preload("res://bg/bg_001.tscn"),
	preload("res://bg/bg_002.tscn"),
	preload("res://bg/bg_003.tscn"),
	preload("res://bg/bg_004.tscn"),
	preload("res://bg/bg_005.tscn")
]
var BGBox
var current_bg

# Called when the node enters the scene tree for the first time.
func _ready():
	BGBox = find_node("BGBox")
	GameRoot.load_board_state()
	GameRoot.init_dominoes_in_next([
		0x02, 0b00001111
	])
	GameRoot.on_phase_spawn()
	Root.request_bgm("main")
	current_bg = bgs[0].instance()
	add_child_below_node(BGBox, current_bg)
	GameRoot.load_objective([0])
	pass # Replace with function body.

func enter_phase_spawn():
	if GameRoot.score > (level + 1) * 1000:
		level = GameRoot.score / 1000
		var new_bg = bgs[level % len(bgs)].instance()
		add_child_below_node(BGBox, new_bg)
		current_bg.queue_free()
		current_bg = new_bg
	.enter_phase_spawn()
