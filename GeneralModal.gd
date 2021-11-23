extends CanvasLayer
var active = false
# Called when the node enters the scene tree for the first time.
func _ready():
	print("GeneralModal is getting ready")
	$Backdrop.hide()
	pass # Replace with function body.

func show_message(message, title = ""):
	$Backdrop.show()
	$Backdrop/ColorRect/NinePatchRect/VBoxContainer/Title.set_text(TranslationServer.translate(title))
	$Backdrop/ColorRect/NinePatchRect/VBoxContainer/Body.set_text(TranslationServer.translate(message))
	($Backdrop/ColorRect/NinePatchRect/VBoxContainer/OKButton as Control).grab_focus()
	active = true

func _on_ResumeButton_pressed():
	($Backdrop as Control).hide()
	active = false
