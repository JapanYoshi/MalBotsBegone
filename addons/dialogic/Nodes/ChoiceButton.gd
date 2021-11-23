extends Button

## I want both the ui_accept and ui_cancel buttons to confirm the choice
## -Haley

func _gui_input(event):
	if event.is_action_pressed("ui_cancel"):
		emit_signal("pressed");
		accept_event()
