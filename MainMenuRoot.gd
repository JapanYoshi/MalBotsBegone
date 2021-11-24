extends Control

# The main menu of the game.
var enable_input: bool = false

# Whether or not the player has "pressed A to start".
var buttons_shown: bool = false
# Stores the initial position of the button container,
# in order to tween it back there.
var cache_position

# The list of on-screen menu buttons,
# used when a key is pressed, to determine when nothing has focus.
var list_of_buttons

signal ready_finished

func _ready():
	buttons_shown = false
	($MainContainer/ButtonsContainer as Control).mouse_filter = Control.MOUSE_FILTER_PASS
	# set up child elements
	# Automatic text localization doesn't do fuzzy matching.
	($MainContainer/RichTextLabel as RichTextLabel).set_bbcode(
		"[center][wave amp=32 freq=5]" +
		tr("I18N_START") +
		"[/wave][/center]"
	)
	# Save the initial position of the button box.
	cache_position = ($MainContainer/ButtonsContainer as Control).get_rect().position
	# Move it way out of the screen.
	($MainContainer/ButtonsContainer as Control).set_position(Vector2(-99999, -99999))
	# Just in case, stop it from accepting any mouse inputs.
	($MainContainer/ButtonsContainer as Control).mouse_filter = Control.MOUSE_FILTER_PASS
	# Store the list of menu buttons.
	list_of_buttons = [
		$MainContainer/ButtonsContainer/ButtonsVBox/StoryButton,
		$MainContainer/ButtonsContainer/ButtonsVBox/ArcadeButton,
		$MainContainer/ButtonsContainer/ButtonsVBox/TuteButton,
		$MainContainer/ButtonsContainer/ButtonsVBox/EditorButton,
		$MainContainer/ButtonsContainer/ButtonsVBox/ButtonsHBox/InfoButton,
		$MainContainer/ButtonsContainer/ButtonsVBox/ButtonsHBox/SettingsButton,
		$MainContainer/ButtonsContainer/ButtonsVBox/ButtonsHBox/ReviewButton
	]
	Root.request_bgm("title")
	if load("res://GameModeHandler.gd") == null:
		printerr("load error")
	emit_signal("ready_finished")

func _input(event):
	if !enable_input:
		return
	# Accept event
	if event.is_action_pressed("ui_accept") or\
		(event is InputEventMouseButton and
		 event.button_index == BUTTON_LEFT and
		 event.pressed) or\
		(event is InputEventScreenTouch and
		 event.pressed):
		# If buttons aren't shown yet, show them
		if !buttons_shown:
			buttons_shown = true
			accept_event()
			($Timer as Timer).start()
			Root.request_sfx("decide")
			# If triggered from keyboard or gamepad,
			# autofocus the first button
			if event.is_action_pressed("ui_accept"):
				($MainContainer/ButtonsContainer/ButtonsVBox/StoryButton as Control).grab_focus()
		# Otherwise, let the buttons' input handlers handle it
	# Move cursor from gamepad or keyboard
	elif event.is_action_pressed("ui_focus_next") or\
		  event.is_action_pressed("ui_focus_prev") or\
		  event.is_action_pressed("ui_up") or\
		  event.is_action_pressed("ui_down") or\
		  event.is_action_pressed("ui_left") or\
		  event.is_action_pressed("ui_right"):
		# If nothing is focused, autofocus the first button
		if _no_focus():
			($MainContainer/ButtonsContainer/ButtonsVBox/StoryButton as Control).grab_focus()
		Root.request_sfx("cursor")

# Returns true when any menu button has focus,
# and returns false otherwise.
func _no_focus() -> bool:
	for btn in list_of_buttons:
		if btn.has_focus():
			return false
	return true

# Shows the menu buttons, and hides the text that says "Press A to start".
func show():
	($MainContainer/RichTextLabel as Control).hide()
	($MainContainer/ButtonsContainer as Control).set_position(Vector2(0, 0))
	self.set_default_cursor_shape(CURSOR_ARROW)
	($MainContainer/ButtonsContainer as Control).mouse_filter = Control.MOUSE_FILTER_STOP
	($ButtonAnimator as AnimationPlayer).play("appear")

# Fires when the "Story mode" button is pressed.
func _on_StoryButton_pressed():
	Root.request_sfx("decide")
	Root.show_message("I18N_MODE_NOT_DONE", 0)

# Fires when the "Arcade mode" button is pressed.
func _on_ArcadeButton_pressed():
	Root.request_sfx("decide")	
	Root.change_scene("ArcadeMenu")

# Fires when the "Level editor" button is pressed.
func _on_EditorButton_pressed():
	Root.request_sfx("decide")
	Root.request_bgm_stop()
	Root.change_scene("EditMode")

# Fires when the "i" button is pressed.
func _on_InfoButton_pressed():
	Root.request_sfx("decide")
	$SocialModal.show_message()

# Fires when the Gear button is pressed.
func _on_SettingsButton_pressed():
	Root.request_sfx("decide")
	Root.change_scene("SettingsMenuRoot")

# Fires when the Heart button is pressed.
func _on_ReviewButton_pressed():
	Root.request_sfx("decide")
	Root.show_message("Thank you for playing! <3")

func _on_TuteButton_pressed():
	Root.change_scene("World0")
