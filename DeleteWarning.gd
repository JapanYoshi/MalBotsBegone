extends ColorRect

onready var sprite = $ColorRect/Panel/AnimatedSprite
onready var SettingsMenuRoot = get_parent()

func _ready():
	hide()

func show_warning():
	Root.request_sfx("alarm")
	sprite.animation = "default"
	$ColorRect/Panel/Button2.grab_focus()
	show()

func _on_yes():
	Root.request_sfx("on")
	sprite.animation = "yes"
	Root.reset_game()

func _on_no():
	Root.request_sfx("off")
	sprite.animation = "no"

func _on_animation_finished():
	if sprite.animation != "default":
		sprite.animation = "default"
		hide()
		SettingsMenuRoot.element_dict.main.reset[1].grab_focus()
