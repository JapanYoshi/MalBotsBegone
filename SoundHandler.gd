extends Node

# The sound handler.
var debug: bool = false

# The AudioStreamPlayers that play music.
# Type: Dictionary of AudioStreamPlayer
var bgm_nodes = {}
# The objects containing AudioStreamPlayers that play sound effects.
# Type: Dictionary of Dictionary (below)
# Under the key of the SFX, each item has this structure:
# {
#   nodes = [...],
#		- Contains the pool of AudioStreamPlayers, with the following children:
#			0: Timer. It is rigged to stop the SFX when the time is up.
#			1: Node2D. Its position.x is the length of the stream in seconds.
#   index = 0
#		- The index of the last played node.
# }
var sfx_nodes = {}
var SFX_NODE = preload("res://SFXNode.tscn")
# The volume of music, out of max_vol.
var bgm_vol = 16
# The volume of sound effects, out of max_vol.
var sfx_vol = 16
# Maximum volume.
const max_vol = 16
# The key of the currently playing music.
var bgm_now

const bus_bgm = "bus_BGM"
const bus_sfx = "bus_SFX"

var bgm_pattern = "res://bgm/%s.ogg"
var sfx_pattern = "res://sfx/%s.wav"

# Called when the node enters the scene tree for the first time.
func _ready():
	name = "SoundHandler"
	AudioServer.set_bus_layout(load("res://bus_layout.tres"))
	
func load_bgm(key: String) -> AudioStreamPlayer:
	dp("Valid BGM keys are: ", Root.SYSCON.bgm_dictionary.keys())
	if bgm_nodes.has(key):
		return bgm_nodes[key]
	elif key in Root.SYSCON.bgm_dictionary.keys():
		dp("Loading BGM named \"", key , "\".")
		# load new bgm but don't play it
		var bgm = AudioStreamPlayer.new()
		bgm.name = "BGM_" + key
		bgm.stream = load(
			bgm_pattern % Root.SYSCON.bgm_dictionary[key]
		)
		dp("Stream: ", bgm.stream)
		bgm.set_bus(bus_bgm)
		dp("Bus: ", bgm.get_bus())
		bgm_nodes[key] = bgm
		dp("bgm_nodes[key]: ", bgm_nodes[key])
		add_child(bgm)
		return bgm
	else:
		printerr("ERROR: BGM key \"", key, "\", was not found!")
		return null

func unload_bgm(key: String) -> void:
	if bgm_nodes.has(key):
		bgm_nodes[key].queue_free()
		bgm_nodes.erase(key)

# Plays the music with the specified key.
# If it's already playing, keeps playing it.
func play_bgm(key: String, restart_if_playing: bool = false) -> void:
	dp("Priming to play BGM \"", key, "\"...")
	if bgm_now == key:
		dp("That BGM \"", key ,"\" is already playing.")
		if bgm_nodes[bgm_now].is_playing() and !restart_if_playing:
			return
		dp("Playing anyway.")
	else:
		if bgm_nodes.has(bgm_now):
			bgm_nodes[bgm_now].stop()
	
	var bgm = load_bgm(key)
	# Returns AudioStreamPlayer if key is an existing BGM key.
	if !bgm:
		printerr("BGM key \"", key, "\" failed to play. Are you sure that's the correct name?")
	else:
		dp("play_bgm() loaded this: ", bgm)
		bgm.stop()
		bgm.play()
	#	print(bgm_nodes[key].volume_db)
		bgm_now = key
		dp("BGM \"", key, "\" is starting to play.")

func pause_bgm(paused: bool = true):
	if bgm_now in bgm_nodes.keys():
		bgm_nodes[bgm_now].playing = !paused

# Stops the currently playing music.
func stop_bgm() -> void:
	if bgm_now in bgm_nodes.keys():
		bgm_nodes[bgm_now].stop()

# Preloads a sound effect to be played later.
# If the sound effect is going to be played multiple times quickly,
# then you can specify the pool size, which is the maximum times
# the sound effect can play simultaneously.
# Sure, sound effects will play even if they aren't preloaded,
# but it's wise to preload them to avoid loading lag spikes.
func load_sfx(key: String, pool_size: int = 1) -> Node:
	if key in Root.SYSCON.sfx_dictionary:
		if key in sfx_nodes:
			return sfx_nodes[key]
		else:
			var pool = {
				nodes = [],
				index = 0
			}
			for i in range(pool_size):
				var node = SFX_NODE.instance()
				node.name = "SFX_" + key + "_" + str(i)
				node.stream = load(
					sfx_pattern % Root.SYSCON.sfx_dictionary[key]
				)
				node.stream_length = node.stream.get_length()
				node.set_bus(bus_sfx)
				pool.nodes.append(node)
				self.add_child(node)
			sfx_nodes[key] = pool
			dp("Adding new node for SFX \"" + key + "\".")
			return pool
	else:
		printerr("Key \"" + key + "\" was not found.")
		return null

# Unloads sound effects that won't be played again any time soon.
func unload_sfx(key: String) -> void:
	if sfx_nodes.has(key):
		while len(sfx_nodes[key].nodes):
		#	print(sfx_nodes[key].nodes)
			sfx_nodes[key].nodes.pop_back().queue_free()
		sfx_nodes.erase(key)


# Plays a sound effect. If it isn't preloaded, loads that sound effect first.
func play_sfx(key: String, pitch = 1.0, duration = 1.0) -> void:
	dp("SoundHandler - Requested SFX: ", key, " at pitch ", pitch, " and duration ", duration)
	if key in Root.SYSCON.sfx_dictionary:
		var node
		node = load_sfx(key) # Guaranteed to return a sound effect pool...
		# ...unless the key isn't found.
		# Advance index in the sound effect pool
		var this_node = node.nodes[node.index]
		# Stop the node in case it's playing
		this_node.stop()
		# Set the pitch
		this_node.set_pitch_scale(pitch)
		# In case the last time it was fired with a timer,
		# stop that too
		var timer = this_node.get_child(0)
		timer.stop()
		if duration < 1.0:
			# Set the duration (Child 0 is timer)
			timer.set_wait_time(
				node.nodes[node.index].stream_length
				* duration
			)
			timer.start()
		this_node.play()
		node.index = (1 + node.index) % len(node.nodes)
		#print("Playing existing node for SFX \"" + key + "\".")
	else:
		printerr("Error: SFX key \"", key, "\" was not found.")

# Converts the abstract "volume" value to a relative decibel level
# that an audio bus will take.
func vol_to_db(vol: int) -> float:
	if vol == 0:
		return -INF
	return log(vol as float / max_vol) * 10

# Sets the volume for background music. If the background music is playing,
# it immediately changes its volume.
func set_vol_bgm(vol: int):
	if vol < 0:
		vol = max_vol
	bgm_vol = vol
	# set volume of the bus
	var bus_i = AudioServer.get_bus_index(bus_bgm)
	AudioServer.set_bus_volume_db(bus_i, vol_to_db(bgm_vol))
	dp("Bus ", bus_i, "'s volume is set to ", AudioServer.get_bus_volume_db(bus_i))

# Sets the volume for sound effects. Does nothing to currently playing
# sound effects.
func set_vol_sfx(vol: int):
	if vol < 0:
		vol = max_vol
	sfx_vol = vol
	# set volume of the bus
	var bus_i = AudioServer.get_bus_index(bus_sfx)
	AudioServer.set_bus_volume_db(bus_i, vol_to_db(sfx_vol))
	dp("Bus ", bus_i, "'s volume is set to ", AudioServer.get_bus_volume_db(bus_i))

func dp(arg0, arg1 = "", arg2 = "", arg3 = "", arg4 = "", arg5 = ""):
	if !debug: return
	print(arg0, arg1, arg2, arg3, arg4, arg5)
