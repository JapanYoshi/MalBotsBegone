extends Button
export var resize_x: bool = false
export var resize_y: bool = true
var margins: Array
var text_node: Label
var default_min: Vector2

func _ready():
	default_min = rect_min_size
	text_node = get_child(0).get_child(0)
	margins = [
		get_child(0).margin_top,
		get_child(0).margin_right,
		get_child(0).margin_bottom,
		get_child(0).margin_left
	]
	text_node.connect("resized", self, "_adjust_size")
	_adjust_size()

func _adjust_size():
	if resize_x:
		rect_min_size.x = max(default_min.x, text_node.rect_size.x + margins[3] - margins[1])
	if resize_y:
		rect_min_size.y = max(default_min.y, text_node.rect_size.y + margins[0] - margins[2])
	print(name, "._adjust_size() ", text_node.rect_size, "->", rect_size)
