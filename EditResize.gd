extends Control

func _input(event):
	if !visible:
		return

func _ready():
	for child in get_children():
		if child.name != "EditMain":
			child.hide()
		else:
			child.show()
