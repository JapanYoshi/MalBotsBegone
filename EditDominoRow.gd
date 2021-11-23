extends HBoxContainer

signal domino_row_changed(index, value)
var selection = 0
# Called when the node enters the scene tree for the first time.
func _ready():
	pass

func change_value(new_value):
	print("EditDominoRow change_value(%d)" % new_value)
	if selection != 0:
		print("Deselected item %d" % selection)
		get_child(selection - 1).pressed = false
	selection = new_value
	if selection != 0:
		print("Selected item %d" % selection)
		get_child(selection - 1).pressed = true

func _on_value_changed(index):
	print("EditDominoRow _on_value_changed(%d)" % index)
	selection = index + 1
	emit_signal("domino_row_changed", self.get_index(), selection)
