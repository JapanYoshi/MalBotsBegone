extends Popup

var label
var cancel
var menu
var action
var listening
var last_time = 0
var last_index
var gamepad

# Called when the node enters the scene tree for the first time.
func _ready():
	label = $DarkBG/NinePatchRect/ColorRect/VBoxContainer/Press
	cancel = $DarkBG/NinePatchRect/ColorRect/VBoxContainer/Cancel
	menu = find_parent("KeyConfig")

func _input(event):
	if !listening:
		return
	accept_event()
	if !((!gamepad and event is InputEventKey) or (gamepad and event is InputEventJoypadButton)):
		return
	if event.is_action("ui_cancel") and event.is_echo():
		if last_time + 1000 < OS.get_system_time_msecs():
			print("Remap cancelled.")
			listening = false
			self.hide()
		# else do nothing
		return
	if !event.is_pressed():
		return
	# we've filtered the events we don't want
	var index
	if gamepad:
		index = event.get_button_index()
	else:
		index = event.get_scancode()
	print("Popup ", index)
	if index == last_index:
		print("Remap confirmed! ", gamepad, " ", action, " ", event)
		menu.apply(gamepad, action, event)
		listening = false
		hide()
	else:
		last_index = index
		label.text = TranslationServer.translate("I18N_AGAIN_" + ("BUTTON" if gamepad else "KEY"))
		label.text = label.text % menu.human_name(gamepad, index)
		last_time = OS.get_system_time_msecs()

func activate(gamepad_, action_):
	print("Activate: ", gamepad_, " ", action_)
	gamepad = gamepad_
	action = action_
	label.text = TranslationServer.translate("I18N_PRESS_" + ("BUTTON" if gamepad else "KEY"))
	label.text = label.text % TranslationServer.translate(action)
	cancel.text = TranslationServer.translate("I18N_CANCEL_" + ("BUTTON" if gamepad else "KEY"))
	listening = true
	popup()

func _on_TextureButton_pressed():
	self.hide()
