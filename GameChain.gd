extends Node2D


# Declare member variables here. Examples:
# var a = 2
# var b = "text"


# Called when the node enters the scene tree for the first time.
func _ready():
	$Viewport/VBoxContainer/before.text = na(TranslationServer.translate("I18N_CHAIN_BEFORE"))
	$Viewport/VBoxContainer/after.text = na(TranslationServer.translate("I18N_CHAIN_AFTER"))

func set_number(number: int):
	hide()
	$Viewport/VBoxContainer/number.text = "%02d" % number

func na(text):
	if text == "N/A":
		return ""
	return text

func pop_up():
	show()
	$AnimationPlayer.play("show")

func pop_out():
	$AnimationPlayer.play("hide")
