extends Control

signal move_left
signal move_right
signal rotate_left
signal rotate_right
signal soft_drop_start
signal soft_drop_end
signal hard_drop_start
signal warp_left
signal warp_right
signal pause

var paused: bool = false
var time: int = 0
var invert: bool = false
var last_pressed: int = -1
var das: int = 11
var arr: int = 1
var debug: bool = false

# Called when the node enters the scene tree for the first time.
func _ready():
	if get_parent() == self.get_tree().root:
		debug = true
		$Test.show()
	else:
		debug = false
		$Test.free()
	invert = Root.get_config("ctrl", "rot_inv")
	das = Root.get_config("ctrl", "das")
	arr = Root.get_config("ctrl", "arr")
	Root.load_inputs()

func frames(ms):
	return int(ms * 60.0 / 1000.0)

func _process(delta: float):
	# process das/arr
	time = frames(OS.get_system_time_msecs())
	if debug:
		$Test/Timestamp.text = str(time)
	if last_pressed == -1 or time < last_pressed:
		if debug:
			print("%02d" % (time % 60), " Not time to repeat: ", "%02d" % (last_pressed % 60))
		return
	print("%02d" % (time % 60), " Repeating: ", "%02d" % (last_pressed % 60))
	if Input.is_action_pressed("gp_left"):
		if debug:
			print(last_pressed % 60, " Left held")
		if arr:
			emit_signal("move_left")
			last_pressed += arr
		else:
			emit_signal("warp_left")
			last_pressed += 1
	elif Input.is_action_pressed("gp_right"):
		if debug:
			print(last_pressed % 60, " Right held")
		if arr:
			emit_signal("move_right")
			last_pressed += arr
		else:
			emit_signal("warp_right")
			last_pressed += 1

func set_active(value):
	paused = !value
	if value:
		hide()
	else:
		show()

func _input(event):
	if paused or not (
		event is InputEventJoypadButton or
		event is InputEventKey
	):
		return
	accept_event()
	if event.is_action_pressed("gp_pause"):
		emit_signal("pause")
	# "holdable" buttons: left, right, soft drop
	elif event.is_action_pressed("gp_left") and not(
		 event is InputEventKey and event.is_echo()
	):
		last_pressed = time + das
		if debug:
			print("%02d" % (time % 60), " Left pressed ", "%02d" % (last_pressed % 60))
		emit_signal("move_left")
	elif event.is_action_released("gp_left"):
		last_pressed = -1
	elif event.is_action_pressed ("gp_right") and not(
		 event is InputEventKey and event.is_echo()
	):
		last_pressed = time + das
		if debug:
			print("%02d" % (time % 60), " Right pressed ", "%02d" % (last_pressed % 60))
		emit_signal("move_right")
	elif event.is_action_released("gp_right"):
		last_pressed = -1
	elif event.is_action_pressed ("gp_soft", false):
		emit_signal("soft_drop_start")
	elif event.is_action_released("gp_soft"):
		emit_signal("soft_drop_end")
	# not "holdable" buttons: rotate, hard drop
	elif event.is_action_pressed ("gp_b"):
		if invert:
			emit_signal("rotate_right")
		else:
			emit_signal("rotate_left")
	elif event.is_action_pressed ("gp_a"):
		if invert:
			emit_signal("rotate_left")
		else:
			emit_signal("rotate_right")
	elif event.is_action_pressed ("gp_hard"):
		emit_signal("hard_drop_start")
