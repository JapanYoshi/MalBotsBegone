extends Control

# Animated logo for hai!touch Studios.
onready var ap: AnimationPlayer = $AnimationPlayer

# Called when the node enters the scene tree for the first time.
func _ready():
	print("SplashScreen ready")
	Root.sound_handler.load_bgm("splash")
	Root.preload_sfx("cursor")
	Root.preload_sfx("decide")
	Root.preload_sfx("back")
	resize()

# Called when the window is initialized.
# It overrides the default scaling behavior based on 360x640px.
func resize():
	var viewport = self.get_tree().get_root().get_visible_rect().size
	var scale = min(viewport.x, viewport.y) / 1080
	set_scale(Vector2(scale, scale))

# Called when the logo is finished animating.
# Also called when the user skips the logo.
func _on_AnimationPlayer_animation_finished(_anim_name):
	Root.request_bgm_stop()
	Root.unload_bgm("splash")
	self.queue_free()
	# if this is the first time running this game, show first time setup screen
	if Root.get_config("config", "setup_done", false):
		Root.reset_scene()
	else:
		Root.change_scene("FirstTime")

# Called after a short delay after the scene is loaded.
func _on_Timer_timeout():
	ap.play("AnimatedLogo")
	ap.advance(0)
	Root.request_bgm("splash")

# Called when the user skips the logo.
func skip():
	ap.stop(true)
	_on_AnimationPlayer_animation_finished("AnimatedLogo")

func _input(event):
	if "pressed" in event and event.pressed:
		if Input.is_action_pressed("ui_accept"):
			skip()
			accept_event()
		elif event is InputEventMouseButton:
			if event.button_index == BUTTON_LEFT:
				skip()
				accept_event()
