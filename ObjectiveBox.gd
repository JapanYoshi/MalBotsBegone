extends Control
const objective_list = [
	"I18N_OBJECTIVE_ZEN",
	"I18N_OBJECTIVE_SURVIVE",
	"I18N_OBJECTIVE_SURVIVE_TIME",
	"I18N_OBJECTIVE_ENEMY",
	"I18N_OBJECTIVE_ENEMY_COUNT",
	"I18N_OBJECTIVE_ENEMY_COLOR",
	"I18N_OBJECTIVE_ENEMY_COLOR_COUNT",
	"I18N_OBJECTIVE_BLOCK",
	"I18N_OBJECTIVE_BLOCK_COUNT",
	"I18N_OBJECTIVE_BLOCK_COLOR",
	"I18N_OBJECTIVE_BLOCK_COLOR_COUNT",
	"I18N_OBJECTIVE_CHAIN_COUNT",
	"I18N_OBJECTIVE_CHAIN_EXACT",
	"I18N_OBJECTIVE_HIGH_SCORE",
	"I18N_OBJECTIVE_COLORS"
]
enum OBJ_MONITOR {
	NONE,
	TIME,
	ENEMY,
	BLOCK,
	CHAIN,
	SCORE,
	COLOR,
	COLOR_MASK
}
export var objective_id: int = 0
export var objective_params: Array = []
var colormask: int = 0
var template: String = "Objective: %s"
var time_template: String = "%02d:%02d"
var raw_text: String = ""
var objective_monitor = OBJ_MONITOR.NONE
var goal: int = -1
var progress: int = 0

# Called when the node enters the scene tree for the first time.
func _ready():
	self.rect_min_size = self.rect_size
	template = TranslationServer.translate("I18N_OBJECTIVE")
	time_template = TranslationServer.translate("I18N_TIME_FORMAT")
	set_objective(objective_id, objective_params)

func parse_objective(data: Array):
	colormask = 0b00111111
	goal = 0
	progress = 0
	match data[0]:
		0x00:
			# Zen
			set_objective(0)
		0x01:
			# Survive
			if data[1] or data[2]:
				var time_to_survive = (data[1] << 8) + data[2]
				if time_to_survive > 900:
					printerr("ObjectiveBox - Time to survive is greater than 15 minutes == 900 seconds! (%d)" % time_to_survive)
				# Survive for n seconds
				goal = time_to_survive
				set_objective(2, [time_to_survive])
			else:
				# Survive ALAP
				goal = 0
				set_objective(1)
		0x02, 0x03, 0x04, 0x05:
			# Erase n colors of blocks at once
			goal = data[0]
			set_objective(14, [data[0]])
		0x06:
			# Beat score
			var score_to_beat = (data[1] << 24) + (data[2] << 16) + (data[3] << 8) + data[4]
			if score_to_beat >= 100000000:
				printerr("ObjectiveBox - Score to beat is greater than 99,999,999 points! (%d)" % score_to_beat)
			# TODO: Get high score
			goal = score_to_beat if bool(score_to_beat) else 11037
			set_objective(13, [score_to_beat])
		0x7F:
			# Clear enemies of any color
			if data[1]:
				# Clear n enemies
				goal = data[1]
				set_objective(4, [data[1]])
			else:
				# Clear all enemies
				goal = -1
				set_objective(3)
		0xBF:
			# Clear blocks of any color
			if data[1]:
				# Clear n blocks
				goal = data[1]
				set_objective(8, [data[1]])
			else:
				# Clear all blocks
				goal = -1
				set_objective(7)
		_:
			if data[0] < 0x20:
				printerr("ObjectiveBox - Could not convert value %X into objective." % data[0])
			elif data[0] < 0x30:
			# 0x20 - 0x2F: Cause an n-cascade or longer
				goal = data[0] - 0x1F
				set_objective(11, [data[0] - 0x1F])
			elif data[0] < 0x40:
			# 0x30 - 0x3F: Cause an n-cascade exactly
				goal = data[0] - 0x2F
				set_objective(12, [data[0] - 0x2F])
			elif data[0] < 0x80:
			# 0x41 - 0x7F: Clear n enemies of specific color(s)
				if data[0] == 0b01000000:
					printerr("ObjectiveBox - Bitmask is all off!")
				print("ObjectiveBox - Bitmask is %X" % (data[0] & 0b00111111))
				if data[1]:
					# Clear n enemies of specific colors
					colormask = data[0] & 0b00111111
					goal = data[1]
					set_objective(6, [data[1], data[0] & 0b00111111])
				else:
					# Clear all enemies of specific color
					colormask = data[0] & 0b00111111
					goal = -1
					set_objective(5, [data[0] & 0b00111111])
			elif data[0] < 0xC0:
			# 0x81 - 0xBF: Clear n blocks of specific color(s):
				if data[0] == 0b10000000:
					printerr("ObjectiveBox - Bitmask is all off!")
				if data[1]:
					# Clear n blocks of specific colors
					colormask = data[0] & 0b00111111
					goal = data[1]
					set_objective(10, [data[1], data[0] & 0b00111111])
				else:
					# Clear all blocks of specific color
					colormask = data[0] & 0b00111111
					goal = -1
					set_objective(9, [data[0] & 0b00111111])
			else:
				printerr("ObjectiveBox - Could not convert value %X into objective." % data[0])

func set_objective(key: int = 0, format: Array = []):
	objective_id = key
	raw_text = TranslationServer.translate(objective_list[key])
	objective_params = format
	match objective_list[key]:
		"I18N_OBJECTIVE_SURVIVE_TIME":
			# time
			objective_monitor = OBJ_MONITOR.TIME
		"I18N_OBJECTIVE_ENEMY",\
		"I18N_OBJECTIVE_ENEMY_COUNT",\
		"I18N_OBJECTIVE_ENEMY_COLOR",\
		"I18N_OBJECTIVE_ENEMY_COLOR_COUNT":
			# number of enemies
			objective_monitor = OBJ_MONITOR.ENEMY
		"I18N_OBJECTIVE_BLOCK",\
		"I18N_OBJECTIVE_BLOCK_COUNT",\
		"I18N_OBJECTIVE_BLOCK_COLOR",\
		"I18N_OBJECTIVE_BLOCK_COLOR_COUNT":
			# number of blocks
			objective_monitor = OBJ_MONITOR.BLOCK
		"I18N_OBJECTIVE_CHAIN_COUNT",\
		"I18N_OBJECTIVE_CHAIN_EXACT": # chain count
			objective_monitor = OBJ_MONITOR.CHAIN
		"I18N_OBJECTIVE_HIGH_SCORE": # score
			objective_monitor = OBJ_MONITOR.SCORE
		"I18N_OBJECTIVE_COLORS": # color
			objective_monitor = OBJ_MONITOR.COLOR
		_: # fallback
			objective_monitor = OBJ_MONITOR.NONE
	update_objective()

func update_objective():
#	print("ObjectiveBox - Raw text = ", raw_text, "; Objective params = ", objective_params)
	if objective_id in [5, 9]:
		$Text.bbcode_text = template % raw_text.format([format_colormask(colormask)])
	elif objective_id in [6, 10]:
		$Text.bbcode_text = template % raw_text.format([format_for_objective(goal), format_colormask(colormask)])
	elif objective_params == []:
		$Text.bbcode_text = template % raw_text
	else:
	#	print("    ", raw_text, " % ", format_for_objective(goal))
		$Text.bbcode_text = template % raw_text.format([format_for_objective(goal)])
	print("ObjectiveBox - ", $Text.bbcode_text)

func set_goal(value):
	goal = value
	update_objective()

func progress(value, relative = false):
	print("ObjectiveBox - progress: %3d / %3d" % [value, goal])
	if relative:
		goal -= value
		if goal < 0:
			goal = 0
	else:
		progress = value
	if progress >= goal:
		set_value(goal)
		self.find_parent("GameRoot").deferred_game_clear = true
	else:
		set_value(progress)

func set_value(value):
	objective_params = [value]
	update_objective()

func format_for_objective(goal):
	match objective_monitor:
		OBJ_MONITOR.TIME: # time
			return time_template % [goal / 60, goal % 60]
		OBJ_MONITOR.COLOR: # color count
			return "%d" % goal
		OBJ_MONITOR.CHAIN: # chain count
			return "%02d" % goal
		OBJ_MONITOR.BLOCK, OBJ_MONITOR.ENEMY: # number of blocks or enemies
			return "%03d" % goal
		OBJ_MONITOR.SCORE: # score
			return "%08d" % goal
		OBJ_MONITOR.NONE: # fallback
			return str(goal)

func format_colormask(value):
	var out_array = []
	for i in range(6):
		if value >> i & 1:
			out_array.push_back(TranslationServer.translate("I18N_COLOR_%d" % i))
	match len(out_array):
		0:
			return "ERROR: NO COLORS!"
		1:
			return out_array[0]
		2:
			return out_array[0] + TranslationServer.translate("I18N_COLOR_SEP_TWO") + out_array[1]
		_:
			var out_str = out_array[0]
			for i in range(1, len(out_array)):
				if i == len(out_array) - 1:
					out_str += TranslationServer.translate("I18N_COLOR_SEP_LAST")
				else:
					out_str += TranslationServer.translate("I18N_COLOR_SEP")
				out_str += out_array[i]
			return out_str

func just_cleared():
	print("ObjectiveBox -\n\\vvvvvvvvvvvvvvv/\n>GAME CLEARED!!!<\n/^^^^^^^^^^^^^^^\\")
	
