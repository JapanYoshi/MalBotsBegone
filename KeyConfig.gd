extends Control

const string2input = {
	"I18N_MOVE_LEFT": "gp_left",
	"I18N_MOVE_RIGHT": "gp_right",
	"I18N_ROTATE_LEFT": "gp_b",
	"I18N_ROTATE_RIGHT": "gp_a",
	"I18N_SOFT_DROP": "gp_soft",
	"I18N_HARD_DROP": "gp_hard",
	"I18N_PAUSE": "gp_pause"
}

var elem_list

# Called when the node enters the scene tree for the first time.
func _ready():
	$VBoxContainer/ScrollContainer/PageSelect/KeyButton.grab_focus()
	elem_list = [
		$VBoxContainer/TabContainer/I18N_KEYBOARD/v/I18N_MOVE_LEFT,
		$VBoxContainer/TabContainer/I18N_KEYBOARD/v/I18N_MOVE_RIGHT,
		$VBoxContainer/TabContainer/I18N_KEYBOARD/v/I18N_ROTATE_LEFT,
		$VBoxContainer/TabContainer/I18N_KEYBOARD/v/I18N_ROTATE_RIGHT,
		$VBoxContainer/TabContainer/I18N_KEYBOARD/v/I18N_SOFT_DROP,
		$VBoxContainer/TabContainer/I18N_KEYBOARD/v/I18N_HARD_DROP,
		$VBoxContainer/TabContainer/I18N_KEYBOARD/v/I18N_PAUSE,
		$VBoxContainer/TabContainer/I18N_GAMEPAD/v/I18N_MOVE_LEFT,
		$VBoxContainer/TabContainer/I18N_GAMEPAD/v/I18N_MOVE_RIGHT,
		$VBoxContainer/TabContainer/I18N_GAMEPAD/v/I18N_ROTATE_LEFT,
		$VBoxContainer/TabContainer/I18N_GAMEPAD/v/I18N_ROTATE_RIGHT,
		$VBoxContainer/TabContainer/I18N_GAMEPAD/v/I18N_SOFT_DROP,
		$VBoxContainer/TabContainer/I18N_GAMEPAD/v/I18N_HARD_DROP,
		$VBoxContainer/TabContainer/I18N_GAMEPAD/v/I18N_PAUSE,
	]
	print("elem_list: ", elem_list)
	for i in range(0, 14):
		var elem = elem_list[i]
		var gamepad = i >= len(elem_list) / 2
		print(InputMap.get_action_list(
				string2input[elem.action_name]
			))
		for event in (
			InputMap.get_action_list(
				string2input[elem.action_name]
			)
		):
			print("i: ", i, ", elem: ", elem_list[i], ", event: ", event)
			if (
				gamepad and event is InputEventJoypadButton
			) or (
				!gamepad and event is InputEventKey
			):
				print("yes, apply")
				elem.change_value(
					human_name(true, event.button_index) if gamepad else human_name(false, event.scancode)
				)

func _input(event):
	if event.is_action_pressed("ui_left")\
	or event.is_action_pressed("ui_right")\
	or event.is_action_pressed("ui_up")\
	or event.is_action_pressed("ui_down"):
		Root.request_sfx("cursor")

func remap(gamepad, action):
	Root.request_sfx("decide")
	$PopupPanel.activate(gamepad, action)

func unmap(gamepad, action):
	Root.request_sfx("discard")
	var list = InputMap.get_action_list(string2input[action])
	for event in list:
		if (
			gamepad and event is InputEventJoypadButton
		) or (
			!gamepad and event is InputEventKey
		):
			InputMap.action_erase_event(string2input[action], event)
	$VBoxContainer/TabContainer.\
	find_node("I18N_" + ("GAMEPAD" if gamepad else "KEYBOARD")).find_node(action).\
	change_value(
		"I18N_UNMAPPED"
	)

func apply(gamepad, action, new_event):
	var list = InputMap.get_action_list(string2input[action])
	for event in list:
		if (
			gamepad and event is InputEventJoypadButton
		) or (
			!gamepad and event is InputEventKey
		):
			InputMap.action_erase_event(string2input[action], event)
	InputMap.action_add_event(string2input[action], new_event)
	$VBoxContainer/TabContainer.\
	find_node("I18N_" + ("GAMEPAD" if gamepad else "KEYBOARD")).find_node(action).\
	change_value(
		human_name(gamepad, new_event.get_button_index() if gamepad else new_event.get_scancode())
	)

func _on_KeyButton_pressed():
	$VBoxContainer/TabContainer.current_tab = 0
	Root.request_sfx("tab")

func _on_GamepadButton_pressed():
	$VBoxContainer/TabContainer.current_tab = 1
	Root.request_sfx("tab")

func _on_SaveButton_pressed():
	var toggle = $VBoxContainer/TabContainer/I18N_GAMEPAD/v/I18N_AB_INV/HBoxContainer/CheckButton.is_pressed()
	var a = InputEventJoypadButton.new()
	a.set_button_index(JOY_DS_A if toggle else JOY_XBOX_A)
	var b = InputEventJoypadButton.new()
	b.set_button_index(JOY_DS_B if toggle else JOY_XBOX_B)
	if InputMap.action_has_event("ui_accept", b):
		InputMap.action_erase_event("ui_accept", b)
		InputMap.action_add_event(  "ui_accept", a)
	if InputMap.action_has_event("ui_cancel", a):
		InputMap.action_erase_event("ui_cancel", a)
		InputMap.action_add_event(  "ui_cancel", b)
	Root.request_sfx("save")
	Root.save_inputs()

func _on_I18N_AB_INV_setting_bool_changed(name, checked):
	Root.request_sfx("on" if checked else "off")
	if name == "I18N_AB_INV":
		Root.config.set_value("config", "ab_inv", checked)


func _on_LoadButton_pressed():
	Root.request_sfx("load")
	self._ready()


func _on_ExitButton_pressed():
	Root.request_sfx("back")
	Root.back_scene()

func human_name(gamepad, index) -> String:
	if gamepad:
		match index:
			JOY_DS_B:
				return TranslationServer.translate("I18N_BTN_DOWN")
			JOY_DS_A:
				return TranslationServer.translate("I18N_BTN_RIGHT")
			JOY_DS_X:
				return TranslationServer.translate("I18N_BTN_UP")
			JOY_DS_Y:
				return TranslationServer.translate("I18N_BTN_LEFT")
			JOY_L:
				return TranslationServer.translate("I18N_BTN_LB")
			JOY_R:
				return TranslationServer.translate("I18N_BTN_RB")
			JOY_L2:
				return TranslationServer.translate("I18N_BTN_LT")
			JOY_R2:
				return TranslationServer.translate("I18N_BTN_RT")
			JOY_L3:
				return TranslationServer.translate("I18N_BTN_LS")
			JOY_R3:
				return TranslationServer.translate("I18N_BTN_RS")
			JOY_SELECT:
				return TranslationServer.translate("I18N_BTN_SELECT")
			JOY_START:
				return TranslationServer.translate("I18N_BTN_START")
			JOY_DPAD_UP:
				return TranslationServer.translate("I18N_DPAD_UP")
			JOY_DPAD_DOWN:
				return TranslationServer.translate("I18N_DPAD_DOWN")
			JOY_DPAD_LEFT:
				return TranslationServer.translate("I18N_DPAD_LEFT")
			JOY_DPAD_RIGHT:
				return TranslationServer.translate("I18N_DPAD_RIGHT")
			_:
				return str(index)
	else:
		print(index)
		match index:
			KEY_ESCAPE:
				return TranslationServer.translate("I18N_KEY_Escape")
			KEY_BACKSPACE:
				return TranslationServer.translate("I18N_KEY_BackSpace")
			KEY_KP_ENTER:
				return TranslationServer.translate("I18N_KEY_KP Enter")
			KEY_LEFT:
				return TranslationServer.translate("I18N_KEY_Left")
			KEY_UP:
				return TranslationServer.translate("I18N_KEY_Up")
			KEY_RIGHT:
				return TranslationServer.translate("I18N_KEY_Right")
			KEY_DOWN:
				return TranslationServer.translate("I18N_KEY_Down")
			KEY_PAGEUP:
				return TranslationServer.translate("I18N_KEY_PageUp")
			KEY_PAGEDOWN:
				return TranslationServer.translate("I18N_KEY_PageDown")
			KEY_CONTROL:
				return TranslationServer.translate("I18N_KEY_Control")
			KEY_META:
				return TranslationServer.translate("I18N_KEY_Meta")
			KEY_CAPSLOCK:
				return TranslationServer.translate("I18N_KEY_CapsLock")
			KEY_NUMLOCK:
				return TranslationServer.translate("I18N_KEY_NumLock")
			KEY_KP_MULTIPLY:
				return TranslationServer.translate("I18N_KEY_Kp Multiply")
			KEY_KP_DIVIDE:
				return TranslationServer.translate("I18N_KEY_Kp Divide")
			KEY_KP_SUBTRACT:
				return TranslationServer.translate("I18N_KEY_Kp Subtract")
			KEY_KP_PERIOD:
				return TranslationServer.translate("I18N_KEY_Kp Period")
			KEY_KP_ADD:
				return TranslationServer.translate("I18N_KEY_Kp Add")
			KEY_KP_0, KEY_KP_1, KEY_KP_2, KEY_KP_3, KEY_KP_4,\
			KEY_KP_5, KEY_KP_6, KEY_KP_7, KEY_KP_8, KEY_KP_9:
				return TranslationServer.translate("I18N_KEY_Kp Number") % str(index - KEY_KP_0)
			KEY_SUPER_L:
				return TranslationServer.translate("I18N_KEY_BackSpace")
			KEY_UNKNOWN:
				return TranslationServer.translate("I18N_KEY_Unknown")
			KEY_SPACE:
				return TranslationServer.translate("I18N_KEY_Space")
			KEY_APOSTROPHE:
				return TranslationServer.translate("I18N_KEY_Apostrophe")
			KEY_PLUS:
				return TranslationServer.translate("I18N_KEY_Plus")
			KEY_COMMA:
				return TranslationServer.translate("I18N_KEY_Comma")
			KEY_MINUS:
				return TranslationServer.translate("I18N_KEY_Minus")
			KEY_PERIOD:
				return TranslationServer.translate("I18N_KEY_Period")
			KEY_SLASH:
				return TranslationServer.translate("I18N_KEY_Slash")
			KEY_SEMICOLON:
				return TranslationServer.translate("I18N_KEY_Semicolon")
			KEY_EQUAL:
				return TranslationServer.translate("I18N_KEY_Equal")
			KEY_BRACELEFT,  KEY_BRACKETLEFT:
				return TranslationServer.translate("I18N_KEY_BraceLeft")
			KEY_BRACERIGHT, KEY_BRACKETRIGHT:
				return TranslationServer.translate("I18N_KEY_BraceRight")
			KEY_BACKSLASH:
				return TranslationServer.translate("I18N_KEY_Backslash")
			KEY_UNKNOWN:
				return TranslationServer.translate("I18N_KEY_Unknown")
			_:
				return OS.get_scancode_string(index)
