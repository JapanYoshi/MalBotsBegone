extends CheckButton
signal color_check(id, value)

func _toggled(button_pressed: bool):
	emit_signal("color_check", get_index(), button_pressed)
