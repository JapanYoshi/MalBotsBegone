extends WindowDialog

const Next = preload("res://NextClass.gd")

var parent: Node
var no_color: Node
var my_index: int
var id_0: int
var id_1: int
var index_0: int
var index_1: int
# Called when the node enters the scene tree for the first time.
func _ready():
	parent = find_parent("EditNext")
	index_0 = find_node("CenterDominoRow", true).get_index()
	index_1 = find_node("OuterDominoRow", true).get_index()
	no_color = $VBoxContainer/A/Button
	pass # Replace with function body.

func edit_domino(index: int, id_0_: int = 0, id_1_: int = 0):
	my_index = index
	if id_0_:
		print("EditDominoDialog Editing index %d with data %d, %d" % [index, id_0_, id_1_])
		id_0 = id_0_
		id_1 = id_1_
	else:
		print("EditDominoDialog Editing index %d as new domino" % index)
		id_0 = 0
		id_1 = 0
	no_color.pressed = (id_0 == 0)
	$VBoxContainer/CenterDominoRow.change_value(id_0)
	$VBoxContainer/OuterDominoRow.change_value(id_1)
	$VBoxContainer/Panel/Label.text = TranslationServer.tr("I18N_EDITING_DOMINO_%d") % index
	popup()
	$VBoxContainer/A/Button.grab_focus()

func _on_domino_row_changed(index: int, value: int):
	print("EditDominoDialog _on_domino_row_changed(%d, %d)" % [index, value])
	if   index == index_0:
		id_0 = value
		if no_color.pressed:
			no_color.pressed = false
			id_1 = 1
			$VBoxContainer/OuterDominoRow.change_value(1)
	elif index == index_1:
		id_1 = value
		if no_color.pressed:
			no_color.pressed = false
			id_0 = 1
			$VBoxContainer/CenterDominoRow.change_value(1)
	else:
		printerr("EditDominoDialog - Error on _on_domino_row_changed(index = %d, value = %d): Unrecognized index." % [index, value])

func _on_X_pressed():
	id_0 = 0; id_1 = 0
	$VBoxContainer/CenterDominoRow.change_value(0)
	$VBoxContainer/OuterDominoRow.change_value(0)

func _on_next_pressed():
	if my_index < len(parent.dominoes) - 1:
		hide()
		parent.swap_dominoes(my_index)
		parent.popup(my_index + 1)

func _on_prev_pressed():
	if my_index > 0:
		hide()
		parent.swap_dominoes(my_index - 1)
		parent.popup(my_index - 1)

func _on_overwrite_pressed():
	parent.overwrite_domino(my_index, id_0, id_1)
	hide()

func _on_insert_pressed():
	parent.insert_domino_before(my_index, id_0, id_1)
	hide()

func _on_delete_pressed():
	parent.delete_domino(my_index)
	hide()
