extends AnimatedSprite

class_name ScaledSprite, "res://sprites/scaledsprite.svg"

export var ideal_size: Vector2 = Vector2(32, 32)

# Called when the node enters the scene tree for the first time.
func _ready():
	auto_scale()

func set_size(size: Vector2):
	ideal_size = size
	auto_scale()

func set_sprite(name):
	frames = load("res://sprites/Gen3/%s.spriteframes.tres" % name)
	animation = "idle"
	auto_scale()

func auto_scale():
	if frames:
		scale = ideal_size / frames.get_frame(frames.get_animation_names()[0], 0).get_size()
# Called every frame. 'delta' is the elapsed time since the previous frame.
#func _process(delta):
#	pass
