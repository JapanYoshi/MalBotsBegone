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

var paused: bool = false
var invert: bool = false
var time: int = -1
var last_pressed: int = -1
var das: int = 12
var arr: int = 2
var debug: bool = false

# Called when the node enters the scene tree for the first time.
func _ready():
	invert = Root.get_config("ctrl", "rot_inv")
	if invert:
		var tex_n = $ButtonPadRight/ButtonB.texture_normal
		var tex_p = $ButtonPadRight/ButtonB.texture_pressed
		$ButtonPadRight/ButtonB.texture_normal = $ButtonPadRight/ButtonA.texture_normal;
		$ButtonPadRight/ButtonB.texture_pressed = $ButtonPadRight/ButtonA.texture_pressed;
		$ButtonPadRight/ButtonA.texture_normal = tex_n;
		$ButtonPadRight/ButtonA.texture_pressed = tex_p;
	das = Root.get_config("ctrl", "das")
	arr = Root.get_config("ctrl", "arr")
	debug = (get_parent() == get_tree().get_root())

func set_active(value):
	paused = !value
	if paused:
		hide()
	else:
		show()

func _process(delta):
	if paused:
		return;
	# process das/arr
	time = int(OS.get_system_time_msecs() * 60.0 / 1000.0)
	if last_pressed == -1 or time < last_pressed:
		return
	if $ButtonPadLeft/ButtonLeft.is_pressed():
		if arr:
			emit_signal("move_left")
			last_pressed += arr
			if debug:
				print("LEFT - repeating again at ", last_pressed % 1000)
		else:
			emit_signal("warp_left")
			last_pressed += 1
			if debug:
				print("LEFT - warp; repeating again at ", last_pressed % 1000)
	elif $ButtonPadLeft/ButtonRight.is_pressed():
		if arr:
			emit_signal("move_right")
			last_pressed += arr
			if debug:
				print("RIGHT - repeating again at ", last_pressed % 1000)
		else:
			emit_signal("warp_right")
			last_pressed += 1
			if debug:
				print("RIGHT - warp; repeating again at ", last_pressed % 1000)


func _on_ButtonLeft_pressed():
	last_pressed = time + das
	if debug:
		print("LEFT PRESS; repeating again at ", last_pressed % 1000)
	emit_signal("move_left")

func _on_ButtonRight_pressed():
	last_pressed = time + das
	if debug:
		print("RIGHT PRESS; repeating again at ", last_pressed % 1000)
	emit_signal("move_right")

func _on_ButtonDown_pressed():
	emit_signal("soft_drop_start")

func _on_ButtonDown_released():
	emit_signal("soft_drop_end")

func _on_ButtonUp_pressed():
	emit_signal("hard_drop_start")

func _on_ButtonB_pressed():
	if invert:
		emit_signal("rotate_right")
	else:
		emit_signal("rotate_left")

func _on_ButtonA_pressed():
	if invert:
		emit_signal("rotate_left")
	else:
		emit_signal("rotate_right")

func pause():
	paused = true
	hide()

func unpause():
	print("InputButton unpaused")
	paused = false
	show()

func _on_ButtonLeft_released():
	last_pressed = -1

func _on_ButtonRight_released():
	last_pressed = -1
