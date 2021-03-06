extends Button

signal increment_by(value)
signal decrement_by(value)
export var decrement = false
export var multiplier: float = 1.0
var press_duration: float
var last_step_taken: float
var speed_level = 0
var thres = [0.500, 1.000, 1.000, 1.000, 1.000, 1.000, 1.000,  1.000,   1.000]
var delay = [0.250, 0.100, 0.100, 0.100, 0.100, 0.100, 0.100,  0.100,   0.100, 0.050]
var step  = [    1,     1,     2,    10,   100,  1000, 10000, 100000, 1000000, 1000000]
var is_pressed: bool = false

var SwipeContainer: Node

# Called when the node enters the scene tree for the first time.
func _ready():
	press_duration = 0
	var parent = get_parent()
	while is_instance_valid(parent) and parent != Root:
		if "is_swipe_container" in parent:
			SwipeContainer = parent
			break
		else:
			parent = parent.get_parent()

func _gui_input(event):
	if (
		event is InputEventMouseButton or
		event.is_action("ui_accept")
	):
		print("IncDecButton - GUI input event %s" % event)
		if !event.is_pressed():
			if last_step_taken == 0:
				emit_signal("decrement_by" if decrement else "increment_by", step[speed_level] * multiplier)
			is_pressed = false
			press_duration = 0
			speed_level = 0
			last_step_taken = 0
			print("IncDecButton - Button just up")
		else:
			is_pressed = true
			print("IncDecButton - Button just down")

func _process(delta):
	if is_pressed:
		if is_instance_valid(SwipeContainer) and SwipeContainer.swipe_distance > 8:
			# don't increment time while swiping
			return
		press_duration += delta
		while press_duration > last_step_taken + delay[speed_level]:
			#print("IncDecButton - Value change %5d" % step[speed_level])
			emit_signal("decrement_by" if decrement else "increment_by", step[speed_level] * multiplier)
			last_step_taken += delay[speed_level]
		if speed_level < len(thres) and press_duration > thres[speed_level]:
			print("IncDecButton - Speed level to %d" % (speed_level + 1))
			press_duration -= thres[speed_level]
			last_step_taken = 0
			speed_level += 1
	else:
		pass
