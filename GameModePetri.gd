extends "res://GameModeHandler.gd"

var initialized: bool = false
var colormask: int
var colors: int = 4
var height: int = 3
var color_ratio: float = 0.5
var avg_health: float = 2.4

func set_params(colors_: int, height_: int, color_ratio_: float, avg_health_: float, level_: int):
	colors = colors_
	height = height_
	color_ratio = color_ratio_
	avg_health = avg_health_
	level = level_
	initialized = true

func _ready():
	if !initialized:
		if "mode" in Root.pass_between and Root.pass_between.mode == "Petri":
			set_params(
				Root.pass_between.colors,
				Root.pass_between.rows,
				Root.pass_between.color_ratio,
				Root.pass_between.hp,
				Root.pass_between.level
			)
		else:
			set_params(
				4,
				3,
				0.5,
				1.25,
				0
			)
	init_game()

func init_game():
	GameRoot.load_board_state()
	GameRoot.set_difficulty(level)
	colormask = bit_mask_from_colors(colors)
	var battalion = GameRoot.generate_enemy_row(
		avg_health, # average enemy health
		color_ratio, # enemy color ratio
		colormask << 1, # enemy color mask
		height
	)
	GameRoot.init_dominoes_in_next([
		0x02, colormask
	])
	Root.request_bgm("main")
	GameRoot.set_title(TranslationServer.translate("I18N_MODE_PETRI"))
	GameRoot.insert_row_below(battalion)
	GameRoot.load_objective([0x7F, 0]) # Defeat all enemies
	# the below probably should be triggered by a signal back from root instead 
	#$Timer.wait_time = 1.0 - pow(0.5, len(battalion))
	#$Timer.connect("timeout", self, "enter_phase_spawn", ["Petri: Init game"])
	#$Timer.start()

func game_clear():
	GameRoot.check_highscore("arcade", "petri")
	.game_clear()
	GameRoot.call_deferred("on_game_clear")

func game_over():
	GameRoot.check_highscore("arcade", "onslaught")
	.game_over()
