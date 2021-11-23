extends CanvasLayer

var active = false
# Called when the node enters the scene tree for the first time.
func _ready():
	$Backdrop.hide()
	pass # Replace with function body.

func show_message():
	$Backdrop.show()
	($Backdrop/ColorRect/NinePatchRect/VBoxContainer/HBoxContainer/Panel as Control).grab_focus()
	active = true

func _input(event):
	if !active: return
	if (event is InputEventKey or event is InputEventJoypadButton):
		var focused = $Backdrop.get_focus_owner()
		if !is_instance_valid(focused) and (
			event.is_action("ui_left") or
			event.is_action("ui_right") or
			event.is_action("ui_focus_next") or
			event.is_action("ui_focus_prev")
		):
			($Backdrop/ColorRect/NinePatchRect/VBoxContainer/ResumeButton as Control).grab_focus()
			$Backdrop.accept_event()
		elif event.is_action_pressed("ui_up"):
			focused.get_node(focused.focus_neighbour_top).grab_focus()
			Root.request_sfx("cursor")
			$Backdrop.accept_event()
		elif event.is_action_pressed("ui_down"):
			focused.get_node(focused.focus_neighbour_bottom).grab_focus()
			Root.request_sfx("cursor")
			$Backdrop.accept_event()

func _on_ResumeButton_pressed():
	($Backdrop as Control).hide()
	active = false

func _on_twitter_pressed():
# warning-ignore:return_value_discarded
	OS.shell_open("https://twitter.com/hai1touch")
	
func _on_website_pressed():
# warning-ignore:return_value_discarded
	OS.shell_open("https://haitouch.ga")

func _on_Discord_pressed():
# warning-ignore:return_value_discarded
	OS.shell_open("https://discord.gg/95JWgy9gue")
