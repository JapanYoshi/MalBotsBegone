extends Control

# This script detects which platform (by which I REALLY mean input device)
# this game is running on,
# by checking what kind of InputEvent it receives.
# (e.g. if it receives an InputEventScreenTouch,
# it assumes it's running on a smartphone)
# * 0 = Smartphone (touchscreen)
# * 1 = Computer (kb/mouse)
# * 2 = Console (gamepad)
var platform: int = -1
# But once we ask the first question, we don't want the platform to change,
# so lock the value using this flag
var detect_platform: bool = true
# This debounces the Dialogic input event so button mashing "feels better"
var just_pressed: float = 0
# Turns out Dialogic accepts input even when it's pausing on a timer,
# so prevent sending new input events by using this flag
var accept_input: bool = true
# Store the answers to the questions using this array
# (because Dialogic's glossary doesn't really play nice)
var answers: Array = []

var dialog_node

func _ready():
	$AnimationPlayer.play("fade_in")

func _input(event):
	#print(event.get_class())
	match str(event.get_class()):
		"InputEventScreenTouch":
			print("screen touched")
			if detect_platform:
				platform = 0
			_send_dialogic_event()
		"InputEventMouseButton":
			if event.is_pressed() and event.button_index == BUTTON_LEFT:
				print("mouse clicked")
				if platform != 0 and detect_platform:
					platform = 1
				_send_dialogic_event()
		"InputEventKey":
			if event.is_action_pressed("ui_accept") or event.is_action_pressed("ui_cancel"):
				if detect_platform:
					platform = 1
				print("key pressed")
				_send_dialogic_event()
			elif event.is_pressed() and event.scancode == KEY_END:
				_on_Skip_pressed()
		"InputEventJoypadButton":
			if event.is_action_pressed("ui_accept") or event.is_action_pressed("ui_cancel"):
				if detect_platform:
					platform = 2
				print("button pressed")
				_send_dialogic_event()
			elif event.is_pressed() and event.button_index == JOY_START:
				_on_Skip_pressed()

# Touch events should be handled using _input(), but if it doesn't,
# set the platform here
func _on_TouchScreenButton_pressed():
	if detect_platform:
		platform = 0
	_send_dialogic_event()

# In order to make the Dialogic node work with both ui_accept and ui_cancel
# we have a virtual action just called "dialogic".
# Send one of those here.
func _send_dialogic_event():
	if (!accept_input # don't send input events if we've paused input events
	or just_pressed > 0.0): # don't send input events right after sending one
		return
	var a = InputMap.get_action_list("dialogic")[0]
	a.pressed = true
	Input.parse_input_event(a)
	just_pressed = 0.1

# We also need to release the event once we've pressed it.
# We have a timer variable called `just_pressed`
# that counts down the time
func _process(delta):
	# Once the timer is negative, we can release the action.
	if just_pressed < 0.0:
		var a = InputMap.get_action_list("dialogic")[0]
		a.pressed = false
		Input.parse_input_event(a)
		print("released")
		just_pressed = 0.0
	# If it's positive, keep counting down until it's negative.
	elif just_pressed > 0.0:
		just_pressed -= delta
		# if the VERY unlikely scenario happens where we've decremented
		# `just_pressed` EXACTLY to 0.0, move it away
		if just_pressed == 0.0:
			just_pressed = -0.1
	# if it's equal to 0.0, don't do anything.

# Dialogic's only way to communicate with the rest of the game is via the
# `dialogic_signal` event.
# But fortunately that doesn't mean we can't communicate with the script.
# Branch using the `value` it passes to us.
func _on_DialogNode_dialogic_signal(value):
	match value:
		"navi_appear":
			# The navigator's intro animation should play.'
			print("Navi appear")
			accept_input = false
			$AnimationPlayer.play("navi_appear")
			$MainBox/ViewportContainer/TextureViewport/navi.spin(true, 4.9, 2.6, MARGIN_BOTTOM)
		"check_platform":
			# Dialogic wants to know what platform we're on.
			# Lock the variable and branch the script accordingly.
			detect_platform = false
			print("Platform is %s" % platform)
			var dialog_name = "firsttime_001"
			match platform:
				0:
					dialog_name += "A"
				1:
					dialog_name += "B"
				2:
					dialog_name += "C"
				_:
					dialog_name += "Z"
			_load_dialog(dialog_name)
		"answer_0":
			# I can't deal with Dialogic's Glossary function, so I just use signals.
			answers.push_back(0)
		"answer_1":
			# I can't deal with Dialogic's Glossary function, so I just use signals.
			answers.push_back(1)
		"end_setup":
			# That's all, folks!
			print("End setup")
			print("Platform: %s" % platform)
			print("Answers: %s" % str(answers))
			# Apply settings according to these answers.
			match platform:
				0:
					# Mobile: control type
					Root.set_config("ctrl", "type", 1 - answers[0])
				1:
					# Mouse/KB: Hard drop key
					var new_keycode = [KEY_SPACE, KEY_UP][answers[0]]
					var found_desired_action = false
					for event in InputMap.get_action_list("gp_hard"):
						if event is InputEventKey:
							if event.scancode != new_keycode:
								InputMap.action_erase_event("gp_hard", event)
							else:
								found_desired_action = true
					if !found_desired_action:
						var new_event = InputEventKey.new()
						new_event.scancode = new_keycode
						InputMap.action_add_event("gp_hard", new_event)
				2:
					# Gamepad: invert A/B
					Root.set_config("config", "ab_inv", answers[0] == 1)
			# The rest of the questions are straightforward
			Root.set_config("ctrl", "rot_inv", answers[1] == 1)
			Root.set_config("custom", "skin_name", ["CBPatterns", "Gen3"][answers[2]])
			Root.set_config("config", "setup_done", true)
			# fade out scene
			$AnimationPlayer.play("fade_out")
		_:
			print("Dialogic sent unrecognized event ID: %s" % value)

func _on_Skip_pressed():
	Root.set_config("config", "setup_done", true)
	Root.reset_scene()

func _on_AnimationPlayer_animation_finished(anim_name):
	match anim_name:
		"fade_in":
			_load_dialog("firsttime_000")
		"navi_appear":
			print("Navi appear end")
			accept_input = true
			_load_dialog("firsttime_001")
		"fade_out":
			Root.reset_scene()

func _load_dialog(timeline):
	# Load the branch.
	# (I don't know how to do this without freeing the existing dialog node.
	# Thanks, nonexistent documentation.)
	if dialog_node != null and is_instance_valid(dialog_node):
		dialog_node.queue_free()
	dialog_node = Dialogic.start(timeline)
	$MainBox/ViewportContainer/TextureViewport.add_child(dialog_node)
	dialog_node.connect("dialogic_signal", self, "_on_DialogNode_dialogic_signal")
