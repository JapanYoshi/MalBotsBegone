extends Node2D

# The RNG that its children use.
var rng

# Called when the node enters the scene tree for the first time.
func _ready():
	print("WalkingEnemyRoot Enter Tree")
	rng = RandomNumberGenerator.new()
	print("WalkingEnemyRoot RNG initiated")
	rng.randomize()
	
	print("WalkingEnemyRoot Ready")
	
	var children = $EnemyPlayground.get_children()
	var i = 0
	for child in children:
		if child is Area2D:
			child.initialize(self)
			child.set_sprite(i)
			i += 1
