extends Node
# GameRoot handles:
# 1. Display of pieces
# 2. Tracking the board state
# 3. Display of the NEXT queue
# 4. Tracking the NEXT queue
# And pretty much everything an instance of the Game needs.

# Different phases are signalled to the GameObserver using these.
# Swapping out the GameObserver lets different modes behave differently
# while keeping the same basic game mechanics.
var phase: String = "init"
signal enter_phase_drop(placed_domino, x, y, direction)
signal enter_phase_erase(block_count, color_count, enemy_damage_count, blob_sizes)
signal enter_phase_spawn
signal enter_phase_move
signal game_over
signal game_clear
signal pause_on
signal rejected_input(id)

# Store how much time has passed so processes can use it
var game_time: float = 0

# Internal variables to be used during piece clearing.
var block_count # int; count
var block_count_color
var color_count # int; count, not bitstring
var enemy_kill_count # int; count
var enemy_kill_count_color
var enemy_damage_count
var attack_spots # coords; may not be unique
var blob_sizes # Array of int

# Controls game difficulty during endless modes.
var gravity = 600
var difficulty = 1

# The resource for the Piece should be loaded ahead of time.
# Each new Piece is instantiated from here.
var Piece = preload("res://GamePiece.tscn")
# Shadow piece.
var Shadow = preload("res://GameShadow.tscn")
var ShadowCenter = Shadow.instance()
var ShadowOuter  = Shadow.instance()
# Position of shadow piece.
var shadow_center: Vector2
var shadow_outer: Vector2
# Domino resource and related variables.
var Domino = preload("res://GameDomino.tscn")
var moving_domino: Node = null
var moving_domino_x: int = 3
var moving_domino_y: int = 11
var offset: Vector2 = Vector2(0, 1)
var last_failed_move: float = -INF
var last_failed_rotate: float = -INF
var double_rotate_thres: float = 0.25
var last_placed_oob: bool = false
var moving_domino_speed: float = 1.0
# Board so we don't use $ so much.
onready var board = $Plate/Board

# The theme name.
# Stored as "custom/skin_name" in Config.
var theme_name = "Gen3"
var theme_scale: float = 2.0
# The size of the board, in grid spaces.
var board_size = Vector2(7, 14)
var shown_height = 12
# The dictionary for sentinel values on the board data.
var piece_dict = {
	0x00: "NULL",
	0x01: "Block1",
	0x02: "Block2",
	0x03: "Block3",
	0x04: "Block4",
	0x05: "Block5",
	0x06: "Wall",
	0x07: "Ball",

	0x08: "V0",
	0x09: "V1",
	0x0A: "V2",
	0x0B: "V3",
	0x0C: "V4",
	0x0D: "V5",
	0x0E: "END_ROW",
	0x0F: "END_DATA"
}
# The size of one grid space, in pixels.
var piece_size = 32
# Whether the player can move the Domino or not.
var input_allowed = false
var move_queue = []
enum moves {
	NONE,
	ROT_LEFT,
	ROT_RIGHT,
	MOVE_LEFT,
	MOVE_RIGHT,
	WARP_LEFT,
	WARP_RIGHT,
	SOFT_DROP_ON,
	SOFT_DROP_OFF,
	HARD_DROP
}
# Nodes that emit particles after hard dropping.
var hdp0: Node
var hdp1: Node
# A 2D Array of ints, storing which kind of piece the grid space contains.
var data; var data_dupe
# A 2D Array of ints, storing which Piece should visually occupy that grid space.
var node_ids
# A dictionary of references to the actual nodes, for use with `node_ids`.
var node_dict = {
	0: null
}
# This tracks the last used key for `node_dict`.
var last_used_index = 0
# This counts how many Pieces are currently in mid-air.
# Each Piece will call back to this object to decrement this value.
var now_falling = 0
# Used to track how many pieces are being deleted.
var now_deleting = 0
# The NEXT queue object.
var NEXTQUEUE = preload("res://NextQueue.gd")
var NEXT = NEXTQUEUE.new()
# An array of pieces, retrieved from the NEXT queue.
var dominoes_in_next = []
# The number of pieces left in the NEXT queue.
var next_rest = 0

# The pseudo-random number generator used for adding random pieces.
var rng = RandomNumberGenerator.new()
var last_used_seed = 0
# The pseudo-random number generator for non-gameplay elements.
var decorative_rng = RandomNumberGenerator.new()

# The velocity of the Piece that collided the fastest this frame.
# Used to queue sound effects.
var max_velocity_this_frame = 0.0

# Objective-related stuff.
var objective_box: Node
var starting_enemy_count = 0
var starting_block_count = 0
var enemies_on_the_board = 0
var deferred_game_clear: bool = false

# Text to display at the back of the playfield.
var game_text: Node

# Current actual score.
var score: int = 0
# Tweened, displayed score.
var score_display = 0
# Set to true when score is tweening.
var score_tweening = false
# Used to calculate scores.
var chain_count = 0
const chain_table = [
	0,	1,	2,	4,
	8,	12,	16
]
const hellfire_table = [
	0, 2, 3, 4, 5, 6, 7, 10
]
const color_table = [
	0, 3, 6, 12, 24
]
func _piece_name(i: int):
	if i < 16:
		return piece_dict[i]
	else:
		return piece_dict[i % 8 + 8]

func _chain_bonus(chain: int):
	assert (chain > 0, "Can't calculate a 0-chain")
	chain -= 1
	if chain < len(chain_table):
		return chain_table[chain]
	else:
		return min(chain, 12) * 8 - 32
	
func _hellfire_bonus(hellfire: int):
	assert (hellfire >= 4, "Can't pop fewer than 4 blocks")
	return hellfire_table[min(hellfire - 4, len(hellfire_table) - 1)]

func _color_bonus(colors: int):
	assert (colors > 0, "Can't pop 0 colors")
	assert (colors <= 5, "Only 5 colors")
	return color_table[colors - 1]

func _calculate_score(block_count_: int, color_count_: int, enemy_count_: int, blob_sizes_: Array):
	var chain_bonus = _chain_bonus(chain_count)
	var hellfire_bonus = 0
	for x in blob_sizes_:
		hellfire_bonus += _hellfire_bonus(x)
	var color_bonus = _color_bonus(color_count_)
	return 10 * (
		block_count_ + enemy_count_ * 5
	) * max(
		1, 
		chain_bonus * 8 + hellfire_bonus + color_bonus
	);

# Called when the node enters the scene tree for the first time.
func _ready():
	# Settng up some values...
	print("GameRoot ready")
	input_allowed = false
	$Plate/NextCaption.set_text(TranslationServer.translate("I18N_NEXT"))
	$Plate/RestCaption.set_text(TranslationServer.translate("I18N_REST"))
	$Plate/ScoreCaption.set_text(TranslationServer.translate("I18N_SCORE"))
	$Plate/TimeCaption.set_text(TranslationServer.translate("I18N_TIME"))
	theme_name = Root.get_config("custom", "skin_name")
	var size = Root.SYSCON.skin_sizes[theme_name]
	theme_scale = 32.0 / size
	NEXT.rng = rng
	board.get_node("Pieces").add_child(ShadowCenter)
	board.get_node("Pieces").add_child(ShadowOuter)
	# idk this doesn't work
#	ShadowCenter.hide()
#	ShadowOuter .hide()
	# so do this instead
	ShadowCenter.set_position(Vector2(-999, -999))
	ShadowOuter.set_position(Vector2(-999, -999))
	# fuck this makes me mad
	objective_box = $ObjectiveBox
	hdp0 = board.get_node("HardDropParticle0")
	hdp1 = board.get_node("HardDropParticle1")
	hdp0.theme()
	hdp1.theme()
	game_text = board.get_node("GameText")
	reset()

func set_title(title_or_level):
	if typeof(title_or_level) == 2:
		print(TranslationServer.translate("I18N_LEVEL_N") % title_or_level)
		$Plate/Stage.set_text(TranslationServer.translate("I18N_LEVEL_N") % title_or_level)
	elif typeof(title_or_level) == TYPE_STRING:
		$Plate/Stage.set_text(title_or_level)
	else:
		# fallback; should not occur
		$Plate/Stage.set_text(str(title_or_level))

func reset(objective = [0], board_state = [], dominoes_in_next = [false], rng_seed = false):
	phase = "init"
	if moving_domino:
		moving_domino.queue_free()
	input_allowed = false
	last_failed_rotate = -INF
	now_falling = 0
	now_deleting = 0
	game_time = 0
	chain_count = 0
	move_queue = []
	if typeof(rng_seed) == TYPE_BOOL:
		rng.randomize()
		print("GameRoot - randomizing RNG")
	else:
		rng.seed = rng_seed
		print("GameRoot - Setting seed to %d" % rng.seed)
	decorative_rng.randomize()
	game_text.reset()
	load_board_state(board_state)
	load_objective(objective)
	init_dominoes_in_next(dominoes_in_next)

func start_game():
	if phase != "init":
		printerr("GameRoot - Can't start game while phase is not init!")
	else:
		emit_signal("enter_phase_drop")

func load_objective(obj_data = [0]):
	objective_box.parse_objective(obj_data)
	if objective_box.goal == -1:
		scan_board()
	
# TEST ONLY!
# initializes the board state from a given board state,
# then immediately activates physics.
#func test_with_set_board_state(new_board_state):
#	load_board_state(new_board_state)
#	emit_signal("enter_phase_drop")

# TEST ONLY!
# generates a new board state randomly,
# then immediately activates physics.
#func test_with_random_board_state(new_seed:bool):
#	if new_seed:
#		last_used_seed = rng.randi()
#		rng.seed = last_used_seed
#	else:
#		rng.seed = last_used_seed
#	var test_board_state = []
#	for row in range(13):
#		test_board_state.append([])
#		for column in 7:
#			var piece_to_add
#			var roll = rng.randi_range(0, 6)
#			match roll:
#				0:
#					piece_to_add = 0
#				2, 3:
#					piece_to_add = 2
#				4, 5:
#					piece_to_add = 5
#				1:
#					piece_to_add = 8
#				6:
#					piece_to_add = 13
#			test_board_state[row].append(piece_to_add)
#	load_board_state(test_board_state)
#	emit_signal("enter_phase_drop")

func init_dominoes_in_next(data_: Array = [false]):
#	print("GameRoot - init_dominoes_in_next: ", data_)
	for elem in dominoes_in_next:
		if typeof(elem) != TYPE_NIL:
			elem.queue_free()
	dominoes_in_next = []
	if typeof(data_[0]) == TYPE_BOOL:
#		print("GameRoot - Successfully discarded NEXT queue")
		return
	elif typeof(data_[0]) == TYPE_INT:
		NEXT.load_data(data_)
	elif (typeof(data_[0]) == TYPE_ARRAY or typeof(data_[0]) == TYPE_INT_ARRAY):
		if len(data_[0]) == 2:
			NEXT.load_tuples(data_)
		else:
			push_error("Level data: NEXT is an array but it was not of two ints.")
	else:
		NEXT.load_dominoes(data_)
	while len(dominoes_in_next) < 6:
		var next = NEXT.get_next($Plate/Next)
		next.set_visual()
		dominoes_in_next.push_back(next)
	show_dominoes_in_next(true)
	next_rest = NEXT.data_length
	update_rest_number()

func update_rest_number():
	if next_rest >= 0:
		$Plate/Rest.text = "%03d" % next_rest
	else:
		$Plate/Rest.text = "∞"

func show_dominoes_in_next(init: bool = false):
	for i in range(len(dominoes_in_next)):
		var pos
		match i:
			0:
				pos = Vector2(20, 52)
				dominoes_in_next[i].set_rot(0)
			_:
				pos = Vector2(20, 56 + i * 36)
				if init or i + 1 == len(dominoes_in_next):
					dominoes_in_next[i].set_rot(1, true)
		if init:
			dominoes_in_next[i].position = pos
		else:
			$NextTween.interpolate_property(
				dominoes_in_next[i], "position",
				dominoes_in_next[i].position, pos,
				0.5, Tween.TRANS_QUAD, Tween.EASE_OUT
			)

# Loads the board state from board data.
# The board data should be a 2D Array,
# of up to 14 rows and up to 7 columns.
# NOTE: Board data starts from the BOTTOM-LEFT!
func load_board_state(new_data = []):
	data = []; node_ids = [];
	# clear old data
	for key in node_dict.keys():
		if node_dict[key]:
			node_dict[key].free()
	last_used_index = 0
	now_falling = 0
	now_deleting = 0
	# iterate through rows of data
	for row in range(len(new_data)):
		data.append(
			[0, 0, 0, 0, 0, 0, 0] # TODO: replace with PackedInt32Array
		)
		node_ids.append(
			[0, 0, 0, 0, 0, 0, 0] # TODO: replace with PackedInt32Array
		)
		# iterate through each row
		for column in range(len(new_data[row])):
			match _piece_name(new_data[row][column]):
				"NULL":
					data[row][column] = 0
					node_ids[row][column] = 0
				"END_ROW", "END_DATA":
					break
				"Block1", "Block2", "Block3", "Block4", "Block5":
					if (objective_box.colormask >> (new_data[row][column])) & 1:
						starting_block_count += 1
					load_new_piece(row, column, new_data[row][column])
				"V0", "V1", "V2", "V3", "V4", "V5":
					if (objective_box.colormask >> (new_data[row][column] % 8)) & 1:
						starting_enemy_count += 1
					load_new_piece(row, column, new_data[row][column])
				_:
					# load one new piece
					load_new_piece(row, column, new_data[row][column])
	# make it have (at least) 14 rows
	while len(data) < board_size.y:
		data.append([0, 0, 0, 0, 0, 0, 0])
		node_ids.append([0, 0, 0, 0, 0, 0, 0])
	assert(len(data) == board_size.y and len(node_ids) == board_size.y)

func scan_board():
	var block_count = 0
	var enemy_count = 0
	var color_block_count = 0
	var color_enemy_count = 0
	for row in data:
		for space in row:
			match space:
				1, 2, 3, 4, 5:
					block_count += 1
					if (objective_box.colormask >> space) & 1:
						color_block_count += 1
				0, 6, 7:
					pass
				_:
					enemy_count += 1
					if (objective_box.colormask >> (space & 7)) & 1:
						color_enemy_count += 1
	match objective_box.objective_monitor:
		objective_box.OBJ_MONITOR.BLOCK:
			if objective_box.colormask:
				objective_box.set_goal(color_block_count)
			else:
				objective_box.set_goal(block_count)
		objective_box.OBJ_MONITOR.ENEMY:
			if objective_box.colormask:
				objective_box.set_goal(color_enemy_count)
			else:
				objective_box.set_goal(enemy_count)

func print_board():
	# debug print
	print("GameRoot - print_board()")
	for row in range(len(data)):
		print(board_size.y - row - 1, "D", data[board_size.y - row - 1])
#	print("---")
#	for row in range(len(data)):
#		print(board_size.y - row - 1, "R", node_ids[board_size.y - row - 1])
	print("---")

# Loads and initializes a new Piece object,
# appends it to the Board object,
# and sets its position.
func load_new_piece(row, column, which):
#	print("GameRoot - Loading piece %d on row %d, column %d." % [which, row, column])
	if which == 0x0E:
		printerr("GameRoot - You can't load a sprite for the end of the row!")
		return
	if which == 0x0F:
		printerr("GameRoot - You can't load a sprite for the end of level data!")
		return
	assert (\
		data[row][column] == 0,\
		"You can't load a piece where data already exists! (%d, %d)" % [row, column]
	)
	# store board data
	data[row][column] = which
	# generate new node for piece
	last_used_index += 1
	node_dict[last_used_index] = Piece.instance()
	node_ids[row][column] = last_used_index
	# initialize state of the new node
	$Plate/Board/Pieces.add_child(node_dict[last_used_index])
	var count = which >> 3
	node_dict[last_used_index].set_piece(which, _piece_name(which), count, last_used_index)
	node_dict[last_used_index].set_position(
		Vector2(
			column, -row
		) * piece_size
	)

# Iterates through the board data to cause necessary Pieces to fall.
func on_phase_drop():
	if input_allowed:
		printerr("GameRoot - Drop phase initiated while player movement is allowed!")
		return
	if now_falling:
		printerr("GameRoot - Drop phase initiated while other pieces are falling")
		return
#	print("GameRoot - on_phase_drop")
	phase = "drop"
	var all_clear = true
	block_count = 0
	block_count_color = 0
	enemy_kill_count = 0
	enemy_kill_count_color = 0
	enemy_damage_count = 0
	for row in range(0, board_size.y):
		for column in range(board_size.x):
			if !(data[row][column] in [0, 6, 7]):
				all_clear = false
			if row != 0: # no pieces to check below bottom row
				drop_one(row, column)
	if !now_falling:
		check_surround()
		if all_clear:
			if game_time > 0:
				_on_all_clear()
			if !deferred_game_clear:
				emit_signal("enter_phase_spawn")
	else:
		emit_signal("enter_phase_erase", block_count, color_count, enemy_damage_count, blob_sizes)
		
	#print("Total falling pieces: ", now_falling)

# For each piece, iterates through the board data downward,
# to check whether the piece should fall, to where it should fall,
# and which piece is directly below it.
# Which piece is directly below it will be referenced during
# physics calculation, to simplify the procedure.
func drop_one(row, column):
	#print("row ", row , " column ", column, " data ", piece_dict[data[row][column]])
	# If the space is affected by gravity,
	# find the next piece below.
	match _piece_name(data[row][column]):
		"NULL":
			return
		"Wall":
			# find the next non-empty space
			var row_below = row - 1
			while (row_below >= 0):
				#print("Wall is checking row ", row_below)
				if _piece_name(data[row_below][column]) in ["NULL"]:
					row_below -= 1
				else:
					node_dict[node_ids[row][column]].drop(
						node_dict[node_ids[row_below][column]],
						-row * piece_size
					)
					return;
			# no piece below!
			node_dict[node_ids[row][column]].drop(
				null,
				-row * piece_size
			)
			return
		_:
			#print("Dropping piece ID %03d which is %x" % [node_ids[row][column], data[row][column]])
			var row_begin = row
			while (
				# not bottom row
				row > 0
			):
				if (
					# space below is NOT empty
					!_piece_name(data[row-1][column]) in ["NULL"]\
				):
					break
				# move piece down
				data    [row-1][column] = data    [row][column]
				node_ids[row-1][column] = node_ids[row][column]
				# clear space above
				data    [row][column] = 0
				node_ids[row][column] = 0
				# check again
				row -= 1
			#print("final position ", row, " ", column)
			if row != row_begin:
				node_dict[node_ids[row][column]].drop(
					node_dict[node_ids[row-1][column]],
					-row * piece_size
				)
#				$Rest.text = "f" + str(now_falling)

# Pieces call this function once they've stopped dropping.
func decrement_dropping():
	if now_falling == 0:
		printerr("decrement_dropping called while nothing is falling")
		now_falling = 0
	else:
#	print("GameRoot - decrement_dropping")
		now_falling -= 1
#	$Rest.text = str(now_falling)
	#print("Piece settled. Total falling pieces: ", now_falling)
	if !now_falling:
		# prepare transition to erasing phase
#		print_board()
		check_surround()

func check_surround():
#	print("GameRoot - check_surround")
	# we will modify data
	data_dupe = data.duplicate(true)
	# find blocks to erase
	var blocks_to_erase = []
	var colors_bitstring = 0b00000000
	blob_sizes = []
	for row in range(shown_height):
		for column in range(len(data[row])):
			match data_dupe[row][column]:
				1, 2, 3, 4, 5:
#					print("Checking space ", row, ",", column, " for neighbors.")
					var coords = check_surround_one(data_dupe[row][column], row, column)
#					print("Checking of space ", row, ",", column, " finished with the following neighbors:\n", coords)
					# NOTE: These are (x, y) coords a.k.a. (column, row) coords
					for coord in coords:
#						print(coord, " is getting marked: ", node_ids[coord[1]][coord[0]])
						data_dupe[coord[1]][coord[0]] = 0
#						node_dict[node_ids[coord[1]][coord[0]]].find_node("Label").text = str(len(coords))
					if len(coords) >= 4:
						blocks_to_erase += (coords)
						blob_sizes.append(len(coords))
				0:
					pass
				_:
#					node_dict[node_ids[row][column]].find_node("Label").text = ""
					pass
#	print("Blocks to erase: ", blocks_to_erase)
	if !len(blocks_to_erase):
		if objective_box.objective_list[objective_box.objective_id] == "I18N_OBJECTIVE_CHAIN_EXACT":
			if objective_box.goal == chain_count:
				deferred_game_clear = true
		elif objective_box.objective_list[objective_box.objective_id] == "I18N_OBJECTIVE_CHAIN_COUNT":
			if objective_box.goal <= chain_count:
				deferred_game_clear = true
		chain_count = 0
		emit_signal("enter_phase_spawn")
		return
	else:
		#print("GameRoot - There are blocks to erase, and the current chain count is %d." % chain_count)
		chain_count += 1
		#print("GameRoot - Now the chain count is %d." % chain_count)
		# find Enemies to erase
		attack_spots = []
		var pop_position = [0, 0]
		for i in len(blocks_to_erase):
			var coord = blocks_to_erase[i]
			# also, bc we're iterating through blocks to erase anyway,
			# take the opportunity to log the color of the block
			colors_bitstring = colors_bitstring | 1 << (data[coord.y][coord.x] - 1)
			# and get the average position
			pop_position[0] += coord.x; pop_position[1] += coord.y
			# check if there are surrounding Enemies to erase
			for difference in [Vector2(-1, 0), Vector2(1, 0), Vector2(0, -1), Vector2(0, 1)]:
				var to_check = coord + difference
#				print("checking ", to_check)
				if to_check.x < 0 or to_check.x >= board_size.x or to_check.y < 0 or to_check.y >= shown_height:
#					print("space is out of bounds")
					pass
				elif data[to_check.y][to_check.x] >= 8:
#					print("block: ", piece_dict[data[coord.y][coord.x]], "; other: ", piece_dict[data[to_check.y][to_check.x]], " (enemy)")
					if (
						data[to_check.y][to_check.x] % 8 == 0 or
						data[to_check.y][to_check.x] % 8 == data[coord.y][coord.x]
					):
						attack_spots.append(to_check)
				else:
#					print("block: ", piece_dict[data[coord.y][coord.x]], "; other: ", piece_dict[data[to_check.y][to_check.x]], " (not enemy)")
					pass
		attack_spots.sort()
		pop_position[0] /= float(len(blocks_to_erase)); pop_position[1] /= float(len(blocks_to_erase));
		
#		print("Enemies to erase: ", enemies_to_erase)
		color_count = 0
		while colors_bitstring:
			color_count += colors_bitstring & 1
			colors_bitstring = colors_bitstring >> 1
		prepare_erase(blocks_to_erase)
		# Update the objective box.
		match objective_box.objective_list[objective_box.objective_id]:
			"I18N_OBJECTIVE_COLORS":
				if color_count >= objective_box.goal:
					deferred_game_clear = true
					objective_box.just_cleared()
		$Plate/GameChain.set_position(
			$Plate/Board/Pieces.get_transform().get_origin() +
			Vector2(pop_position[0] * piece_size, pop_position[1] * -piece_size) +
			Vector2(64, -64)
		)
				

func check_surround_one(value: int, row: int, column: int) -> Array:
#	print("check_surround_one(", row,",", column,")")
	data_dupe[row][column] = 0 # clear space, replace later
	var coords = []
	coords.append(Vector2(column, row))
	if row > 0 and data_dupe[row-1][column] == value:
#		print("Recursing to lower neighbor: ", data[row-1][column], "==", value)
		coords += check_surround_one(value, row-1, column)
#	else:
#		print("Lower neighbor does not match")
	if row < shown_height - 1 and data_dupe[row+1][column] == value:
#		print("Recursing to upper neighbor: ", data[row+1][column], "==", value)
		coords += check_surround_one(value, row+1, column)
#	else:
#		print("Upper neighbor does not match")
	if column > 0 and data_dupe[row][column-1] == value:
#		print("Recursing to left neighbor: ", data[row][column-1], "==", value)
		coords += check_surround_one(value, row, column-1)
#	else:
#		print("Left neighbor does not match")
	if column < board_size.x - 1 and data_dupe[row][column+1] == value:
#		print("Recursing to right neighbor: ", data[row][column+1], "==", value)
		coords += check_surround_one(value, row, column+1)
#	else:
#		print("Right neighbor does not match")
#	print("Final coords at ", row, ",", column, "=", coords)
	#data_dupe[row][column] = value
	assert(typeof(coords) == TYPE_ARRAY)
	return coords

func prepare_erase(blocks_to_erase):
	print("GameRoot - prepare_erase with chain counter %02d" % chain_count)
	# coords to erase are guaranteed to be unique
	block_count = 0
	block_count_color = 0
	for coord in blocks_to_erase:
		block_count += 1
		if objective_box.colormask:
			block_count_color += (objective_box.colormask >> data[coord.y][coord.x]) & 1
		else:
			block_count_color += 1
		node_dict[node_ids[coord.y][coord.x]].damage()
		# remove the node from the data;
		# it will ask to be unloaded later
		data[coord.y][coord.x] = 0
		node_ids[coord.y][coord.x] = 0
	# attack spots are not guaranteed to be unique,
	# bc the same spot may be attacked twice
	enemy_kill_count = 0
	enemy_kill_count_color = 0
	var enemy_color_mask = 0x00
	enemy_damage_count = 0
	for i in range(len(attack_spots)):
		var coord = attack_spots[i]
		
		# check if it's unique
#		if i == 0 or coord != attack_spots[i-1]:
#			print("unique")
#			pass
		# send damage to the object
		if !(node_dict[node_ids[coord.y][coord.x]]) or node_dict[node_ids[coord.y][coord.x]].count <= 0:
			# already dead! prevent overkill
			pass
		elif node_dict[node_ids[coord.y][coord.x]].count <= chain_count:
			# last hit; remove the node from the data
			# it will ask to be unloaded later
			enemy_damage_count += 1
			enemy_kill_count += 1
			enemy_color_mask = enemy_color_mask | (1 << (data[coord.y][coord.x] & 7))
			if objective_box.colormask:
				print("GameRoot - color %x data %x - Enemy defeated." % [objective_box.colormask, data[coord.y][coord.x]])
				# increments enemy-of-right-color count if the correct color is killed
				enemy_kill_count_color += (objective_box.colormask >> (data[coord.y][coord.x] % 8)) & 1
			# shouldn't even need this part but in case i do...
			else:
				print("GameRoot - color %x data %x - Enemy defeated." % [objective_box.colormask, data[coord.y][coord.x]])
				# increments enemy-of-right-color count if any color is killed
				enemy_kill_count_color += 1
			node_dict[node_ids[coord.y][coord.x]].damage(chain_count)
			data[coord.y][coord.x] = 0
			node_ids[coord.y][coord.x] = 0
		else:
			# not last hit; keep the node in the data
			enemy_damage_count += 1
			node_dict[node_ids[coord.y][coord.x]].damage(chain_count)
	print(
		"GameRoot\n- Block ", block_count, # int; count
		", Color ", color_count, # int; count, not bitstring
		", Enemy (defeat) ", enemy_kill_count, # int; count
		", Enemy (damage) ", enemy_damage_count,
		", Atk Spots ", attack_spots, # coords; may not be unique
		", Sizes ", blob_sizes # Array of int
	)
	match objective_box.objective_list[objective_box.objective_id]:
		"I18N_OBJECTIVE_BLOCK", "I18N_OBJECTIVE_BLOCK_COUNT",\
		"I18N_OBJECTIVE_BLOCK_COLOR", "I18N_OBJECTIVE_BLOCK_COLOR_COUNT":
			objective_box.progress(block_count_color, true)
		"I18N_OBJECTIVE_ENEMY", "I18N_OBJECTIVE_ENEMY_COUNT",\
		"I18N_OBJECTIVE_ENEMY_COLOR", "I18N_OBJECTIVE_ENEMY_COLOR_COUNT":
			objective_box.progress(enemy_kill_count_color, true)
		"I18N_OBJECTIVE_COLORS":
			if color_count >= objective_box.goal:
				deferred_game_clear = true
				objective_box.just_cleared()
		_:
			print("GameRoot - Objective not in the match statement: ", objective_box.objective_list[objective_box.objective_id])
	request_enemy_cries(enemy_color_mask)
	emit_signal("enter_phase_erase", block_count, color_count, enemy_damage_count, blob_sizes)

func on_phase_erase():
	phase = "erase"
	if now_deleting:
		call_deferred("on_phase_erase")
		return
	# are we even erasing any blocks here
	if block_count == 0:
		emit_signal("enter_phase_drop")
		return
	# show score gain
	score_tweening = false
	var score_gain = _calculate_score(block_count, color_count, enemy_damage_count, blob_sizes)
	$Plate/Score.text = "+" + str(int(score_gain))
	$Plate/GameChain.set_number(chain_count)
	$Plate/GameChain.pop_up()
	score += score_gain
	# DO NOT count the multiple-HP enemies that survived!
	print("GameRoot - Erasing %d blocks and %d enemies." % [block_count, enemy_kill_count])
	now_deleting = block_count + enemy_kill_count
	# each popping piece has bound itself to $PopTimer.timeout()
	if !$PopTimer.is_stopped():
		# force pop timer to fire
		$PopTimer.set_wait_time(0)
	$PopTimer.wait_time = 0.5
	$PopTimer.start()
#	$Rest.text = "x" + str(now_deleting)
# TODO:
# Makes the first Domino in the queue playable,
# and generates the next Domino from the NEXT object.
func on_phase_spawn():
	if input_allowed:
		printerr("GameRoot - Spawn phase initiated prematurely while user input is allowed!")
		return
	phase = "spawn"
	if objective_box.objective_list[objective_box.objective_id] == "I18N_OBJECTIVE_HIGH_SCORE":
		objective_box.progress(score, false)
	if deferred_game_clear:
		emit_signal("game_clear")
		deferred_game_clear = false
		# wait 5 seconds before returning to the previous menu
		$GameClearedTimer.start()
		return
	if (
		!last_placed_oob and # last placed at least partially in bounds
		data[shown_height - 1][3] == 0 and # spawn block is free
		dominoes_in_next.front().id_0 != 0 # next queue has a block
	):
		moving_domino = dominoes_in_next.pop_front()
		moving_domino.subgrid_speed = moving_domino_speed
		var new_next = NEXT.get_next($Plate/Next)
		new_next.set_visual()
		new_next.stall_timer = 0
		dominoes_in_next.push_back(new_next)
		$NextTween.interpolate_property(
			moving_domino, "position",
			moving_domino.position, moving_domino.position + Vector2(0, -72),
			0.5, Tween.TRANS_QUAD, Tween.EASE_OUT
		)
		show_dominoes_in_next()
		next_rest -= 1
		update_rest_number()
		$NextTween.start()
	else:
		if last_placed_oob:
			print("GameRoot - Game over by OOB placement!")
		elif next_rest <= 0:
			print("GameRoot - Game over by empty NEXT queue!")
		else:
			print("GameRoot - Game over by filled spawn point!")
		emit_signal("game_over")

func on_phase_move():
	phase = "move"
	print("GameRoot - Enable user input")
	$Plate/Next.remove_child(moving_domino)
# warning-ignore:integer_division
	moving_domino_x = int(board_size.x) / 2
	moving_domino_y = shown_height - 1
	moving_domino.position = Vector2(0.5 + floor(board_size.x / 2), 0.5 - shown_height) * piece_size
	$Plate/Board/Pieces.add_child(moving_domino)
	moving_domino.set_active(true)
	input_allowed = true
	print("GameRoot - Moving domino is at ", moving_domino.get_global_transform_with_canvas().get_origin())
	call_deferred("init_shadow")
	ShadowCenter.show()
	ShadowOuter .show()

func on_game_clear():
	Root.request_bgm("game_clear")
	print("Game cleared")
	game_text.game_clear()
	phase = "init"
	deferred_game_clear = false
	input_allowed = false
	if is_instance_valid(moving_domino):
		moving_domino.queue_free()
	now_falling = 0
	move_queue = []
	set_paused(true)
	

func on_game_over():
	Root.request_bgm("game_over")
	game_text.game_over()
	for piece in node_dict.values():
		if piece:
			piece.joy()
	set_paused(true)

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	# FPS display for debugging.
	var fps = round(1.0 / max(0.001, delta))
	$Plate/Label.text = str(int(fps)) + " FPS"
	
	if input_allowed:
		game_time += delta
		# Game time display, since we're tracking it anyway.
		var minutes = game_time / 60
		$Plate/Time.text = "%02d'%02d.%1d" % [minutes, int(game_time) % 60, int(game_time * 10) % 10]
		# Update the objective box.
		if objective_box.objective_list[objective_box.objective_id] == "I18N_OBJECTIVE_SURVIVE_TIME":
			if objective_box.goal <= game_time:
				emit_signal("game_clear")
	# Track the fastest colliding Piece every frame,
	# and queue sound effects if something collided this frame.
	if now_falling and max_velocity_this_frame:
		if max_velocity_this_frame > 100:
			# Something fell. Queue sound effects.
	#		print("Max velocity was ", max_velocity_this_frame)
	#		$Label.text = str(max_velocity_this_frame)
			Root.request_sfx_length("land", (max_velocity_this_frame - 100) / 2560)
	max_velocity_this_frame = 0.0
	# Tween score display
	if score_tweening:
		$Plate/Score.text = "%08d" % int(min(99999999, score_display))
#		print("Tweening score from ", score_display, " to ", score)
		if score_display == score:
			score_tweening = false
	# process queued inputs
	if !is_instance_valid(moving_domino) and len(move_queue):
		move_queue.clear()
	while len(move_queue) > 0:
#		print("GameRoot - ", len(move_queue), " queued movements: ", move_queue)
		var next_move = move_queue.pop_front()
		match next_move:
			moves.MOVE_LEFT:
#				print("GameRoot - Dequeued move left")
				if move_queue.has(moves.MOVE_RIGHT):
#					print("GameRoot - Move right in queue, canceling")
					move_queue.erase(moves.MOVE_RIGHT)
				else:
# warning-ignore:return_value_discarded
					try_move(false)
			moves.MOVE_RIGHT:
#				print("GameRoot - Dequeued move right")
				if move_queue.has(moves.MOVE_LEFT):
#					print("GameRoot - Move left in queue, canceling")
					move_queue.erase(moves.MOVE_LEFT)
				else:
# warning-ignore:return_value_discarded
					try_move(true)
			moves.ROT_LEFT:
#				print("GameRoot - Dequeued rotate left")
				if move_queue.has(moves.ROT_RIGHT):
#					print("GameRoot - Rotate right in queue, canceling")
					move_queue.erase(moves.ROT_RIGHT)
				else:
# warning-ignore:return_value_discarded
					try_rotate(false)
			moves.ROT_RIGHT:
#				print("GameRoot - Dequeued rotate right")
				if move_queue.has(moves.ROT_LEFT):
#					print("GameRoot - Rotate left in queue, canceling")
					move_queue.erase(moves.ROT_LEFT)
				else:
# warning-ignore:return_value_discarded
					try_rotate(true)
			moves.SOFT_DROP_ON:
#				print("GameRoot - Dequeued soft drop")
				if move_queue.has(moves.SOFT_DROP_OFF):
#					print("GameRoot - Soft drop off in queue, canceling")
					move_queue.erase(moves.SOFT_DROP_OFF)
				else:
					set_soft_drop(true)
			moves.SOFT_DROP_OFF:
#				print("GameRoot - Dequeued soft drop off")
				if move_queue.has(moves.SOFT_DROP_ON):
#					print("GameRoot - Soft drop in queue, canceling")
					move_queue.erase(moves.SOFT_DROP_ON)
				else:
					set_soft_drop(false)
			moves.HARD_DROP:
#				print("GameRoot - Dequeued hard drop")
				call_deferred("hard_drop")
			moves.WARP_LEFT:
#				print("GameRoot - Dequeued warp left")
				if move_queue.has(moves.WARP_RIGHT):
#					print("GameRoot - Warp right in queue, canceling")
					move_queue.erase(moves.WARP_RIGHT)
				else:
# warning-ignore:return_value_discarded
					try_warp(false)
			moves.WARP_RIGHT:
#				print("GameRoot - Dequeued warp right")
				if move_queue.has(moves.WARP_LEFT):
#					print("GameRoot - Warp left in queue, canceling")
					move_queue.erase(moves.WARP_LEFT)
				else:
# warning-ignore:return_value_discarded
					try_warp(true)
			_:
				printerr("GameRoot - Invalid value ", next_move, " in move_queue")

#func _input(event):
#	# Just for testing! The actual input should be handled by another element.
#	if event.is_action_pressed("ui_accept"):
#		test_with_random_board_state(true)
#	elif event.is_action_pressed("ui_cancel"):
#		test_with_random_board_state(false)

# Pieces call this when colliding.
# The board stores the speed of the fastest dropping Piece
# in order to queue sound effects.
func submit_velocity(velocity: float):
	if velocity > max_velocity_this_frame:
		max_velocity_this_frame = velocity

func free_me(id: int):
	assert(now_deleting > 0, "free_me called while nothing should be deleted")
	if (node_dict.has(id)):
		node_dict[id].queue_free()
		node_dict.erase(id)
		now_deleting -= 1
#		$Rest.text = "x" + str(now_deleting)
#		print("GameRoot - free_me; now deleting: ", now_deleting)
		if now_deleting == 0:
			emit_signal("enter_phase_drop")
	else:
		print("GameRoot - free_me double-call?")

func _on_PopTimer_timeout():
#	print("GameRoot - PopTimer timed out, requesting SFX")
	Root.request_sfx("combo%02d" % min(14, chain_count))
	$ScoreTween.interpolate_property(
		self, "score_display", score_display, score,
		0.5, Tween.TRANS_CUBIC, Tween.EASE_OUT
	)
	$ScoreTween.start()
	$Plate/GameChain.pop_out()
	score_tweening = true

func _on_NextTween_end():
	print("GameRoot - NextTween ended. Entering phase move")
	emit_signal("enter_phase_move")

func rot_to_offset(rot: int) -> Vector2:
	match rot % 4:
		0:
			return Vector2( 0,  1)
		1:
			return Vector2( 1,  0)
		2:
			return Vector2( 0, -1)
		_:
			return Vector2(-1,  0)

func init_shadow():
	ShadowCenter.get_child(0).frames = load(Root.SYSCON.sprite_root + theme_name + "/Block%1d.spriteframes.tres" % moving_domino.id_0)
	if !ShadowCenter.get_child(0).frames:
		printerr("ShadowCenter.frames could not load")
	ShadowOuter.get_child(0).frames  = load(Root.SYSCON.sprite_root + theme_name + "/Block%1d.spriteframes.tres" % moving_domino.id_1)
	if !ShadowOuter.get_child(0).frames:
		printerr("ShadowCenter.frames could not load")
	ShadowCenter.get_child(0).animation = "idle"
	ShadowOuter .get_child(0).animation = "idle"
	ShadowCenter.get_child(0).auto_scale()
	ShadowOuter .get_child(0).auto_scale()
	update_shadow()

func update_shadow():
	offset = rot_to_offset(moving_domino.direction)
	var center_pos = Vector2(moving_domino_x, moving_domino_y)
	var outer_pos = center_pos + offset
	while (
		_y_in_bounds(center_pos.y - 1) and
		_y_in_bounds(outer_pos.y  - 1) and
		data[center_pos.y - 1][moving_domino_x] == 0 and
		data[outer_pos.y  - 1][outer_pos.x    ] == 0
	):
#		print("Can drop from row ", center_pos.y)
		center_pos.y -= 1
		outer_pos.y  -= 1
	shadow_center = center_pos
	shadow_outer  = outer_pos
#	print("GameRoot - Shadow is at %2d,%2d and %2d,%2d" % [shadow_center.x, shadow_center.y, shadow_outer.x, shadow_outer.y])
	ShadowCenter.position = shadow_center * piece_size * Vector2(1, -1)
	ShadowOuter.position =  shadow_outer * piece_size * Vector2(1, -1)

func domino_may_descend() -> bool:
	return (
		moving_domino_y != shadow_center.y
	)

func lock_domino(silent: bool = false):
	if !moving_domino:
		printerr("GameRoot: Attempt to lock nonexistent domino! (Hard drop at the same frame as the stall timer running out naturally?)")
		return;
	ShadowCenter.hide()
	ShadowOuter .hide()
	input_allowed = false
	offset = rot_to_offset(moving_domino.direction)
	# find out whether the blocks end up in bounds
	var center_y = moving_domino_y
	while center_y >= shown_height and ( # checked block is not displayed
			center_y >= board_size.y or # off the top of the field
			data[center_y - 1][moving_domino_x] == 0 # block below is blank
		):
		center_y -= 1
	if center_y >= shown_height:
		var outer_y = moving_domino_y + offset.y
		while outer_y >= shown_height and ( # checked block is not displayed
			outer_y >= board_size.y or # off the top of the field
			data[outer_y - 1][moving_domino_x + offset.x] == 0 # block below is blank
		):
			outer_y -= 1
		if outer_y >= shown_height:
#			print("GameRoot - Both blocks are out of bounds: ", center_y, " ", outer_y)
			last_placed_oob = true
		else:
#			print("GameRoot - Outer block is in bounds: ", center_y, " ", outer_y)
			last_placed_oob = false
	else:
#		print("GameRoot - Center block is in bounds: ", center_y)
		last_placed_oob = false
	# load new pieces
	load_new_piece(moving_domino_y, moving_domino_x, moving_domino.id_0)
	load_new_piece(moving_domino_y + offset.y, moving_domino_x + offset.x, moving_domino.id_1)
	if !silent:
		Root.request_sfx("lock")
	emit_signal("enter_phase_drop", true, moving_domino_x, moving_domino_y, moving_domino.direction)
	moving_domino.queue_free()

# returns whether or not the movement succeeded
func try_move(right: bool = false, silent: bool = false) -> bool:
	var to_move = moving_domino_x + (1 if right else -1)
	print("GameRoot - Trying to move domino ", "right" if right else "left", " at column ", moving_domino_x, " row ", moving_domino_y, " and sub-grid timer ", moving_domino.subgrid_timer)
	if !_x_in_bounds(to_move):
		# definitely can't move center block to out of bounds
		return false
	#offset = rot_to_offset(moving_domino.direction)
	if (
		# center block is unobstructed
		data[moving_domino_y][to_move] == 0 and
		# outer block is in bounds
		_vec2_in_bounds(offset + Vector2(to_move, moving_domino_y)) and
		# outer block is unobstructed
		data[moving_domino_y + offset.y][to_move + offset.x] == 0
	):
		# can move
		if !silent:
			Root.request_sfx("move")
		moving_domino_x = to_move
		print("GameRoot - moved to %02d,%02d!" % [moving_domino_x, moving_domino_y])
		moving_domino.move_right_up(1 if right else -1, 0)
		_after_moving()
		return true
	# initial check failed; try one block up
	var may_bump_up = moving_domino.subgrid_timer > 0.75
	if may_bump_up:
		print("GameRoot - Checking bumped up position at row ", moving_domino_y + 1)
		var check_y = moving_domino_y + 1
		if (
			# we're not moving the center block above bounds
			_y_in_bounds(check_y) and
			# center block target is not occupied
			data[check_y][to_move] == 0 and
			# outer block target is in bounds
			_vec2_in_bounds(offset + Vector2(to_move, check_y)) and
			# outer block target is not occupied
			data[check_y + offset.y][to_move + offset.x] == 0
		):
			# can move
			if !silent:
				Root.request_sfx("move")
			moving_domino_x = to_move
			moving_domino_y = check_y
			print("GameRoot - moved to %02d,%02d!" % [moving_domino_x, moving_domino_y])
			moving_domino.move_right_up(1 if right else -1, 1)
			moving_domino.floor_kick()
			_after_moving()
			return true
	if last_failed_move + 0.2 < game_time:
		Root.request_sfx("move_fail")
	last_failed_move = game_time
	return false

func _after_moving():
	# calculate shadow
	# updates the offset too
	update_shadow()
	if (
		# OOB above center block
		!_y_in_bounds(moving_domino_y + 1) or
		# block above center block
		data[moving_domino_y + 1][moving_domino_x] or
		# OOB above outer block
		!_vec2_in_bounds(offset + Vector2(
			moving_domino_x, moving_domino_y + 1
		)) or
		# block above outer block
		data[moving_domino_y + 1 + offset.y][moving_domino_x + offset.x]
	):
		print("GameRoot - Grazed the ceiling. Moving the Domino down.")
		moving_domino.graze_ceiling()
	else:
		print("GameRoot - Did not graze a ceiling.")
	return true

func try_warp(right: bool = false) -> bool:
	var moved_distance = 0
	while true:
		var result = try_move(right, true)
		if result:
			moved_distance += 1
		else:
			break
	if moved_distance:
		# calculate shadow
		update_shadow()
		Root.request_sfx("move_warp")
		return true
	else:
		return false

func try_rotate(right: bool = false) -> bool:
	var new_direction = (moving_domino.direction + (1 if right else 3)) % 4
#	print("GameRoot - Trying to rotate to direction ", new_direction)
	# new position of the outer piece
	var outer = rot_to_offset(new_direction) + Vector2(moving_domino_x, moving_domino_y)
	if _vec2_in_bounds(outer):
		# position is in bounds, check if grid-space is occupied
		if 0 == data[outer.y][outer.x]:
			# grid-space is vacant. can rotate
			Root.request_sfx("rotate")
#			print("GameRoot - Rotating without kicks...")
			moving_domino.rot(1 if right else -1)
			update_shadow()
			return true
		else:
			pass
	# can't rotate, check for wall or floor kicks
#	print("GameRoot - Can't rotate. Check for wall or floor kicks.")
	match new_direction:
		1:
			# kick the right wall; check the block to the left
			if (moving_domino_x > 0 and # there's space to move left
				0 == data[moving_domino_y][moving_domino_x - 1]): # space is blank
#				print("GameRoot - Kicking to left and rotating...")
				Root.request_sfx("rotate")
				moving_domino.rot(1 if right else -1)
				moving_domino_x -= 1
				moving_domino.move_right_up(-1, 0)
				update_shadow()
				return true
			elif moving_domino.direction == 0:
				#   OO[]      00OO[]
				# []00[]  ->  []  []
				# [][][]      [][][]
				var to_check = Vector2(moving_domino_x - 1, moving_domino_y + 1)
				if _vec2_in_bounds(to_check) and 0 == data[to_check.y][to_check.x]:
#					print("GameRoot - Side-kicking up and rotating...")
					Root.request_sfx("rotate")
					moving_domino.rot(1)
					moving_domino_y += 1
					moving_domino_x -= 1
					moving_domino.move_right_up(-1, 1)
					moving_domino.floor_kick()
					update_shadow()
					return true
				# []OO        []00OO
				# []00[]  ->  []  []
				# [][][]      [][][]
				to_check = Vector2(moving_domino_x + 1, moving_domino_y + 1)
				if _vec2_in_bounds(to_check) and 0 == data[to_check.y][to_check.x]:
#					print("GameRoot - Side-kicking up and rotating...")
					Root.request_sfx("rotate")
					moving_domino.rot(1)
					moving_domino_y += 1
					moving_domino.move_right_up(0, 1)
					moving_domino.floor_kick()
					update_shadow()
					return true
		3:
			# kick the left wall
			if (moving_domino_x < board_size.x - 1 and # there's space to move right
				0 == data[moving_domino_y][moving_domino_x + 1]): # space is blank
#				print("GameRoot - Kicking to right and rotating...")
				Root.request_sfx("rotate")
				moving_domino.rot(1 if right else -1)
				moving_domino_x += 1
				moving_domino.move_right_up(1, 0)
				update_shadow()
				return true
			elif moving_domino.direction == 0:
				# []OO        []OO00
				# []00[]  ->  []  []
				# [][][]      [][][]
				var to_check = Vector2(moving_domino_x + 1, moving_domino_y + 1)
				if _vec2_in_bounds(to_check) and 0 == data[to_check.y][to_check.x]:
#					print("GameRoot - Side-kicking up and rotating...")
					Root.request_sfx("rotate")
					moving_domino.rot(-1)
					moving_domino_y += 1
					moving_domino_x += 1
					moving_domino.move_right_up(1, 1)
					moving_domino.floor_kick()
					update_shadow()
					return true
				#   OO[]      OO00[]
				# []00[]  ->  []  []
				# [][][]      [][][]
				to_check = Vector2(moving_domino_x - 1, moving_domino_y + 1)
				if _vec2_in_bounds(to_check) and 0 == data[to_check.y][to_check.x]:
#					print("GameRoot - Side-kicking up and rotating...")
					Root.request_sfx("rotate")
					moving_domino.rot(-1)
					moving_domino_y += 1
					moving_domino.move_right_up(0, 1)
					moving_domino.floor_kick()
					update_shadow()
					return true
		2:
			# kick the floor; check for block above
			if (moving_domino_y < board_size.y - 1 and
				0 == data[moving_domino_y + 1][moving_domino_x]):
#				print("GameRoot - Kicking the floor and rotating...")
				Root.request_sfx("rotate")
				moving_domino.rot(1 if right else -1)
				moving_domino_y += 1
				moving_domino.move_right_up(0, 1)
				moving_domino.floor_kick()
				update_shadow()
				return true
		_:
			# kick the ceiling (possible if there's a block); check for block below
			if (moving_domino_y > 0 and
				0 == data[moving_domino_y - 1][moving_domino_x]):
#				print("GameRoot - Kicking the ceiling and rotating...")
				Root.request_sfx("rotate")
				moving_domino.rot(1 if right else -1)
				moving_domino_y -= 1
				moving_domino.move_right_up(0, -1)
				moving_domino.floor_kick()
				update_shadow()
				return true
#	print("GameRoot - Can't kick. Is this a double-rotation?")
	if last_failed_rotate + double_rotate_thres > game_time:
#		print("GameRoot - Yes, double rotate...")
		Root.request_sfx("rotate")
		moving_domino.rot(2)
		match moving_domino.direction:
			0:
				moving_domino_y -= 1
				moving_domino.move_right_up(0, -1)
			1:
				moving_domino_x -= 1
				moving_domino.move_right_up(-1, 0)
			2:
				moving_domino_y += 1
				moving_domino.move_right_up(0, 1)
			_:
				moving_domino_x += 1
				moving_domino.move_right_up(1, 0)
		last_failed_rotate = -INF
		update_shadow()
		return true
	last_failed_rotate = game_time
#	print("GameRoot - Check failed. Cannot rotate.")
	Root.request_sfx("rotate_fail")
	return false

func set_soft_drop(on: bool = true):
	moving_domino.fast_drop = on

func hard_drop():
	hdp0.set_color(moving_domino.id_0); hdp1.set_color(moving_domino.id_1)
#	print_board()
#	print("Hard drop started from row ", moving_domino_y, ", column ", moving_domino_x)
	if shadow_center.y != moving_domino_y:
		# fall distance
		Root.request_sfx("harddrop")
		var drop_distance = moving_domino_y - shadow_center.y
		score += drop_distance
		$ScoreTween.interpolate_property(
			self, "score_display", score_display, score,
			drop_distance / 20.0, Tween.TRANS_LINEAR
		)
		$ScoreTween.start()
		moving_domino_y = int(shadow_center.y)
		score_tweening = true
		# particles
		hdp0.set_height(drop_distance); hdp1.set_height(drop_distance)
		match moving_domino.direction:
			0:
				hdp1.position = Vector2(
					moving_domino_x * 32,
					(shown_height - moving_domino_y - 1) * 32
				)
				hdp1.emit()
			1:
				hdp0.position = Vector2(
					moving_domino_x * 32,
					(shown_height - moving_domino_y) * 32
				)
				hdp1.position = Vector2(
					(moving_domino_x + 1) * 32,
					(shown_height - moving_domino_y) * 32
				)
				hdp0.emit(); hdp1.emit()
			2:
				hdp0.position = Vector2(
					moving_domino_x * 32,
					(shown_height - moving_domino_y) * 32
				)
				hdp0.emit()
			3:
				hdp0.position = Vector2(
					moving_domino_x * 32,
					(shown_height - moving_domino_y) * 32
				)
				hdp1.position = Vector2(
					(moving_domino_x - 1) * 32,
					(shown_height - moving_domino_y) * 32
				)
				hdp0.emit(); hdp1.emit()
	else:
		# no fall distance
		Root.request_sfx("lock")
	lock_domino(true)

func request_enemy_cries(colormask: int):
	print("GameRoot - Requesting enemy cries: %x" % colormask)
	for i in range(0, 6):
		if ((colormask >> i) & 1):
			Root.request_sfx("cry%d" % i)

func _on_move_left():
	if input_allowed:
		move_queue.push_back(moves.MOVE_LEFT)
		move_queue.sort()
	else:
		emit_signal("rejected_input", moves.MOVE_LEFT)

func _on_move_right():
	if input_allowed:
		move_queue.push_back(moves.MOVE_RIGHT)
		move_queue.sort()
	else:
		emit_signal("rejected_input", moves.MOVE_RIGHT)

func _on_rotate_left():
	if input_allowed:
		move_queue.push_back(moves.ROT_LEFT)
		move_queue.sort()
	else:
		emit_signal("rejected_input", moves.ROT_LEFT)

func _on_rotate_right():
	if input_allowed:
		move_queue.push_back(moves.ROT_RIGHT)
		move_queue.sort()
	else:
		emit_signal("rejected_input", moves.ROT_RIGHT)

func _on_soft_drop_start():
	if input_allowed:
		move_queue.push_back(moves.SOFT_DROP_ON)
		move_queue.sort()
	else:
		emit_signal("rejected_input", moves.SOFT_DROP_ON)

func _on_soft_drop_end():
	if input_allowed:
		move_queue.push_back(moves.SOFT_DROP_OFF)
		move_queue.sort()
	else:
		emit_signal("rejected_input", moves.SOFT_DROP_OFF)

func _on_hard_drop_start():
	if input_allowed:
		move_queue.push_back(moves.HARD_DROP)
		move_queue.sort()
	else:
		emit_signal("rejected_input", moves.HARD_DROP)

func _on_warp_left():
	if input_allowed:
		move_queue.push_back(moves.WARP_LEFT)
		move_queue.sort()

func _on_warp_right():
	if input_allowed:
		move_queue.push_back(moves.WARP_RIGHT)
		move_queue.sort()

func _x_in_bounds(x: int):
	return (x >= 0 and x < board_size.x)

func _y_in_bounds(y: int):
	return (y >= 0 and y < board_size.y)

func _vec2_in_bounds(check_pos: Vector2):
	return (_x_in_bounds(int(check_pos.x)) and _y_in_bounds(int(check_pos.y)))

func _on_all_clear():
	print("All Clear!")
	Root.request_sfx("empty")
	score += 100
	game_text.all_clear()
	$ScoreTween.interpolate_property(
		self, "score_display", score_display, score,
		0.5, Tween.TRANS_CUBIC, Tween.EASE_OUT
	)
	$ScoreTween.start()
	score_tweening = true

func set_difficulty(value: int):
	difficulty = value
	moving_domino_speed = pow(2.0, (value / 4.0) - 1)
	gravity = 500 + 50 * value

func _on_InputJoyKey_pause():
	emit_signal("pause_on")

func _on_Pause_pressed():
	emit_signal("pause_on")

func generate_enemy_row(average_enemy_health, enemy_color_ratio, enemy_color_mask, rows = 1):
	if enemy_color_ratio > 0 and enemy_color_mask == 0:
		printerr("Can't generate colored enemies with no allowed colors!")
		enemy_color_ratio = 0.0
	# Output is stored here.
	# It will be rows * 7 items long, matching the 7 columns per row.
	var new_data = PoolByteArray()
	var pieces = 7 * rows
	
	## First, convert the bit mask into an array of allowed colors,
	## for easy processing later.
	# An array of integers standing for an allowed color, from 1 to 5 inclusive.
	var colors = PoolByteArray()
	for i in range(1, 6):
		if (enemy_color_mask >> i) & 1:
			colors.push_back(i)
	
	## Each enemy will be either gray or a random allowed color,
	## at a ratio approximating enemy_color_ratio.
	# Expected value for how many enemies will NOT be gray.
	var expected_color = int(enemy_color_ratio * pieces)
	
	## Each enemy will have either floor or ceil average_enemy_health,
	## at a ratio approximating the decimal portion of it.
	# Baseline for enemies' health.
	var health_baseline = floor(average_enemy_health)
	# Expected value for how many enemies will have one more hit point.
	var expected_health_add = int((average_enemy_health - health_baseline) * pieces)
	# Generate in order first
	new_data = Root.byte_array_repeat(8 * (health_baseline + 1), expected_health_add) + Root.byte_array_repeat(8 * health_baseline, pieces - expected_health_add)
	var new_color_data = Root.byte_array_repeat(0, pieces)
	for i in range(expected_color):
		new_color_data[i] = (colors[rng.randi_range(0, len(colors) - 1)])
	# Shuffle colors
	new_color_data = Root.byte_array_shuffle(new_color_data, rng)
	new_data = Root.byte_array_add(new_data, new_color_data)
	new_data = Root.byte_array_shuffle(new_data, rng)
	
	# Finally distribute into rows
	var final_data = [[]]
	var i = 0
	while len(new_data):
		if i == 7:
			i = 0
			final_data.push_back([])
		var last: int = new_data.size() - 1
		final_data.back().push_back(new_data[last])
		new_data.resize(last)
		i += 1
	return final_data

func insert_row_below(new_data):
	set_paused(true)
	# move existing data up
	var moved_pieces = false
	var rows_to_move = new_data.size()
	print(len(data), "-", data.size(), "-", data.front())
	for row in range(data.size() - 1, 0 - 1, -1):
		var oob = row + rows_to_move >= data.size()
		moved_pieces = true
		for column in range(0, 7):
			if data[row][column]:
				node_dict[node_ids[row][column]].position.y -= rows_to_move * piece_size
				# we are gonna temporarily have extra rows of pieces
				# we'll free them once the tween ends
				data[row + rows_to_move] = data[row]
				node_ids[row + rows_to_move] = node_ids[row]
	assert(moved_pieces)
	# overwrite the data once we've moved the data up
	for row in range(0, rows_to_move):
		data[row] = [0, 0, 0, 0, 0, 0, 0]; node_ids[row] = [0, 0, 0, 0, 0, 0, 0]
	# iterate through each NEW row
	for row in range(rows_to_move):
		for column in range(0, 7):
			if (objective_box.colormask >> (new_data[row][column] % 8)) & 1:
				starting_enemy_count += 1
			load_new_piece(row, column, new_data[row][column])
	#animate the board moving upward
	board.get_node("Tween").interpolate_property(
		board.get_node("Pieces"), "position"
		, Vector2(0
			, (shown_height + rows_to_move) * piece_size
		), Vector2(0
			, (shown_height               ) * piece_size
		)
		, 0.5, Tween.TRANS_QUAD, Tween.EASE_OUT
	)
	board.get_node("Tween").start()
	# if the domino is there, recalculate its shadow
	if is_instance_valid(moving_domino):
		# moving_domino_y is positive=up	
		moving_domino_y += rows_to_move
		update_shadow()

func set_paused(pause: bool = true):
	input_allowed = !pause
	if is_instance_valid(moving_domino):
		moving_domino.active = !pause
		ShadowCenter.visible = !pause
		ShadowOuter.visible = !pause

func award_bonus(points: int = 0):
	game_text.bonus()
	score += points
	score_tweening = true

func _on_pieces_moved_up():
	# remember how i said there were gonna be extra rows?
	# we free them here
	while len(node_ids) > board_size.y:
		for i in range(0, 7):
			# free the node in the top row
			node_dict[node_ids.back()[i]].queue_free()
			# then erase the entry for it
			node_dict.erase(node_ids.back()[i])
		node_ids.pop_back()
		data.pop_back()
	set_paused(false)

func _on_GameClearedTimer_timeout():
	Root.request_bgm_stop()
	Root.back_scene()

func show_highscore(old_highscore):
	var high_score_text = board.get_node("HighScoreText")
	high_score_text.get_child(0).set_bbcode(TranslationServer.translate("I18N_NEW_RECORD") + "\n%08d → %08d" % [old_highscore, score])
	high_score_text.show()
