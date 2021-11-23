extends HBoxContainer

func _ready():
	# stringify it bc eval can't return HTMLElements
	var a = JavaScript.eval("String(document)", true)
	if "Null" == a:
		hide()

func _on_Button_pressed():
	JavaScript.eval("""
document.documentElement.requestFullscreen(
	{ navigationUI: 'hide' }
)
	""", true);
	accept_event()
