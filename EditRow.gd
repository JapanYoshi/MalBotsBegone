extends HBoxContainer

signal piece_click(row, column)
signal piece_right_click(row, column)
signal select_cursor(next)
signal hp_cursor(next)

var row_index: int
# Called when the node enters the scene tree for the first time.
func _ready():
	row_index = self.get_index()
	pass # Replace with function body.

func _on_select_piece(id):
	emit_signal("piece_click", row_index, id)
	print("piece click: %02d,%02d" % [row_index, id])

func _on_deselect_piece(index):
	emit_signal("piece_right_click", row_index, index)
	print("piece right click: %02d,%02d" % [row_index, index])

func _on_select_cursor(next):
	emit_signal("select_cursor", next)
	pass # Replace with function body.

func _on_hp_cursor(next):
	emit_signal("hp_cursor", next)
