extends Node2D

export var spritesheet: StreamTexture
export var direction: int = 0
export var frame_of_walk: int = 1
var animating: bool = false
var direction_after: int = 0

# Called when the node enters the scene tree for the first time.
func _ready():
	$Sprite.texture = spritesheet
	_set_sprite_frame()

func turn(margin: int):
	match margin:
		MARGIN_BOTTOM:
			direction = 0
		MARGIN_LEFT:
			direction = 1
		MARGIN_RIGHT:
			direction = 2
		_:
			direction = 3

func walk(value: bool):
	if value:
		$AnimationPlayer.play("walk")
		animating = true
	else:
		$AnimationPlayer.stop()
		frame_of_walk = 1
		animating = false
		_set_sprite_frame()

func spin(value: bool, speed: float, decay: float = 0, margin_after: int = 0):
	frame_of_walk = 1
	if value:
		$AnimationPlayer.play("spin", -1, abs(speed), speed < 0.0)
		if decay > 0:
			$Tween.interpolate_property($AnimationPlayer, "playback_speed", abs(speed), abs(speed) / 108.0, decay, Tween.TRANS_CUBIC, Tween.EASE_OUT)
			direction_after = margin_after
			$Tween.start()
		animating = true
	else:
		$AnimationPlayer.stop()
		animating = false
		_set_sprite_frame()

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	if !animating: return
	_set_sprite_frame()

func _set_sprite_frame():
	$Sprite.frame = direction * 3 + frame_of_walk

func _on_Tween_tween_completed(object, key):
	if key == ":playback_speed":
		$AnimationPlayer.stop()
		turn(direction_after)
		animating = false
	_set_sprite_frame()
