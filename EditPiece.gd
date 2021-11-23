extends Button

var parent
var pos
signal piece_click(id)
signal piece_right_click(id)
signal select_cursor(next)
signal hp_cursor(next)
# Called when the node enters the scene tree for the first time.
func _ready():
	parent = self.find_parent("EditMode")
	pos = [get_parent().get_index(), get_index()]
	$ThemedScaledSprite.auto_scale()

func set_piece(which: int, hp: int = 0):
	#print("set to %2d with HP %1d" % [which, hp])
	if which == 0:
		$ThemedScaledSprite.hide()
		$Label.hide()
		return;
	$ThemedScaledSprite.show()
	if which < 8:
		$Label.hide()
		if which == 6:
			$ThemedScaledSprite.set_sprite("Wall")
		elif which == 7:
			$ThemedScaledSprite.set_sprite("Ball")
		else:
			$ThemedScaledSprite.set_sprite("Block%1d" % which)
	else:
		$ThemedScaledSprite.set_sprite("V%1d" % (which % 8))
		if hp < 2:
			$Label.hide()
		else:
			$Label.text = str(hp);
			$Label.show()

func _on_TouchScreenButton_pressed():
#	print("Tap converted into left click")
	emit_signal("piece_click", self.get_index())

func _on_self_gui_input(event):
	if event is InputEventMouseButton:
	#	print("InputEventMouseButton: ", event.button_index, ", ", event.pressed)
		if event.pressed:
			match event.button_index:
				1:
#					print("Left click")
					emit_signal("piece_click", self.get_index())
				2:
#					print("Right click")
					emit_signal("piece_right_click", self.get_index())
				4:
					emit_signal("select_cursor", false)
				5:
					emit_signal("select_cursor", true)
				8:
					emit_signal("hp_cursor", false)
				9:
					emit_signal("hp_cursor", true)
