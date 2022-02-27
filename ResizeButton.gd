extends Button
export var resize_x: bool = false
export var resize_y: bool = true
var margins: Array
var child: Control
var default_min: Vector2

func _ready():
	default_min = rect_min_size
	child = get_child(0)
	margins = [
		child.margin_top,
		child.margin_right,
		child.margin_bottom,
		child.margin_left
	]
	for c in child.get_children():
		if c is Control:
			c.connect("resized", self, "_adjust_size")
	_adjust_size()

func _adjust_size():
	if resize_x:
		rect_min_size.x = max(default_min.x, child.rect_size.x + margins[3] - margins[1])
	if resize_y:
		rect_min_size.y = max(default_min.y, child.rect_size.y + margins[0] - margins[2])
	print(name, "._adjust_size() ", child.rect_size, "->", rect_size)
