extends ColorRect
var loaded = false
# Called when the node enters the scene tree for the first time.
func _ready():
	loaded = true

func _process(delta):
	if loaded:
		Root.back_scene()
