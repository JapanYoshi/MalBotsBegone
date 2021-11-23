extends Control


# Declare member variables here. Examples:
# var a = 2
# var b = "text"
var edit_root

# Called when the node enters the scene tree for the first time.
func _ready():
	edit_root = find_parent("EditMode")
	pass

# Called every frame. 'delta' is the elapsed time since the previous frame.
#func _process(delta):
#	pass
func _input(event):
	if !visible or !get_parent().visible: return;
	if event is InputEventJoypadButton or event is InputEventKey:
		var focused = self.get_focus_owner()
		if !focused:
			$ButtonObjective.grab_focus()
		elif event.is_action_pressed("ui_up"):
			Root.focus_neighbor(focused, 0)
		elif event.is_action_pressed("ui_right"):
			Root.focus_neighbor(focused, 1)
		elif event.is_action_pressed("ui_down"):
			Root.focus_neighbor(focused, 2)
		elif event.is_action_pressed("ui_left"):
			Root.focus_neighbor(focused, 3)
		elif event.is_action_pressed("ui_accept"):
			print(focused.name)
			match focused.name:
				"ButtonObjective":
					edit_root._on_ButtonObjective_pressed()
				"ButtonPlayfield":
					edit_root._on_ButtonPlayfield_pressed()
				"ButtonNext":
					edit_root._on_ButtonNext_pressed()
				"ButtonTest":
					edit_root._test()
				"ButtonShare":
					edit_root._on_ButtonShare_pressed()
				"ButtonRestart":
					edit_root._on_ButtonRestart_pressed()
				"ButtonExit":
					edit_root._on_ButtonExit_pressed()
		elif event.is_action_pressed("ui_cancel"):
			$ButtonExit.grab_focus()
		accept_event()
	elif event is InputEventMouse:
#		print("mouse event")
		pass
	elif event is InputEventScreenTouch:
#		print("screen touch event")
		pass
