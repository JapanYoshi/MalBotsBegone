extends Control

var active = false
var playfield_data = [
	[0, 0, 0, 0, 0, 0, 0],
	[0, 0, 0, 0, 0, 0, 0],
	[0, 0, 0, 0, 0, 0, 0],
	[0, 0, 0, 0, 0, 0, 0],
	[0, 0, 0, 0, 0, 0, 0],
	[0, 0, 0, 0, 0, 0, 0],
	[0, 0, 0, 0, 0, 0, 0],
	[0, 0, 0, 0, 0, 0, 0],
	[0, 0, 0, 0, 0, 0, 0],
	[0, 0, 0, 0, 0, 0, 0],
	[0, 0, 0, 0, 0, 0, 0],
	[0, 0, 0, 0, 0, 0, 0],
	[0, 0, 0, 0, 0, 0, 0],
	[0, 0, 0, 0, 0, 0, 0],
]
var selected_id = 1
var selected_hp = 1
var palette_children = []

func reload_board():
	print("EditPlayfield - Reload board, ", Root.ROWS, "|", Root.COLUMNS, "=",  len(playfield_data), "|", len(playfield_data.front()))
	for y in range(0, Root.ROWS):
		for x in range(0, Root.COLUMNS):
			var id: int = playfield_data[y][x]
# warning-ignore:integer_division
			var hp: int = id / 8
			if hp > 1:
				id -= (hp - 1) * 8
			change_piece(Root.ROWS - y - 1, x, id, true, hp)

func set_active(x: bool):
	active = x
	if x:
		show()
	else:
		hide()

func _ready():
	palette_children = [
		$PaletteRect/Palette/Row0/L,
		$PaletteRect/Palette/Row1/L,
		$PaletteRect/Palette/Row2/L,
		$PaletteRect/Palette/Row3/L,
		$PaletteRect/Palette/Row4/L,
		$PaletteRect/Palette/Row5/L,
		$PaletteRect/Palette/Row6/L,
		$PaletteRect/Palette/Row7/L,
		$PaletteRect/Palette/Row0/R,
		$PaletteRect/Palette/Row1/R,
		$PaletteRect/Palette/Row2/R,
		$PaletteRect/Palette/Row3/R,
		$PaletteRect/Palette/Row4/R,
		$PaletteRect/Palette/Row5/R
	]
	palette_children[1].highlight()
	$Panel/Tabs/Label.bbcode_text = (
		"[b]" +
		TranslationServer.translate("I18N_EDIT_PLAYFIELD_MOUSE") +
		"[/b]\n" +
		TranslationServer.translate("I18N_EDIT_PLAYFIELD_MOUSE_HELP")
	)
	var buttons = [
		TranslationServer.translate("I18N_BTN_DOWN").left(1),
		TranslationServer.translate("I18N_BTN_RIGHT").left(1)
	]
	var swap = Root.get_config("config", "ab_inv")
	$Panel/Tabs/Label2.bbcode_text = (
		"[b]" +
		TranslationServer.translate("I18N_EDIT_PLAYFIELD_GAMEPAD") +
		"[/b]\n" +
		TranslationServer.translate("I18N_EDIT_PLAYFIELD_GAMEPAD_HELP") % [buttons[int(swap)], buttons[int(!swap)]]
	)
	$Panel/Tabs/Label3.bbcode_text = (
		"[b]" +
		(TranslationServer.translate("I18N_EDIT_PLAYFIELD_KEYBOARD")) +
		"[/b]\n" +
		TranslationServer.translate("I18N_EDIT_PLAYFIELD_KEYBOARD_HELP")
	)

func _input(event):
	if !self.visible: return;
	if event is InputEventJoypadButton or event is InputEventKey:
		var focused = self.get_focus_owner()
		if !focused or !self.find_node(focused.name, true):
			print("Nothing has focus. Grabbing focus.")
			$FieldRect/Rows.get_child($FieldRect/Rows.get_child_count() - 1).get_child(3).grab_focus()
			accept_event()
		elif str(focused.get_path()).begins_with(str($FieldRect/Rows.get_path())):
			print("Cursor in playfield.")
			var column = focused.get_index()
			var row = focused.get_parent().get_index()
			if event.is_action_pressed("ui_down"):
				$FieldRect/Rows.get_child((row + 1) % 14).get_child(column).grab_focus()
				if Input.is_action_pressed("ui_accept"):
					_on_piece_click(row + 1, column)
				elif Input.is_action_pressed("ui_cancel"):
					_on_piece_right_click(row + 1, column)
			elif event.is_action_pressed("ui_right"):
				if column != 6:
					$FieldRect/Rows.get_child(row).get_child(column + 1).grab_focus()
					if Input.is_action_pressed("ui_accept"):
						_on_piece_click(row, column + 1)
					elif Input.is_action_pressed("ui_cancel"):
						_on_piece_right_click(row + 1, column)
				else:
					$PaletteRect/Palette/Row0.get_child(0).grab_focus()
			elif event.is_action_pressed("ui_up"):
				$FieldRect/Rows.get_child(posmod(row - 1, 14)).get_child(column).grab_focus()
				if Input.is_action_pressed("ui_accept"):
					_on_piece_click(posmod(row - 1, 14), column)
				elif Input.is_action_pressed("ui_cancel"):
					_on_piece_right_click(posmod(row - 1, 14), column)
			elif event.is_action_pressed("ui_left"):
				$FieldRect/Rows.get_child(row).get_child(posmod(column - 1, 7)).grab_focus()
				if Input.is_action_pressed("ui_accept"):
					_on_piece_click(row, posmod(column - 1, 7))
				elif Input.is_action_pressed("ui_cancel"):
					_on_piece_right_click(row, posmod(column - 1, 7))
			elif event.is_action_pressed("ui_accept"):
				_on_piece_click(row, column)
			elif event.is_action_pressed("ui_cancel"):
				_on_piece_right_click(row, column)
			elif event.is_action_pressed("ui_page_up"):
				_on_select_cursor(false)
			elif event.is_action_pressed("ui_page_down"):
				_on_select_cursor(true)
			elif event.is_action_pressed("ui_home"):
				_on_hp_cursor(true)
			elif event.is_action_pressed("ui_end"):
				_on_hp_cursor(false)
			else:
				return
			accept_event()
		elif str(focused.get_path()).begins_with(str($PaletteRect/Palette/Row0.get_path())):
			print("Cursor in palette row 0.")
			if event.is_action_pressed("ui_up"):
				$ButtonExit.grab_focus()
				accept_event()
		elif str(focused.get_path()).begins_with(str($PaletteRect/Palette.get_path())):
			print("Cursor in palette.")
		elif str(focused.get_path()).begins_with(str($ButtonExit.get_path())):
			print("Cursor on Exit button.")
			if event.is_action_pressed("ui_left"):
				$FieldRect/Rows/Row0.get_child(6).grab_focus()
				accept_event()
		else:
			print("Cursor elsewhere.")
			pass
#	elif event is InputEventMouse:
#		print("mouse event")
#		pass
#	elif event is InputEventScreenTouch:
#		print("screen touch event")
#		pass

func change_piece(row, column, id, silent = false, hp = 0):
	if hp == 0:
		hp = selected_hp
	#print("I'd like to change %2d,%2d into %2d (with HP %1d)." % [row, column, id, hp])
	if !silent:
		request_piece_sfx(id)
	$FieldRect/Rows.get_child(row).get_child(column).set_piece(id, hp)
	if len(playfield_data) != Root.ROWS:
		while len(playfield_data) < Root.ROWS:
			playfield_data.append([0, 0, 0, 0, 0, 0, 0])
		if len(playfield_data) > Root.ROWS:
			playfield_data.resize(Root.ROWS)
	while len(playfield_data[Root.ROWS - row - 1]) < Root.COLUMNS:
		playfield_data[Root.ROWS - row - 1].append(0)
	playfield_data[Root.ROWS - row - 1][column] = id + (8 * (hp - 1) if id >= 8 else 0)

func _on_piece_click(row, column):
	change_piece(row, column, selected_id)

func _on_piece_right_click(row, column):
	change_piece(row, column, 0)

const major_scale = [
	1.0,
	9.0/8.0,
	5.0/4.0,
	4.0/3.0,
	3.0/2.0,
	5.0/3.0,
	15.0/8.0
]

func _on_hp_cursor(up):
	if (!up and selected_hp == 1) or (up and selected_hp == 7):
		print("Can't change HP anymore!")
		Root.request_sfx("move_fail")
	else:
		selected_hp += (1 if up else -1)
		Root.request_sfx("on" if up else "off", major_scale[selected_hp - 1])
		for i in range(8, 14):
			palette_children[i].set_hp(selected_hp)

func _on_select_cursor(next):
	if (!next and selected_id == 0) or (next and selected_id == 13):
		Root.request_sfx("move_fail")
		print("Can't change block ID anymore!")
	else:
		palette_children[selected_id].unhighlight()
		selected_id += (1 if next else -1)
		request_piece_sfx(selected_id)
		palette_children[selected_id].highlight()

func request_piece_sfx(id):
	print("Requesting sound effect for piece id ", id)
	if id == 0:
		Root.request_sfx("null_select")
	elif id == 6:
		Root.request_sfx("wall_select")
	elif id == 7:
		Root.request_sfx("ball_select")
	elif id < 8:
		Root.request_sfx("block_select", major_scale[id])
	else:
		Root.request_sfx("enemy_select", major_scale[id - 8])

func _on_select_piece(id):
	selected_id = id
	request_piece_sfx(selected_id)
	highlight_piece()

func highlight_piece():
	for i in len(palette_children):
		if i == selected_id:
			palette_children[i].highlight()
		else:
			palette_children[i].unhighlight()


func _on_ButtonExit_pressed():
	set_active(false)
	find_parent("EditMode").back_to_menu()


func _on_Timer_timeout():
	$Panel/Tabs.current_tab = (1 + $Panel/Tabs.current_tab) % $Panel/Tabs.get_child_count()
