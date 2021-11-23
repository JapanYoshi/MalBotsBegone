extends CanvasLayer

var active = false
# Called when the node enters the scene tree for the first time.
func _ready():
	$Backdrop.hide()
	pass # Replace with function body.

func pause():
	$Backdrop.show()
	get_tree().paused = true
	$Backdrop/ColorRect/NinePatchRect/VBoxContainer/ResumeButton.grab_focus()
	active = true

func _input(event):
	if (event is InputEventKey or event is InputEventJoypadButton):
		if $Backdrop.get_focus_owner() == null and (
			event.is_action("ui_left") or
			event.is_action("ui_right") or
			event.is_action("ui_up") or
			event.is_action("ui_down") or
			event.is_action("ui_focus_next") or
			event.is_action("ui_focus_prev")
		):
			$Backdrop/ColorRect/NinePatchRect/VBoxContainer/ResumeButton.grab_focus()

func _on_ResumeButton_pressed():
	get_tree().paused = false
	$Backdrop.hide()
	active = false
	get_parent().unpause() # parent will inherit from GameModeHandler

func _on_RestartButton_pressed():
	get_tree().paused = false
	Root.request_bgm_stop()
	Root.restart_scene()

func _on_ExitButton_pressed():
	get_tree().paused = false
	Root.request_bgm_stop()
	Root.back_scene()
