extends Node2D
var gameroot

func _ready():
	gameroot = find_parent("GameRoot")

func point_to(coords):
	$ScaledSprite.frame = 0
	position = Vector2(coords[1], gameroot.shown_height - coords[0]) * gameroot.piece_size
