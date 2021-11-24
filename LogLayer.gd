extends CanvasLayer

onready var box = $LogBox
onready var template = $LogBox/LogItem.duplicate()

func _ready():
	$LogBox/LogItem.free()

func show_log(content: String):
	var new_item = template.duplicate()
	box.add_child(new_item)
	var new_content = new_item.get_node("LogContent")
	if is_instance_valid(new_content):
		new_content.set_text(content)
	else:
		pass
	new_item.get_node("Timer").start()
