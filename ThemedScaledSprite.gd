extends ScaledSprite

class_name ThemedScaledSprite, "res://sprites/themedscaledsprite.svg"
export var sprite_name = ""
var theme_name = ""

# Called when the node enters the scene tree for the first time.
func _ready():
	if !theme_name:
		set_theme(Root.get_config("custom", "skin_name"))
	if sprite_name:
		set_sprite(sprite_name)

func set_theme_sprite(new_theme, new_sprite):
	set_theme(new_theme)
	set_sprite(new_sprite)

func set_sprite(name):
	sprite_name = name
	var res = load("res://sprites/%s/%s.spriteframes.tres" % [theme_name, name])
	if res:
		frames = res
		animation = "idle"
		.auto_scale()
	else:
		printerr("ThemedScaledSprite: Could not load the resource ", "res://sprites/%s/%s.spriteframes.tres" % [theme_name, name])

func set_theme(new_theme):
	theme_name = new_theme
