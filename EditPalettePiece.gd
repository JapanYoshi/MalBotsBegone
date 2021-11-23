extends Button

var parent
var id
signal select_piece(id)
# Called when the node enters the scene tree for the first time.
func _ready():
	print("EditPiece")
	parent = self.find_parent("EditMode")
	id = get_parent().get_index() + get_index() * 8
	if id != 0:
		$ThemedScaledSprite.set_theme_sprite(Root.get_config("custom", "skin_name"), [
			"Block1",
			"Block2",
			"Block3",
			"Block4",
			"Block5",
			"Wall",
			"Ball",
			"V0",
			"V1",
			"V2",
			"V3",
			"V4",
			"V5"
		][id-1])

func _on_TouchScreenButton_pressed():
#	print("Tap converted into left click")
	emit_signal("select_piece", id)

func _on_self_gui_input(event):
	if event is InputEventMouseButton:
	#	print("InputEventMouseButton: ", event.button_index, ", ", event.pressed)
		if event.pressed and event.button_index == 1:
			print("Clicked palette piece ", id)
			emit_signal("select_piece", id)

func highlight():
	$BG.show()

func unhighlight():
	$BG.hide()

func set_hp(hp):
	if hp == 1:
		$Label.hide()
	else:
		$Label.text = str(hp)
		$Label.show()
