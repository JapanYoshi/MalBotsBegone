extends Button
signal value_changed(index)

var index

func _ready():
	index = get_index()
	$CenterContainer/Control/ThemedScaledSprite.set_sprite("Block%d" % (index + 1))

func focus():
	pressed = true

func unfocus():
	pressed = false

func _toggled(button_pressed):
	print("EditDominoButton toggled(%s)" % bool(button_pressed))
	if button_pressed:
		emit_signal("value_changed", index)
