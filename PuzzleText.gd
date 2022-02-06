extends Node2D
onready var panel: PanelContainer = $PanelContainer
onready var max_size = panel.rect_size
onready var scroll: ScrollContainer = $PanelContainer/ScrollContainer
onready var label: RichTextLabel = $PanelContainer/ScrollContainer/RichTextLabel
var scroll_height: float = 0
var auto_scroll: bool = false
const SCROLL_MARGIN: float = 40.0
var scroll_speed: float = 30.0
var scroll_distance: float = -SCROLL_MARGIN

#func _ready():
#	# testing
#	set_bbcode("aoeusah,s. sha,u scru hah.,r scrhahcr ,.s rhu.")

func set_bbcode(text):
	label.set_bbcode(TranslationServer.translate(text))
	label.set_size(Vector2.ZERO) # set to minimum allowable size
	panel.set_size(max_size)
	yield(get_tree(), "idle_frame")
#	print("label.rect_size.y=",label.rect_size.y,", scroll.rect_size.y=",scroll.rect_size.y)
	scroll_height = label.rect_size.y - scroll.rect_size.y
	auto_scroll = scroll_height > 0
	if auto_scroll:
		scroll_distance = -SCROLL_MARGIN
	else:
		scroll.rect_size.y = label.rect_size.y
		panel.rect_size.y = label.rect_size.y + (2 * 16)
		pass

func _process(delta):
	if auto_scroll:
		scroll_distance += delta * scroll_speed
		if scroll_distance >= scroll_height + SCROLL_MARGIN:
			scroll_distance = -SCROLL_MARGIN
		scroll.scroll_vertical = scroll_distance
