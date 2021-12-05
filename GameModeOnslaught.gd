extends "res://GameModeHandler.gd"

var colormask: int
var colors: int = 4
var how_often_to_spawn: float = 30.0

onready var board_timer = load("res://GameCounter.tscn").instance()

func _ready():
	GameRoot.get_node("Plate/Board").add_child(board_timer)
	init_game()

func _process(delta):
	if GameRoot.aux_timer >= how_often_to_spawn:
		level += 1
		GameRoot.aux_timer -= how_often_to_spawn
		add_enemies()
		GameRoot.set_difficulty(level / 4)
		GameRoot.set_title(level)
	board_timer.set_value(int(max(ceil(how_often_to_spawn - GameRoot.aux_timer), 0)), 2)

func init_game():
	level = 1
	colormask = bit_mask_from_colors(colors)
	GameRoot.init_dominoes_in_next([
		0x02, colormask
	])
	Root.request_bgm("main")
	GameRoot.set_title(level)
	add_enemies()
#	.enter_phase_spawn("Onslaught: Init game")

func game_clear(world: String = "", level = ""):
	# player cleared all enemies! give bonus
	GameRoot.award_bonus(1000)
	# set the timer to spawn delay, so that
	# we add enemies the next frame
	GameRoot.aux_timer = how_often_to_spawn
	#.enter_phase_spawn("Onslaught: Cleared objective")

func add_enemies():
	var row_count = min(3, 1 + floor(level * 0.05))
	var battalion = GameRoot.generate_enemy_row(
		min(7, 1 + level * 0.1), # average enemy health
		min(1, level * 0.04), # enemy color ratio
		colormask << 1, # enemy color mask
		row_count
	)
	GameRoot.insert_row_below(battalion)
	GameRoot.load_objective([0x7F, 0]) # Clear all enemies

func game_over():
	GameRoot.check_highscore("arcade", "onslaught")
	.game_over()
