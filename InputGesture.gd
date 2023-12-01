extends Control

signal move_left
signal move_right
signal rotate_left
signal rotate_right
signal soft_drop_start
signal soft_drop_end
signal hard_drop_start
# The center of the visual touch-cursor indicator.
var cursor_origin = Vector2(-12, -29)
# Current time in seconds. Sum of all deltas so far.
var now: float = 0;
# Tracks mouse click position.
var last_pos: Vector2
var this_pos: Vector2
# Tracks last time a rotation was triggered.
# Intended to fix issues with double tapping on mobile.
var last_press: float = -9000;
# Ignore rotation inputs if another rotation input was
# registered this many seconds ago or sooner.
const press_debounce: float = 7.0 / 60.0;
# Currently clicked/touched.
var pressed: bool = false
### Movement distance ###
# How many seconds it's been clicked/touched.
var press_duration = 0.0
# How many dp you need to drag sideways
# in order to move the block.
var thres_move = 32
# How many dp you need to drag down/up
# in order to activate/deactivate soft drop.
var thres_softdrop = 32
# How many dp you need to drag down
# in order to hard drop.
var thres_harddrop = 96
# If held this many seconds or longer,
# ignore rotation.
var thres_rotate = 0.25
# If this is true, ignore rotation.
var just_moved: bool = false
var soft_drop_pressed: bool = false
var hard_drop_pressed: bool = false
var invert: bool = false

var paused: bool = false
var first_frame_of_unpausing: bool = false

# Called when the node enters the scene tree for the first time.
func _ready():
	invert = Root.get_config("ctrl", "rot_inv")

func set_active(to_active):
	paused = !to_active
	if to_active:
		show()
	else:
		hide()

func _process(delta):
	if paused or first_frame_of_unpausing:
		first_frame_of_unpausing = false
		return
	now += delta
	press_duration += delta
	var diff = this_pos - last_pos
	diff.y = min(80, max(-16, diff.y))
	$GesturePad/Cursor.set_position(cursor_origin + diff)
	if pressed:
		$GesturePad/Cursor.show()
	else:
		$GesturePad/Cursor.hide()
	if !pressed or press_duration < thres_rotate:
		$GesturePad/IconsClick.show()
	else:
		$GesturePad/IconsClick.hide()
	if !pressed or press_duration >= thres_rotate:
		$GesturePad/IconsDrag.show()
	else:
		$GesturePad/IconsDrag.hide()

func _input(event):
	if paused:
		return
	if not (
#		event is InputEventScreenTouch or
#		event is InputEventScreenDrag or
		event is InputEventMouseButton or
		event is InputEventMouseMotion
	):
		return
	if event is InputEventScreenTouch\
	or event is InputEventMouseButton:
		if event.is_pressed():
			pressed = true
			press_duration = 0
			last_pos = event.position
			this_pos = last_pos
		else:
			pressed = false
			if soft_drop_pressed:
				print("soft_drop_end")
				emit_signal("soft_drop_end")
			soft_drop_pressed = false
			hard_drop_pressed = false
			# Check if it's a rotation input
			if !just_moved and press_duration < thres_rotate:
				if now - last_press >= press_debounce:
					last_press = now
				else:
					return
				# rotate
				if last_pos.x < .get_size().x / 2.0:
					# rotate left
					print("rotate_left")
					emit_signal("rotate_left")
					anim_click(false)
				else:
					# rotate right
					print("rotate_right")
					emit_signal("rotate_right")
					anim_click(true)
			just_moved = false
	elif event is InputEventScreenDrag\
	or event is InputEventMouseMotion:
		if pressed:
			this_pos = event.position
			if this_pos.x - last_pos.x >= thres_move:
				press_duration = 999
				# drag right
				last_pos.x += thres_move
				print("move_right")
				emit_signal("move_right")
				just_moved = true
			elif this_pos.x - last_pos.x <= -thres_move:
				press_duration = 999
				# drag left
				last_pos.x -= thres_move
				print("move_left")
				emit_signal("move_left")
				just_moved = true
			if this_pos.y - last_pos.y > thres_harddrop:
				press_duration = 999
				# hard drop
				if !hard_drop_pressed:
					hard_drop_pressed = true
					print("hard_drop_pressed")
					emit_signal("hard_drop_start")
				just_moved = true
			elif this_pos.y - last_pos.y > thres_softdrop:
				press_duration = 999
				# soft drop
				if hard_drop_pressed:
					hard_drop_pressed = false
					print("hard_drop_released")
				if !soft_drop_pressed:
					soft_drop_pressed = true
					print("soft_drop_pressed")
					emit_signal("soft_drop_start")
				just_moved = true
			else:
				if soft_drop_pressed:
					soft_drop_pressed = false
					print("soft_drop_released")
					emit_signal("soft_drop_end")
					just_moved = true
		else:
			pass

func anim_click(right: bool = false): # `xor` has the same truth table as `!=`
	var click = $GesturePad/RightClick if right != invert else $GesturePad/LeftClick
	click.show()
	$Timer.wait_time = 2 / 60.0
	$Timer.connect("timeout", click, "hide", [], CONNECT_ONESHOT)
	$Timer.start()

func pause():
	hide()
	last_pos = Vector2(0, 0)
	this_pos = Vector2(0, 0)
	pressed = false
	press_duration = 99999
	soft_drop_pressed = false
	hard_drop_pressed = false
	paused = true

func unpause():
	# reset input
	print("InputGesture unpaused")
	last_pos = Vector2(0, 0)
	this_pos = Vector2(0, 0)
	pressed = false
	press_duration = 99999
	soft_drop_pressed = false
	hard_drop_pressed = false
	first_frame_of_unpausing = true
	paused = false
	show()
