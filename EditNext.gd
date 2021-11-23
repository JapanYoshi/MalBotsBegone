extends Control

const Next = preload("res://NextClass.gd").Next
const Domino = preload("res://EditDomino.tscn")
var active = false
var grid: Node
var dominoes = []
var last_domino = Next.new()

func set_active(x: bool):
	active = x
	if x:
		show()
		$A/H/OptionButton.grab_focus()
	else:
		hide()

# Called when the node enters the scene tree for the first time.
func _ready():
	grid = $A/Dominoes/GridContainer
	generate_dominoes()
	init_spinbox()
	init_dropdown()
	$A/H/Label.set_text("I18N_EDIT_END_BEHAVIOR")
	pass

func generate_dominoes():
	for child in grid.get_children():
		child.queue_free()
	for domino in dominoes:
		assert(domino is Next)
		var elem = Domino.instance()
		elem.set_visual(domino.id_0, domino.id_1)
		grid.add_child(elem)
	grid.add_child(Domino.instance())

func init_dropdown():
	$A/H/OptionButton.selected = 0
	match last_domino.id_0:
		0:
			$A/H/OptionButton.selected = 0
			$A/WarnLabel.text = ""
		6:
			$A/H/OptionButton.selected = 1
			for i in range(0, 5):
				$A/TabContainer/A.get_child(i).pressed = bool((last_domino.id_0 >> i) & 1)
			color_set_warning()
		7:
			$A/H/OptionButton.selected = 2
			$A/TabContainer/B/C/RangeSelector.value = last_domino.id_1
			$A/WarnLabel.text = ""

func init_spinbox():
	$A/TabContainer/B/C/RangeSelector.max_value = max(0, len(dominoes) - 1)
	if $A/TabContainer/B/C/RangeSelector.value > $A/TabContainer/B/C/RangeSelector.max_value:
		$A/TabContainer/B/C/RangeSelector.value = $A/TabContainer/B/C/RangeSelector.max_value

func popup(id):
	if id == len(dominoes):
		print("Last domino selected")
		$WindowDialog.edit_domino(id)
	else:
		print("Domino index %d selected with data %d, %d" % [id, dominoes[id].id_0, dominoes[id].id_1])
		$WindowDialog.edit_domino(id, dominoes[id].id_0, dominoes[id].id_1)

func overwrite_domino(id, id_0, id_1):
	print("EditNext overwrite_domino(%d, %d, %d)" % [id, id_0, id_1])
	if id_0 == 0:
		if len(dominoes):
			delete_domino(id)
	elif id == len(dominoes):
		dominoes.push_back(Next.new(id_0, id_1))
		var new_domino = Domino.instance()
		new_domino.set_visual(id_0, id_1)
		grid.add_child(new_domino)
		grid.move_child(new_domino, id)
		init_spinbox()
	else:
		dominoes[id] = Next.new(id_0, id_1)
		grid.get_child(id).set_visual(id_0, id_1)

func insert_domino_before(id, id_0, id_1):
	print("EditNext insert_domino_before(%d, %d, %d)" % [id, id_0, id_1])
	if id_0 == 0:
		pass
	else:
		dominoes.insert(id, Next.new(id_0, id_1))
		var new_domino = Domino.instance()
		new_domino.set_visual(id_0, id_1)
		grid.add_child(new_domino)
		grid.move_child(new_domino, id)
		init_spinbox()
	

func delete_domino(id):
	print("EditNext delete_domino(%d)" % id)
	if len(dominoes):
		dominoes.remove(id)
		grid.remove_child(grid.get_child(id))
	init_spinbox()

func swap_dominoes(id_first: int, id_last: int = -1):
	if id_last == -1:
		id_last = id_first + 1
	print("EditNext swap_dominoes(%d, %d)" % [id_first, id_last])
	if id_first == id_last:
		printerr("EditNext Can't swap with itself!")
	elif (
		id_first < 0 or id_first >= len(dominoes) or
		id_last < 0 or id_last >= len(dominoes)
	):
		printerr("EditNext Index(es) out of range!")
	else:
		print("Swap 0 ", grid.get_children())
		var swap_temp = dominoes[id_last]
		var elem_0 = grid.get_child(id_first)
		var elem_1 = grid.get_child(id_last)
		dominoes[id_last] = dominoes[id_first]
		grid.move_child(elem_0, id_last)
		print("Swap 1 ", grid.get_children())
		grid.move_child(elem_1, id_first)
		dominoes[id_first] = swap_temp
		print("Swap 2 ", grid.get_children())


func _on_color_check(id, value):
	if value:
		last_domino.id_1 = last_domino.id_1 | (1 << id)
	else:
		last_domino.id_1 = last_domino.id_1 & ~(1 << id)
	color_set_warning()

func color_set_warning():
	if last_domino.id_1 == 0:
		$A/WarnLabel.text = TranslationServer.translate("I18N_EDIT_NO_COLORS")
	elif bit_count(last_domino.id_1) < 3:
		$A/WarnLabel.text = TranslationServer.translate("I18N_EDIT_TOO_FEW_COLORS")
	else:
		$A/WarnLabel.text = ""

func bit_count(x: int) -> int:
	var count = 0
	while x != 0:
		count += (x & 1)
		x = x >> 1
	return count

func _on_ButtonExit_pressed():
	set_active(false)
	find_parent("EditMode").back_to_menu()

func _on_loop_index_changed(value):
	last_domino.id_1 = value

func set_dominoes(new_dominoes):
	last_domino = new_dominoes.pop_back()
	dominoes = new_dominoes
	generate_dominoes()
	init_dropdown()
	init_spinbox()
	if last_domino.id_0 == 7:
		# randomize colors
		for child in $A/TabContainer/A/B.get_children():
			var i = child.get_index()
			child.pressed = bool((last_domino.id_1 >> i) & 1)

func get_length():
	match last_domino.id_0:
		0:
			return dominoes.length()
		6, 7:
			return -1
