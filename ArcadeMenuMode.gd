extends PanelContainer

func _ready():
	connect("focus_entered", self, "focus_entered")

func focus_entered():
	$VBoxContainer/Button.grab_focus();
