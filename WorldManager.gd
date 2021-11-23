extends Control

export var world_directory: String = "tutorial"
export var world_number: int = 0
export var tier_count: int = 1
export var scroller_path: NodePath
export var level_info_path: NodePath

var levels: Array
var save: Dictionary

onready var scroller = get_node(scroller_path)
onready var level_info = get_node(level_info_path)

func _ready():
	# play bgm
	Root.request_bgm("worldmap")
	
	# load level info
	levels = Root.load_levels(world_directory)
	scroller.initialize(world_directory, world_number, tier_count)
	
	# load high score and clear status
	save = Root.save_dict[world_directory]
	if typeof(save.cleared) == TYPE_STRING:
		save.cleared = save.cleared.hex_to_int()
	for tier_i in range(tier_count):
		for i in range(0, 4):
			var clear_bit = (save.cleared >> (tier_i * 4 + i)) & 1
			scroller.set_clear_status(tier_i, i, clear_bit)
			print("tier %d level %d clear status is %s" % [tier_i, i, str(clear_bit)])
	var clear_bit = (save.cleared >> (tier_count * 4)) & 1
	scroller.set_clear_status(tier_count, 0, clear_bit)
	print("boss clear status is %s" % [str(clear_bit)])
	
	# check if any of the following tiers are accessible too
	scroller.tier_list[0].set_access(true)
	for i in range(0, tier_count):
		if (save.cleared >> (i * 4)) & 0xF in [0b0111, 0b1011, 0b1101, 0b1110, 0b1111]:
			scroller.tier_list[i + 1].set_access(true)
		else:
			break
	# show error message
	# Root.show_message("I18N_MODE_NOT_DONE", 0)

func _on_s_level_hovered(tier, id):
	if $Tween.is_active():
		return
	if (
		id == 4 and len(levels) <= tier * 4 # boss not defined
	) or (
		id != 4 and len(levels) <= tier * 4 + id # non-boss not defined
	):
		printerr("Level out of range")
		level_info.show_info(tier, id, "ERROR: UNRECOGNIZED LEVEL", 0)
		return
	elif tier == -1: # hide
		level_info.show_info(-1, 0, "", -1)
	elif tier == tier_count: # boss
		id = 4
		var title = levels[tier * 4].data.name
		var highscore = 0
		if save.highscores.has(tier * 4):
			highscore = save.highscores[tier * 4]
		elif save.highscores.has(str(tier * 4)):
			# json fucked the int up into a string
			highscore = save.highscores[str(tier * 4)]
			# unfuck it up
			Root.save_dict[world_directory].highscores[tier * 4] = highscore
			Root.save_dict[world_directory].highscores.erase(str(tier * 4))
		level_info.show_info(tier, id, title, highscore)
	elif scroller.tier_list[tier].tier_accessible:
		var title = levels[tier * 4 + id].data.name
		var highscore = 0
		if save.highscores.has(tier * 4 + id):
			highscore = save.highscores[tier * 4 + id]
		elif save.highscores.has(str(tier * 4 + id)):
			# json fucked the int up into a string
			highscore = save.highscores[str(tier * 4 + id)]
			# unfuck it up
			Root.save_dict[world_directory].highscores[tier * 4 + id] = highscore
			Root.save_dict[world_directory].highscores.erase(str(tier * 4 + id))
		level_info.show_info(tier, id, title, highscore)
	else:
		level_info.show_info(tier, id, "", -1)

func _on_s_level_selected(tier, id):
	if $Tween.is_active():
		return
	Root.request_sfx("decide")
	Root.pass_between.world = world_directory
	Root.pass_between.level = levels[tier * 4 + id]
	Root.pass_between.level_index = tier * 4 + id
	$Tween.interpolate_property(
		self, "modulate", Color.white, Color.black, 0.5, Tween.TRANS_LINEAR
	)
	$Tween.start()
	Root.request_sfx("decide")

func _on_Tween_tween_completed(object, key):
	if key == ":modulate":
		if Root.pass_between.level.mode == "puzzle":
			if Root.pass_between.level.has("bgm"):
				Root.request_bgm(Root.pass_between.level.bgm)
			else:
				print("No music specified in the level data")
			Root.change_scene_direct("GameModePuzzle")
