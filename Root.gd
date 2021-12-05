extends Node

const DEBUG = true;

# To be auto-loaded as Singleton

# The `GlobalRoot` node is placed right below the root node,
# and lets each component access the sound handler,
# configurations, and system constants.
# That is to say:
# This is the node that loads everyhing else used in the game!

# The sound handler is a Scene containing one AudioStreamPlayer
# that plays music, and several AudioStreamPlayers that load
# and play sound effects as needed.
var sound_handler
var SOUND_HANDLER = preload("res://SoundHandler.tscn")
# The config file stores settings. Most of them can be changed
# by the user, through the settings screen.
var config = ConfigFile.new()
var first_time = true

var save_dict = {
	"arcade": {
		"highscores": {
			"marathon": 0,
			"petri": 0,
			"onslaught": 0,
			"mission": 0,
			"zen": 0
		}
	},
	"tutorial": {
		"cleared": "0x0",
		"highscores": {}
	},
	"world1": {
		"cleared": "0x0",
		"highscores": {}
	},
	"world2": {
		"cleared": "0x0",
		"highscores": {}
	},
	"world3": {
		"cleared": "0x0",
		"highscores": {}
	},
	"world4": {
		"cleared": "0x0",
		"highscores": {}
	},
	"world5": {
		"cleared": "0x0",
		"highscores": {}
	}
}
var save_dict_backup = save_dict.duplicate(true)

# The list of supported locales, in alphabetical order of country code.
var locales
# The default locale's country code.
var default_locale
# SYStem CONstants.
var SYSCON = {}
# Currently loaded scene stack.
var scene_stack = []
var _new_node

const Next = preload("res://NextClass.gd").Next

var preloaded_scene: Node
var preloaded_scene_name: String
var _loader: ResourceInteractiveLoader

var pass_between: Dictionary

# Fonts.
var px_regular: DynamicFont; var px_bold: DynamicFont;
var px_small: DynamicFont; var px_piece: DynamicFont;
var fb_regular: DynamicFont; var fb_bold: DynamicFont;
var fb_small: DynamicFont; var fb_piece: DynamicFont;

# Message icons.
var icon_warn = preload("res://icons/msg_warn.png")
var icon_info = preload("res://icons/msg_info.png")
var icon_error = preload("res://icons/msg_error.png")

signal dialog_result(confirmed)

# RNG.
var rng = RandomNumberGenerator.new()

const input_actions = [
	"ui_accept",
	"ui_cancel",
	"gp_left",
	"gp_right",
	"gp_b",
	"gp_a",
	"gp_soft",
	"gp_hard",
	"gp_pause"
]

const COLUMNS = 7;
const ROWS = 14;

var load_wait: float = 0;
var load_progress: float = 0;

func _process(delta):
	if _loader != null:
		dp("Root - result polling (wait time %5.2fs)" % load_wait)
		var result = _loader.poll()
		dp("Root - result == %d" % result)
		if result == OK and load_wait < 30.0:
			load_progress = (float(_loader.get_stage()) / _loader.get_stage_count() * 100)
# warning-ignore:unsafe_method_access
			$CanvasLayer/Loading/Prog.set_text(
				"%05.1f%%" % load_progress
			)
			load_wait += delta
			#print("Root - Resource load at %05.1f%% (time spent: %05.2fs)" % [load_progress, load_wait])
			return
		elif result == ERR_FILE_EOF:
			# don't worry, this just means it's done loading
			dp("Root - Resource finished loading")
# warning-ignore:unsafe_method_access
			$CanvasLayer/Loading/Prog.set_text(
				"Almost there"
			)
			_add_scene()
			return
		else:
			add_log("Root - Failed to load resource at %05.1f%% with error code %s" % [load_progress, result])
			_loader = null
			show_error("Failed to load resource: Error code %s" % result)
			return

# Called when the node enters the scene tree for the first time.
func _ready():
	# Make sure this is correctly loaded as a Singleton
	assert(self == Root)
	
	# Load configurations
	config.load("user://settings.cfg")
	if config.has_section("main"):
		first_time = false
	else:
		dp("First time boot!")
	# Load keybinds
	load_inputs()
	# Load system constants from JSON
	var file = File.new()
	file.open("res://constants.json", file.READ)
	SYSCON = JSON.parse(file.get_as_text())
	file.close()
	if SYSCON.error == OK:
		SYSCON = SYSCON.get_result()
		dp("SYStem CONstants parsed successfully.")
	else:
		printerr(
			"SYStem CONstants could not be parsed!\n"
			+ "JSON parse error on line "
			+ String(SYSCON.get_error_line()) + ";\n"
			+ String(SYSCON.get_error_string())
		)
	# Load and instantiate the sound handler
	var new_sound_handler = SOUND_HANDLER.instance()
	dp(str(new_sound_handler) + "SoundHandler")
	self.add_child(new_sound_handler)
	sound_handler = new_sound_handler
	# Apply the saved sound volume
	set_vol_bgm(config.get_value("main", "vol_bgm", -1))
	set_vol_sfx(config.get_value("main", "vol_sfx", -1))
	# Get the list of locales supported
	locales = TranslationServer.get_loaded_locales()
	locales.sort()
	dp("Loaded locales: " + String(locales))
	# Get the default locale
	default_locale = TranslationServer.get_locale()
	# Change the locale, if the player has changed it
	if config.has_section("main") and config.has_section_key("main", "language"):
		if typeof(config.get_value("main", "language")) == TYPE_STRING:
			dp("Initializing locale to: " + config.get_value("main", "language"))
			TranslationServer.set_locale(config.get_value("main", "language"))
	# Apply the user's font settings
	px_regular = load(SYSCON.font_root + "sys12_400.tres")
	px_bold = load(SYSCON.font_root + "sys12_700.tres")
	px_small = load(SYSCON.font_root + "sys10_400.tres")
	px_piece = load(SYSCON.font_root + "piece_number.tres")
	fb_regular = load(SYSCON.font_root + "fallback_400.tres")
	fb_bold = load(SYSCON.font_root + "fallback_700.tres")
	fb_small = load(SYSCON.font_root + "fallback_400.tres")
	fb_piece = load(SYSCON.font_root + "fallback_piece.tres")
	if config.has_section("a11y") and config.has_section_key("a11y", "font_size"):
		if typeof(config.get_value("a11y", "font_size")) == TYPE_STRING:
			dp("Initializing font size to: " + str(config.get_value("a11y", "font_size")))
			apply_font(config.get_value("a11y", "font_size"))
	else:
		apply_font(0)
	$ErrorLayer/ConfirmDialog.get_ok().set_text("YES")
	$ErrorLayer/ConfirmDialog.get_cancel().set_text("NO")
	$ErrorLayer/ConfirmDialog.get_cancel().connect("pressed", self, "_on_ConfirmDialog_cancelled")
	
	load_game()

# Unloads the current scene.
# If another scene is already loaded, it is deactivated.
func change_scene(name_: String):
	if len(scene_stack) and name_ == scene_stack.back(): return
	if get_tree().get_current_scene() and name_ == get_tree().get_current_scene().name: return
	dp("Root - change_scene(%s), %s" % [name_, scene_stack])
	dp("Root - loading scene res://%s.tscn" % name_)
# warning-ignore:unsafe_method_access
	$CanvasLayer/Loading.show()
# warning-ignore:unsafe_method_access
	$CanvasLayer/AnimationPlayer.play("Loading")
	if get_tree().get_current_scene():
		get_tree().get_current_scene().queue_free()
	load_wait = 0
	load_progress = 0
	dp("Root - freed current scene")
	var new_uri = "res://" + name_ + ".tscn"
	if _loader != null:
		show_error("Already loading a scene")
		return
	_loader = ResourceLoader.load_interactive(new_uri, "PackedScene")
	dp("Root - started loading scene resource")
	if _loader == null: # Check for errors.
# warning-ignore:unsafe_method_access
		$CanvasLayer/Loading.hide()
# warning-ignore:unsafe_method_access
		$CanvasLayer/AnimationPlayer.stop(false)
		show_error("Could not load scene %s." % new_uri)
		return
	scene_stack.push_back(name_)

# Unloads the current scene.
# If another scene is already loaded, it is deactivated.
func change_scene_direct(name_: String):
	if len(scene_stack) and name_ == scene_stack.back(): return
	if get_tree().get_current_scene() and name_ == get_tree().get_current_scene().name: return
	dp("Root - change_scene_direct(%s), %s" % [name_, scene_stack])
	dp("Root - loading scene res://%s.tscn" % name_)
	if get_tree().get_current_scene():
		get_tree().get_current_scene().queue_free()
	get_tree().change_scene("res://%s.tscn" % name_)
	scene_stack.push_back(name_)

func _add_scene():
	dp("Root - adding scene to tree")
# warning-ignore:unsafe_method_access
	_new_node = _loader.get_resource().instance()
	_loader = null
	_new_node.set_name(scene_stack.back())
	_new_node.visible = false
	if false:
	#if _new_node.has_signal("ready_finished"):
		# this causes the main thread to freeze
		# start a thread
		dp("Root - connecting ready signal to this node")
		_new_node.connect("ready_finished", self, "_on_scene_loaded")
		get_tree().get_root().add_child(_new_node)
		# this causes the main thread to freeze, but
		# we assume it's not a problem
	else:
		dp("Root - adding child to root of scene tree")
		get_tree().get_root().add_child(_new_node)
		_on_scene_loaded()
	#set_process(true)

func _add_to_scene_tree(_dummy):
	dp("Root - Thread reporting! Adding child to root of scene tree")
	get_tree().get_root().add_child(_new_node)
	dp("Root - added child to root of scene tree in thread")
	return

func _on_scene_loaded():
# warning-ignore:unsafe_method_access
	$Timer.stop()
	dp("Root - new scene is now ready to go")
	_new_node.visible = true
# warning-ignore:unsafe_method_access
	$CanvasLayer/Loading.hide()
# warning-ignore:unsafe_method_access
	$CanvasLayer/AnimationPlayer.stop(false)
	if "enable_input" in _new_node:
		_new_node.enable_input = true
	get_tree().set_current_scene(_new_node)
	dp("Root - all done!")
	#get_tree().paused = false

## Resets the entire scene tree
func reset_scene():
	dp("reset_scene, %s" % str(scene_stack))
	change_scene("MainMenuRoot")

func back_scene():
	dp("back_scene(), %s" % [scene_stack])
	var leaving_name = scene_stack.pop_back()
	if leaving_name == null:
		change_scene("MainMenuRoot")
		return
	get_tree().get_root().get_node(leaving_name).queue_free()
	var entering_name = scene_stack.pop_back()
	if entering_name:
		change_scene(entering_name)
	else:
		dp("Scene stack is empty! " + str(scene_stack))
		change_scene("MainMenuRoot")

func restart_scene():
	dp("Root - restart_scene()")
	if scene_stack:
		change_scene("_blank")
	else:
		var name_ = get_tree().get_root().get_child(1).name
		back_scene()
		change_scene(name_)

func preload_scene(name_: String):
	if preloaded_scene_name == name_:
		return
	if is_instance_valid(preloaded_scene):
		preloaded_scene.queue_free()
	preloaded_scene_name = name_
# warning-ignore:unsafe_method_access
	preloaded_scene = load("res://%s.tscn" % name_).instance()

func change_scene_preloaded():
	if preloaded_scene:
		get_tree().get_current_scene().queue_free()
		get_tree().get_root().add_child(preloaded_scene)
		get_tree().set_current_scene(preloaded_scene)
		scene_stack.push_back(preloaded_scene_name)
		dp("Changed scene to preloaded scene %s" % preloaded_scene_name)
		preloaded_scene_name = ""

# Gets the value of a configuration, if it exists.
func get_config(section: String, name_: String, default = null):
	return config.get_value(section, name_,
		default if default != null else SYSCON.config_defaults[section][name_]
	)

# Sets the value of a configuration.
func set_config(section: String, name_: String, value):
	return config.set_value(section, name_, value)

# Gets whether a value exists in the configuration file.
func has_config(section: String, name_: String) -> bool:
	return config.has_section_key(section, name_)

func reset_settings():
	for section in config.get_sections():
		for name_ in config.get_section_keys(section):
			config.set_value(section, name_,
			SYSCON.config_defaults[section][name_]
		)

# Preloads a sound effect that's expected to play soon.
# Sound effects will fire without this, but it's recommended
# to use this beforehand to prevent loading lag.
func preload_sfx(name_: String, pool_size: int = 1):
	sound_handler.load_sfx(name_, pool_size)

# Requests the sound handler to play a sound effect.
# Optionally, you can set the pitch of the sound effect.
# (e.g. used for sliders in the setting screen)
func request_sfx(name_: String, pitch = 1.0):
	sound_handler.play_sfx(name_, pitch)

func request_sfx_random(name_: String, pitch_min = 0.9, pitch_max = 1.1):
	sound_handler.play_sfx(name_, rng.randf_range(pitch_min, pitch_max))

# Requests the sound handler to play a sound effect,
# clipped to the duration of `duration` times the total length.
func request_sfx_length(name_: String, duration = 1.0):
	if duration >= 1.0:
		sound_handler.play_sfx(name_)
	else:
		sound_handler.play_sfx(name_, 1, duration)

# Requests the sound handler to play music.
# Music is not preloaded (so far), because they change
# at scene boundaries anyway.
func request_bgm(name_: String, restart_if_playing: bool = false):
	sound_handler.play_bgm(name_, restart_if_playing)

# Requests the sound handler to stop the currently playing music.
func request_bgm_stop():
	sound_handler.stop_bgm()

func pause_bgm(paused: bool):
	sound_handler.pause_bgm(paused)

# Requests the sound handler to change the volume of the music.
func set_vol_bgm(vol):
	sound_handler.set_vol_bgm(vol)

# Requests the sound handler to change the volume of
# all following sound effects.
func set_vol_sfx(vol):
	sound_handler.set_vol_sfx(vol)

# Requests the sound handler to unload music that is not expected to play any time soon.
func unload_bgm(name_: String):
	sound_handler.unload_bgm(name_)

# Requests the sound handler to unload sound effects
# that are not expected to play any time soon.
func unload_sfx(name_: String):
	sound_handler.unload_sfx(name_)

func apply_font(size: int):
	dp("apply_font " + str(size))
	var font_regular:DynamicFont = load(SYSCON.font_root + "SWAP_12_Regular.tres")
	var font_bold:DynamicFont = load(SYSCON.font_root + "SWAP_12_Bold.tres")
	var font_small:DynamicFont = load(SYSCON.font_root + "SWAP_10_Regular.tres")
	var font_piece:DynamicFont = load(SYSCON.font_root + "SWAP_Piece.tres")
	if size:
		# accessible font
		var multiplier = pow(2, (size - 1) * 0.05)
		dp("font multiplier is " + str(multiplier))
		font_regular = fb_regular
		font_bold    = fb_bold
		font_small   = fb_small
		font_piece   = fb_piece
		font_regular.set_size(20 * multiplier)
		font_bold.set_size(20 * multiplier)
		font_small.set_size(16 * multiplier)
		font_piece.set_size(12 * multiplier)
	else:
		# default font
		dp("default font set")
		font_regular = px_regular
		font_bold    = px_bold
		font_small   = px_small
		font_piece   = px_piece
	font_regular.update_changes()
	font_bold.update_changes()
	font_small.update_changes()
	font_piece.update_changes()
	
	var menu_theme = load("res://menuTheme.tres")
	menu_theme.set_default_font(font_regular)
	#ResourceSaver.save("res://menuTheme.tres", menu_theme)
	var other_theme = load("res://tiles/PopupMenuTheme.tres")
	other_theme.set_default_font(font_regular)
	#ResourceSaver.save("res://tiles/PopupMenuTheme.tres", other_theme)
	return [font_regular, font_bold, font_small, font_piece]

func load_inputs():
	dp("Loading keybinds...")
	var file := File.new()
	if file.open("user://keyconfig.json", File.READ) != OK:
		printerr("Could not open settings.json for loading")
		return
	var jsonstr := file.get_as_text()
	file.close()

	if not jsonstr:
		printerr("Keybind JSON could not be loaded!")
		return

	var json_res := JSON.parse(jsonstr)
	if json_res.error:
		printerr("Failed to parse keybind settings: " + json_res.error_string)

	var data = json_res.get_result()
	assert(typeof(data) == TYPE_DICTIONARY)
	dp("Loaded Keybind JSON")
#	print(data)
	data = data.input
	var invert = config.get_value("config", "ab_inv", false)
	var down_button = InputEventJoypadButton.new()
	var right_button = InputEventJoypadButton.new()
	down_button.button_index = JOY_XBOX_A
	right_button.button_index = JOY_XBOX_B
	for action_name in input_actions:
		match action_name:
			"ui_accept":
				InputMap.action_erase_events("ui_accept")
				for key in [KEY_ENTER, KEY_KP_ENTER, KEY_SPACE]:
					var temp_event = InputEventKey.new()
					temp_event.set_scancode(key)
					InputMap.action_add_event("ui_accept", temp_event)
				if invert:
					InputMap.action_add_event("ui_accept", right_button)
				else:
					InputMap.action_add_event("ui_accept", down_button)
			"ui_cancel":
				InputMap.action_erase_events("ui_cancel")
				for key in [KEY_BACKSPACE, KEY_ESCAPE, KEY_DELETE]:
					var temp_event = InputEventKey.new()
					temp_event.set_scancode(key)
					InputMap.action_add_event("ui_cancel", temp_event)
				if invert:
					InputMap.action_add_event("ui_cancel", down_button)
				else:
					InputMap.action_add_event("ui_cancel", right_button)
			_:
				if not data.has(action_name):
					dp("Input map for the action %s is blank." % action_name)
					continue
				dp("Input map for the action %s is:" % action_name)
# warning-ignore:unsafe_cast
				var item = data[action_name] as Dictionary
				dp(str(item))
				var list = [null, null, null]
				if item.has("key"):
					var keycode = item["key"]
					if typeof(keycode) == TYPE_REAL:
						list[0] = InputEventKey.new()
						list[0].scancode = keycode
				if item.has("button"):
					var button_index = item["button"]
					if typeof(button_index) == TYPE_REAL:
						list[1] = InputEventJoypadButton.new()
						list[1].button_index = button_index
				if item.has("axis") and item.has("axis_dir"):
					var axis_id = item["axis"]
					var axis_dir = item["axis_dir"]
					if typeof(axis_id) == TYPE_REAL and typeof(axis_dir) == TYPE_REAL:
						list[2] = InputEventJoypadMotion.new()
						list[2].axis = axis_id
						list[2].axis_value = 1 if axis_dir > 0 else -1
				InputMap.action_erase_events(action_name)
				if list[0]:
				#	print("Adding key event... ", list[0].scancode)
					InputMap.action_add_event(action_name, list[0])
				if list[1]:
				#	print("Adding button event... ", list[1].button_index)
					InputMap.action_add_event(action_name, list[1])
				if list[2]:
				#	print("Adding axis event... ", ("-" if list[2].axis_value < 0 else "+"), list[2].axis)
					InputMap.action_add_event(action_name, list[2])

func save_inputs():
	var data = {}
	for action in input_actions:
		var list = InputMap.get_action_list(action)
		var item = {}
		for bind in list:
			if bind is InputEventKey:
				item["key"] = bind.scancode
			elif bind is InputEventJoypadButton:
				item["button"] = bind.button_index
			elif bind is InputEventJoypadMotion:
				item["axis"] = bind.axis
				item["axis_dir"] = 1 if bind.axis_value > 0 else -1
		data[action] = item
		config.set_value("config", action, item)
	dp(data)

	var file := File.new()
	if file.open("user://keyconfig.json", File.WRITE) != OK:
		dp("Error opening keyconfig.json for save")
		return

	var jsonstr := JSON.print({
		"input": data,
	}, "  ")

	file.store_string(jsonstr)
	file.close()

func focus_neighbor(node: Control, index: int):
	dp("Focusing neighbor " + str(index) + " of node " + str(node))
	var path
	match index:
		0:
			path = node.focus_neighbour_top
		1:
			path = node.focus_neighbour_right
		2:
			path = node.focus_neighbour_bottom
		3:
			path = node.focus_neighbour_left
	if path:
		dp("Got path: " + str(path))
		Root.request_sfx("cursor")
		(node.get_node(path) as Control).grab_focus()
	else:
		dp("Got no path")

func text_to_utf16_bytes(text: String, little_endian: bool = false) -> PoolByteArray:
	var output = PoolByteArray()
	# Test if C++'s wchar_t() returns 16 or 32 bits on this platform.
	# Generates a string containing the character U+1F489 PILE OF POO,
	# which should return 0x0001F489 on platforms that return 32 bits,
	# but 0xD83D on platforms that return 16 bits.
	var is_32_bit: bool
	var test_char_code = PoolByteArray([0xF0, 0x9F, 0x92, 0xA9]).get_string_from_utf8().ord_at(0)
	match test_char_code:
		0x0001F489:
			dp("GlobalScripts.text_to_utf16_bytes: Char codes are 32 bits.")
			is_32_bit = true
		0xD83D:
			dp("GlobalScripts.text_to_utf16_bytes: Char codes are 16 bits.")
			is_32_bit = false
			is_32_bit = true
	while len(text) > 0:
		var char_code = text.ord_at(0)
		dp("Char code is %02x" % char_code)
		text = text.substr(1)
		if !is_32_bit or char_code <= 0xFFFF:
			# Direct mapping
			if little_endian:
				output.push_back(255 &  char_code)
				output.push_back(255 & (char_code >> 8))
			else:
				output.push_back(255 & (char_code >> 8))
				output.push_back(255 &  char_code)
		else:
			# From codepoint to UTF-16 surrogate pair
			char_code -= 0x10000
			var lo = 0xD800 + 0x04FF & (char_code >> 10)
			var hi = 0xDC00 + 0x04FF & (char_code)
			if little_endian:
				output.push_back(255 &  lo)
				output.push_back(255 & (lo >> 8))
				output.push_back(255 &  hi)
				output.push_back(255 & (hi >> 8))
			else:
				output.push_back(255 & (lo >> 8))
				output.push_back(255 &  lo)
				output.push_back(255 & (hi >> 8))
				output.push_back(255 &  hi)
	return output

func level_data_to_bytes(lv_dat: Dictionary) -> PoolByteArray:
#	# Necessary fields for ver 0:
#	name_16: PoolByteArray,
#	auth_16: PoolByteArray,
#	mission: PoolByteArray,
#	next: Array,
#	field: Array,
#	level: int,
#	ver: int,
#	# Necessary fields for ver 1:
#	solution: Array,
#	seed: int
	if (!lv_dat.has("ver")):
		printerr("Does not have necessary key: %s" % "ver")
		return PoolByteArray()
	
	var necessary_keys: Array
	match lv_dat.ver:
		"0":
			necessary_keys = ["name_16", "auth_16", "mission", "next", "field", "level", "ver"]
		"1":
			necessary_keys = ["name_16", "auth_16", "mission", "next", "field", "level", "ver", "solved", "solution", "seed"]
		_:
			printerr("Unrecognized ver code: %s" % lv_dat.ver)
			return PoolByteArray()
	
	for key in necessary_keys:
		if (!lv_dat.has(key)):
			printerr("Does not have necessary key: %s" % key)
			return PoolByteArray()
	
	dp("Root - Level data to bytes\nMission: " + str(Array(lv_dat.mission)))
	var sig = "MB" + lv_dat.ver
	var output = PoolByteArray([
		sig.ord_at(0),
		sig.ord_at(1),
		sig.ord_at(2)
	])
	# The following portion will switch to 6 bits per word.
	# First, store the values in this intermediate array.
	var items = PoolByteArray()
	# Encode difficulty level
	items.push_back(lv_dat.level & 0x3F)
	dp("Difficulty level\n%s" % rep_oct(items))
	# Encode playfield
	# Trim trailing blank rows
	while true:
		var last = lv_dat.field.back()
		if last == [0, 0, 0, 0, 0, 0, 0]:
			lv_dat.field.pop_back()
		else:
			break
	# If the whole field is blank, just write an "end field data" word
	if len(lv_dat.field) == 0:
		items.push_back(15)
	else:
		for row in range(0, len(lv_dat.field)):
			# Trim trailing blank grid-spaces
			while lv_dat.field[row].back() == 0:
				lv_dat.field[row].pop_back()
			# Add each grid-space in the row
			for column in range(0, len(lv_dat.field[row])):
				items.push_back(lv_dat.field[row][column])
			# Add line ender
			# Is this the last row?
			if row + 1 == len(lv_dat.field):
				items.push_back(15)
			elif len(lv_dat.field[row]) < COLUMNS:
				items.push_back(14)
			# If the row is already all 7 grid-spaces long, just do nothing,
			# and let the parser move onto the next row on its own.
	dp("Playfield\n%s" % rep_oct(items))
	# Encode NEXT queue
	if len(lv_dat.next):
		for domino in lv_dat.next:
			var domino_value = domino.id_0
			match domino_value:
				0:
					items.push_back(0)
				6:
					items.push_back(1)
					items.push_back(domino.id_1)
				7:
					items.push_back(2)
					items.push_back(domino.id_1)
				_:
					items.push_back((domino.id_0 << 3) + domino.id_1)
	else:
		printerr("NEXT queue is empty!")
		return PoolByteArray()
	dp("NEXT\n%s" % rep_oct(items))
	# solution (Version 1)
	if lv_dat.ver == "1":
		var solution_terminate = (7 << 6) | (0 << 2) | 0
		if lv_dat.solved:
			var solution_ended: bool = false
			var temp: int = 0
			while len(lv_dat.solution):
				var move = lv_dat.solution.pop_front()
				# XXXYYYYRR - each solution move
				# XXXYYY YRRXXX YYYYRR - packed pair of solutions
				# XXXYYY YRR000 - end if odd number of moves
				temp = (move.x << 6) | (move.y << 2) | move.rot
				temp = temp << 9
				if len(lv_dat.solution):
					move = lv_dat.solution.pop_front()
					temp |= (move.x << 6) | (move.y << 2) | move.rot
				else:
					solution_ended = true
					temp |= solution_terminate
				items.push_back((temp >> 12) & 63)
				items.push_back((temp >> 6) & 63)
				items.push_back((temp) & 63)
			if !solution_ended:
				temp = solution_terminate
				items.push_back((temp >> 3) & 63)
				items.push_back((temp << 3) & 63)
		else:
			var temp = solution_terminate + 1
			items.push_back((temp >> 3) & 63)
			items.push_back((temp << 3) & 63)
	# Now, pad the array of 6-bit words into an array of bytes.
	# Find how many padding bits we will need.
	var size_needed = len(items) * 6
	var modulo_bits = size_needed % 8
	# Work in 24-bit units, since the LCM of 6 and 8 is 24.
	# Iterate through groups of 4 * 6 bits,
	# and regroup them into groups of 3 * 8 bits.
	var i = 0
	while i < len(items):
		# Make a 24-bit-at-least integer to store all 24 bits.
		# Godot uses 64-bit integers.
		var temp_bits  = items[i    ] << 18
		if i + 1 < len(items):
			temp_bits ^= items[i + 1] << 12
		if i + 2 < len(items):
			temp_bits ^= items[i + 2] <<  6
		if i + 3 < len(items):
			temp_bits ^= items[i + 3]
		i += 4
		#print("%o" % temp_bits, " == %X - Temp bits" % temp_bits)
		# Append that integer in 8-bit units.
		output.append(temp_bits >> 16 & 255)
		output.append(temp_bits >>  8 & 255)
		output.append(temp_bits       & 255)
		#print("%s - Hex items" % rep_hex(output.subarray(i / 4 * 3, i - 4 * 3 + 3)))
	# We may have just added some unnecessary null bytes at the end.
	# Figure out how many bytes we need to remove, depending on
	# how many padding bits we needed to add.
	match modulo_bits:
		0:
			# 0 modulo_bits: AAAAAABB BBBBCCCC CCDDDDDD
			# don't remove any bytes
			pass
		2:
			# 2 modulo_bits: AAAAAABB BBBBCCCC CC000000
			# don't remove any bytes
			pass
		4:
			# 4 modulo_bits: AAAAAABB BBBB0000 00000000
			# remove 1 byte
			output.remove(len(output) - 1)
		6:
			# 6 modulo_bits: AAAAAA00 00000000 00000000
			# remove 2 bytes
			output.remove(len(output) - 1)
			output.remove(len(output) - 1)
	dp("Base64 so far: \n%s" % octal_to_base64(items))
	dp("Converted to hexadecimal: \n%s" % rep_hex(output))
	# The following sections are 8 bits per word.
	# Directly manipulate the PoolByteArray.
	
	# Encode RNG seed
	if lv_dat.ver == "1":
		dp("Seed: %d\n" % lv_dat.seed)
		output.append((lv_dat.seed >> 24) & 0xFF)
		output.append((lv_dat.seed >> 16) & 0xFF)
		output.append((lv_dat.seed >>  8) & 0xFF)
		output.append((lv_dat.seed      ) & 0xFF)
	
	# Encode mission
	output.append_array(PoolByteArray(lv_dat.mission))
	
	dp("Mission\n%s" % rep_hex(output))
	
	# Encode name
	var max_name_length_in_bytes = 128
# warning-ignore:integer_division
	var name_length = len(lv_dat.name_16) / 2
	if name_length > max_name_length_in_bytes / 2:
		lv_dat.name_16.resize(max_name_length_in_bytes)
	elif 0 == len(lv_dat.name_16):
		lv_dat.name_16 = PoolByteArray([0x00, 0x20])
		name_length = 1
	output.append(name_length - 1)
	output.append_array(lv_dat.name_16)
	dp("Name\n%s" % rep_hex(output))
	# Encode author
# warning-ignore:integer_division
	var author_length = len(lv_dat.auth_16) / 2
	if author_length > max_name_length_in_bytes / 2:
		lv_dat.auth_16.resize(max_name_length_in_bytes)
	elif 0 == len(lv_dat.auth_16):
		lv_dat.auth_16 = PoolByteArray([0x00, 0x20])
		author_length = 1
	output.append(author_length - 1)
	output.append_array(lv_dat.auth_16)
	dp("Author\n%s" % rep_hex(output))
	
	# Finally, calculate checksum and complement
	var sum = 0
	for byte in output:
		sum = (sum + byte) & 0xFF
	output.append(sum)
	output.append((~sum + 1) & 0xFF)
	dp("Encode complete!\n%s" % rep_hex(output))
	assert(output[0] == "M".ord_at(0))
	assert(output[1] == "B".ord_at(0))
	assert(output[2] == lv_dat.ver.ord_at(0))
	return output

func bytes_to_level_data(data: PoolByteArray) -> Dictionary:
	var out = {
		"result": "NULL",
		"ver": "",
		"name": "",
		"auth": "",
		"mission": [],
		"next": [],
		"field": [[]],
		"level": 0,
		"solved": false,
		"solution": [],
		"seed": 0
	}
	if len(data) < 3:
		printerr("Data not long enough.")
		out.result = "ERR_TOO_SHORT"
		return out
	dp("Signature is %c%c%c" % [data[0], data[1], data[2]])
	if data[0] == 0x4D and data[1] == 0x42:
		dp("Signature found.")
		out.ver = char(data[2])
	else:
		printerr("Signature not found.")
		out.result = "ERR_SIGNATURE"
		return out
	# checksum
	var sum = 0
	for byte in data:
		sum = (sum + byte) & 255
	if sum != data[len(data) - 2]:
		printerr("Checksum %02X did not match the sum %02X." % [data[len(data) - 2], sum])
		out.result = "ERR_CHECKSUM"
		return out
	# discard signature (we'll discard the checksum later)
	data = data.subarray(3, -1)
	# first make a copy that's all octal bytes
	var octal_data = PoolByteArray()
	var i = 0
# for some reason godot thinks i'm not using the variable 'padding'
# when i'm clearly using it in the while loop after it
# warning-ignore:unused_variable
	var padding = 0
	while i < len(data):
		var bytes_to_encode = min(3, len(data) - i)
		var bitstring = data[i] << 16
		if i+1 < len(data):
			bitstring ^= data[i+1] << 8
		if i+2 < len(data):
			bitstring ^= data[i+2]
		#print("Bitstring = %06X = %08o" % [bitstring, bitstring])
		for j in range(1 + bytes_to_encode):
			var value = bitstring >> (6 * (3 - j)) & 0x3F
			octal_data.push_back(value)
		for _j in range(3 - bytes_to_encode):
			padding += 1
		i += 3
	i = 0
	# decode speed level
	out.level = octal_data[i]
	# decode playfield
	out.field = []
	var break_out = false
	i = 1
	while !break_out:
		for row in range(0, ROWS):
			# add new row
			out.field.append([0, 0, 0, 0, 0, 0, 0])
			# populate new row
			for column in range(0, COLUMNS):
				if octal_data[i] == 0x0E:
					# to next row
					pass
					i += 1
					break
				elif octal_data[i] == 0x0F:
					# end playfield
					break_out = true
					i += 1
					break
				elif octal_data[i] >= 0x16 and octal_data[i] & 0x07 == 0x06:
					var addition = (octal_data[i] >> 3) - 1
					dp("Add 7 HP to next piece (not implemented yet)")
					# and load following piece
					i += 1
					out.field[row][column] = octal_data[i] + (56 * addition)
				else:
					# normal piece
					out.field[row][column] = octal_data[i]
				i += 1
				column += 1
			dp("Root - read row: " + str(out.field[row]) + " (from data)")
			if break_out:
				break
	while len(out.field) < ROWS:
		out.field.append([0, 0, 0, 0, 0, 0, 0])
		dp("Root - read row: " + str(out.field.back()) + " (padding)")
	dp("Root - That's all she wrote!")
	# decode next
	out.next = []
	while true:
		var next_piece = Next.new()
		if octal_data[i] == 0x00:
			# end queue
			next_piece.id_0 = 0
			next_piece.id_1 = 0
			out.next.push_back(next_piece)
			dp("Root - Last next piece: Game over")
			break
		elif octal_data[i] == 0x02:
			# generate random
			next_piece.id_0 = 7
			i += 1
			next_piece.id_1 = octal_data[i]
			out.next.push_back(next_piece)
			dp("Root - Last next piece: Generate randomly: %x" % next_piece.id_1)
			break
		elif octal_data[i] >= 0x60:
			# loop to index
			next_piece.id_0 = 6
			i += 1
			next_piece.id_1 = (octal_data[i-1] & 15) << 6 ^ octal_data[i]
			out.next.push_back(next_piece)
			dp("Root - Last next piece: Loop to %d" % next_piece.id_1)
			break
		else:
			# normal domino
			next_piece.id_0 = (octal_data[i] >> 3) & 7
			next_piece.id_1 = octal_data[i] & 7
			out.next.push_back(next_piece)
			i += 1
			dp("Root - New next piece: " + str(next_piece.id_0) + "|" + str(next_piece.id_1))
	i += 1
	var i_temp = i
	# solution (version 1)
	if out.ver == "1":
		dp("%02d" % i + " Decoding solution")
		var steps_of_solution: int = 0
		var done_with_solution: bool = false
		while !done_with_solution:
			var byte_0 = octal_data[i]
			var byte_1 = octal_data[i + 1] if i + 1 < len(octal_data) else 0
			var byte_2 = octal_data[i + 2] if i + 2 < len(octal_data) else 0
			var temp_bits = (
				(byte_0 << 12) |
				(byte_1 << 6) |
				(byte_2)
			)
			for bits_2_shift in [9, 0]:
				# move the index along as we go
				if bits_2_shift == 9:
					i += 2
				else:
					i += 1
				# extract bits
				var this_move_bits = temp_bits >> bits_2_shift & 0x1FF
				var this_move = {}
				this_move.x = this_move_bits >> 6 & 0x7
				this_move.y = this_move_bits >> 2 & 0xF
				this_move.rot = this_move_bits & 0x3
				dp("%02d" % i + " Solution step: x{x} y{y} rot{rot}".format(this_move))
				steps_of_solution += 1
				out.solution.push_back(this_move)
				if this_move.x == 7:
					if this_move.y == 0 and this_move.rot == 0:
						done_with_solution = true
						out.solved = true
					elif this_move.y == 0 and this_move.rot == 1:
						done_with_solution = true
						out.solved = false
				if done_with_solution:
					break
		# Should not be overread, but just in case,
		# Align the index to the real size of the solutions
		i = i_temp + ceil(1.5 * steps_of_solution)
		dp("%02d" % i)
	# go back to hex bytes
	var pointer_in_bits = i * 6
	dp("Used up %d 6-bit words. That's %d bits or %f bytes." % [i, pointer_in_bits, pointer_in_bits / 8.0])
	i = ceil(pointer_in_bits / 8.0)
	
	# rng seed (version 1)
	if out.ver == "1":
		out.seed = (
			data[i] << 24 |
			data[i + 1] << 16 |
			data[i + 2] << 8 |
			data[i + 3]
		)
		i += 4
	
	# decode mission
	out.mission = []
	out.mission.append(data[i])
	dp("Mission is %02x" % out.mission[0])
	var param_bytes: int
	if data[i] == 0x01:
		param_bytes = 2
	elif (data[i] <= 0x05 or
		(data[i] <= 0x20 and data[i] < 0x40)):
		param_bytes = 0
	elif data[i] == 0x06:
		param_bytes = 4
	elif (0x41 <= data[i] and data[i] <= 0x7F)\
	  or (0x81 <= data[i] and data[i] <= 0xBF):
		param_bytes = 1
	else:
		printerr("Unrecognized mission! %02x" % data[i])
	i += 1
	for j in range(param_bytes):
		dp("%d of %d mission data bytes: %02x" % [j, param_bytes, data[i]])
		out.mission.push_back(data[i])
		i += 1
	# decode title
	var title_length = data[i] + 1
	out.name = ""
	dp("Title length is %d + 1" % data[i])
	i += 1
	while title_length > 0:
		out.name += char((data[i] * 256) ^ data[i+1])
		i += 2
		title_length -= 1
	# decode author
	var author_length = data[i] + 1
	out.auth = ""
	dp("Author length is %d + 1" % data[i])
	i += 1
	while author_length > 0:
		out.auth += char((data[i] * 256) ^ data[i+1])
		i += 2
		author_length -= 1
	# checksum at the end
	# finished!
	out.result = "SUCCESS"
	return out

func rep_hex(data: PoolByteArray) -> String:
	var out = ""
	for x in data:
		out += "%02X " % x
	return out

func rep_oct(data: PoolByteArray) -> String:
	var out = ""
	for x in data:
		out += "%02o " % x
	return out

const b64 = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789-_"
const b64_redirects = {
	"+": 62,
	"/": 63,
	"-": 62,
	"_": 63,
	",": 63
}

func octal_to_base64(data: PoolByteArray) -> String:
	var out = ""
	var i = 0
	while i < len(data):
		out += b64.substr(data[i], 1)
		i += 1
	var remainder = posmod(4, -i)
	out += "=".repeat(remainder)
	return out

func base64(data: PoolByteArray) -> String:
	var out = ""
	var i = 0
	while i < len(data):
		var bytes_to_encode = min(3, len(data) - i)
		var bitstring = data[i] << 16
		if i+1 < len(data):
			bitstring ^= data[i+1] << 8
		if i+2 < len(data):
			bitstring ^= data[i+2]
		#print("Encode Base64 - Bitstring = %06X = %08o" % [bitstring, bitstring])
		for j in range(1 + bytes_to_encode):
			var value = bitstring >> (6 * (3 - j)) & 0x3F
			#print("Value %02o = %s" % [value, b64.substr(value, 1)])
			out += b64.substr(value, 1)
		for _j in range(3 - bytes_to_encode):
			out += "="
		i += 3
	return out

func base64_value(char_: String):
	if char_ in b64:
		return b64.find(char_);
	elif b64_redirects.has(char_):
		return b64_redirects[char_]
	else:
		return 0

func decode_base64(data: String) -> PoolByteArray:
	var out = PoolByteArray()
	var i = 0
	if data.ends_with("="):
		data.erase(data.find("="), 2)
	while i < len(data):
		#print("Decoding Base64 section")
		var bytes_to_decode = min(4, len(data) - i)
		var bitstring = base64_value(data[i]) << 18
		#print(data[i], " : ", b64.find(data[i]))
		if bytes_to_decode > 1:
			bitstring ^= base64_value(data[i+1]) << 12
			#print(data[i+1], " : ", base64_value(data[i+1]))
		if bytes_to_decode > 2:
			bitstring ^= base64_value(data[i+2]) << 6
			#print(data[i+2], " : ", base64_value(data[i+2]))
		if bytes_to_decode > 3:
			bitstring ^= base64_value(data[i+3])
			#print(data[i+3], " : ", base64_value(data[i+3]))
		#print("Bitstring = %06X = %08o" % [bitstring, bitstring])
		for j in range(bytes_to_decode - 1):
			var value = bitstring >> (8 * (2 - j))
			#print("Value %02X" % value)
			out.push_back(value & 255)
		i += 4
	return out

enum ERR_TYPE {
	INFO,
	WARN,
	ERROR
}

func show_error(message: String):
	show_message(message, 1)

func show_message(message: String, type: int = 0):
	match type:
		0:
			$ErrorLayer/AcceptDialog/VBoxContainer/icon.texture = icon_info
		1:
			$ErrorLayer/AcceptDialog/VBoxContainer/icon.texture = icon_warn
		2:
			$ErrorLayer/AcceptDialog/VBoxContainer/icon.texture = icon_error
	($ErrorLayer/AcceptDialog/VBoxContainer/content as Label).set_text(message)
	($ErrorLayer/AcceptDialog as Popup).popup_exclusive = true
	($ErrorLayer/AcceptDialog as Popup).popup()
	get_tree().paused = true

func show_confirm(message: String, type, connect_to: Node = null, method_name: String = "_on_dialog_result", id: String = "default"):
	match type:
		0:
			$ErrorLayer/ConfirmDialog/VBoxContainer/icon.texture = icon_info
		2:
			$ErrorLayer/ConfirmDialog/VBoxContainer/icon.texture = icon_error
		1, _:
			$ErrorLayer/ConfirmDialog/VBoxContainer/icon.texture = icon_warn
	($ErrorLayer/ConfirmDialog/VBoxContainer/content as Label).set_text(message)
	($ErrorLayer/ConfirmDialog as Popup).popup_exclusive = true
	($ErrorLayer/ConfirmDialog as Popup).popup()
	if is_instance_valid(connect_to):
		self.connect("dialog_result", connect_to, method_name, [id], CONNECT_ONESHOT & CONNECT_DEFERRED)
	else:
		dp("Root.tscn: Can't connect to dialog callback.")
	get_tree().paused = true

func _on_AcceptDialog_confirmed():
	get_tree().paused = false
	($ErrorLayer/AcceptDialog as Control).hide()

func byte_array_repeat(what_to_repeat: int, how_many_times: int) -> PoolByteArray:
	var array = PoolByteArray()
	for i in range(0, how_many_times):
		array.push_back(what_to_repeat)
	return array
	
func byte_array_shuffle(array: PoolByteArray, rng_to_use: RandomNumberGenerator) -> PoolByteArray:
	var out = PoolByteArray()
	for i in range(len(array)):
		var last = array.size() - 1
		out.insert(rng_to_use.randi_range(0, i), array[last])
		array.resize(last)
	return out

func byte_array_add(arrayA: PoolByteArray, arrayB: PoolByteArray) -> PoolByteArray:
	for i in range(len(arrayA)):
		arrayA[i] += arrayB[i]
	return arrayA

func save_game():
	var save_game = File.new()
	var err = save_game.open("user://savegame.save", File.WRITE)
	if err != OK:
		show_error("Could not save game due to an error while opening the file: %d" % err)
	save_game.store_string(to_json(save_dict))
	save_game.close()

func load_game():
	var save_game = File.new()
	if not save_game.file_exists("user://savegame.save"):
		return # Error! We don't have a save to load.
	var err = save_game.open("user://savegame.save", File.READ)
	if err != OK:
		show_error("Could not load game due to an error while opening the file: %d" % err)
		return
	dp("Save game loaded")
	dp(save_game.get_as_text())
	var json_parse_result = JSON.parse(save_game.get_as_text())
	if json_parse_result.get_error() != OK:
		show_error("Could not load game due to an error while parsing JSON: %s" % json_parse_result.get_error_string())
		return
	save_dict = json_parse_result.get_result()
	save_game.close()

func reset_game():
	save_dict = save_dict_backup
	save_game()

func _on_ConfirmDialog_confirmed():
	get_tree().paused = false
	($ErrorLayer/ConfirmDialog as Control).hide()
	self.emit_signal("dialog_result", true)

func _on_ConfirmDialog_cancelled():
	get_tree().paused = false
	($ErrorLayer/ConfirmDialog as Control).hide()
	self.emit_signal("dialog_result", false)

func load_levels(world: String) -> Array:
	var path = "res://story/levels/%s.json" % world
	var level_data = File.new()
	if not level_data.file_exists(path):
		return [] # Error! We don't have a save to load.
	var err = level_data.open(path, File.READ)
	if err != OK:
		show_error("Could not load world %s's levels due to an error while opening the file: %d" % [world, err])
		return []
	var json_parse_result = JSON.parse(level_data.get_as_text())
	if json_parse_result.get_error() != OK:
		show_error("Could not load world %s due to an error while parsing JSON: Line %d Error %d %s" % [world, json_parse_result.get_error_line(), json_parse_result.get_error(), json_parse_result.get_error_string()])
		return []
	var levels = json_parse_result.get_result()
	level_data.close()
	# overwrite decoded level data
	if err != OK:
		show_error("Could not save game due to an error while opening the file: %d" % err)
		return []
	var edited: bool = false
	for i in range(len(levels)):
		if !levels[i].has("data"):
			edited = true
			dp("decoding data:" + levels[i].base64)
			var this_data = bytes_to_level_data(decode_base64(levels[i].base64))
			levels[i].data = this_data
		else:
			dp("got data:" + (levels[i].data.name))
		for key in levels[i].data.keys():
			if typeof(levels[i].data[key]) == TYPE_REAL:
				levels[i].data[key] = int(levels[i].data[key])
			elif typeof(levels[i].data[key]) == TYPE_ARRAY:
				if typeof(levels[i].data[key][0]) == TYPE_REAL:
					levels[i].data[key] = PoolIntArray(levels[i].data[key])
				elif typeof(levels[i].data[key][0]) == TYPE_ARRAY:
					if typeof(levels[i].data[key][0][0]) == TYPE_REAL:
						for j in range(len(levels[i].data[key])):
							levels[i].data[key][j] = PoolIntArray(levels[i].data[key][j])
	if edited:
		var level_data_edit = File.new()
		err = level_data_edit.open(path, File.READ_WRITE)
		level_data_edit.store_string(to_json(levels))
		level_data_edit.close()
	return levels

func dp(content: String):
	if DEBUG:
		print(content)

func add_log(content: String):
	$LogLayer.show_log(content)
