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
var current_bg: Node
var color_change_threshold = [8, 14]

# Called when the node enters the scene tree for the first time.
func _ready():
	level = 1
	BGBox = find_node("BGBox")
	GameRoot.set_difficulty(1)
	GameRoot.load_objective([0xBF, 50]) # Clear 50 blocks!
	GameRoot.load_board_state()
	GameRoot.init_dominoes_in_next([
		0x02, bit_mask_from_colors(colors_allowed)
	])
	GameRoot.set_title(1)
	GameRoot.on_phase_spawn("Marathon: Initialize")
	Root.request_bgm("main")
	current_bg = bgs[0].instance()
	add_child_below_node(BGBox, current_bg)
	pass # Replace with function body.

func game_clear():
	if level == 20:
		.game_clear()
		GameRoot.check_highscore("arcade", "marathon")
		GameRoot.call_deferred("on_game_clear")
	else:
		Root.request_sfx("level_up")
		level += 1
		current_bg.queue_free()
		current_bg = bgs[(level - 1) % len(bgs)].instance()
		add_child_below_node(BGBox, current_bg)
		GameRoot.set_difficulty(level)
		GameRoot.load_objective([0xBF, 50]) # Clear 50 blocks!
		GameRoot.set_title(level)
		.enter_phase_spawn("Marathon: Starting level %f" % level)
		if color_change_threshold.has(level):
			colors_allowed += 1
			GameRoot.NEXT.load_data([2, bit_mask_from_colors(colors_allowed)])

func game_over():
	GameRoot.check_highscore("arcade", "marathon")
	.game_over()
