extends Area2D

# The WalkingEnemyRoot (the Playground).
var playground
# Toggles every time the movement changes.
# If walking = false, the enemy's speed tends to 0.
# If walking = true, the enemy's speed increases.
var walking = false
# The fastest speed each enemy can walk.
export var max_speed = 50.0
# The current speed the enemy is walking.
# This will be changed by the Tween.
var speed = 0.0
# The speed the enemy tends to.
var speed_target
# The current direction in radians the enemy is facing.
# This will be changed by the Tween.
var direction = 0.0
# The direction the enemy tends to.
var direction_target
# Each enemy will wait between 10% and 100% of this length
# before changing its movement.
export var max_wait_time = 2.0
# This flag is updated when the enemy leaves or enters the playground.
# When the enemy is outside the playground, it will try to
# return to the center of the playground.
var oob = false
# The parent containing the RNG.
var rt

onready var tss: ThemedScaledSprite = $AnimatedSprite
onready var twn: Tween = $Tween

func _ready():
	if rt:
		change_movement()

func initialize(new_root):
	print("WalkingEnemy ready")
	playground = get_parent()
	rt = new_root
	print("WalkingEnemy found parent")	
	direction = rt.rng.randf_range(0, PI * 2)
	change_movement()

func set_sprite(index: int):
	tss.set_sprite("V%d" % index)
	
func change_skin(skin, _index):
	# Load AnimatedSprite
	tss.set_theme(skin)

func _process(delta):
	# Move one step in the current direction and speed
	position += Vector2(cos(direction), sin(direction)) * speed * delta
	# Change the animation depending on how fast it's moving
	if speed < 8:
		if tss.animation == "idle":
			tss.animation = "joy"
	else:
		if tss.animation == "joy":
			tss.animation = "idle"

func change_movement():
	if !get_tree(): return;
	# Commit the current speed and direction
# warning-ignore:return_value_discarded
	twn.stop_all()
	# Generate how long to wait until changing the movement again
	var duration = rt.rng.randf_range(0.1 * max_wait_time, max_wait_time)
	# Normalize direction between 0 and 2π rad
	direction = fmod(direction + PI * 2, PI * 2);
	if !walking:
		# Change direciton
		if oob:
			# Get which way to face, as a Vector2
			var vector_to_center = -self.position # already relative to playground
			# Get which way to face, as a bearing in radians
			direction_target = vector_to_center.angle()
			# Make sure we don't turn more than π rad (180°) at once
			if (direction - direction_target > PI):
				direction_target += 2 * PI
			elif (direction - direction_target < -PI):
				direction_target -= 2 * PI
		else:
			# Generate a new direction, within ±0.5π rad (== ±90°)
			# of the current direction
			direction_target = direction + (rt.rng.randf() - 0.5) * 0.5 * PI
		# Generate the new speed to accelerate towards
		speed_target = rt.rng.randf_range(max_speed * 0.5, max_speed)
	else:
		# Slow down to a stop
		speed_target = 0
	# Tween the direction and speed
# warning-ignore:return_value_discarded
	twn.interpolate_property(
		self,
		"direction",
		direction,
		direction_target,
		duration,
		Tween.TRANS_LINEAR,
		Tween.EASE_IN
	)
# warning-ignore:return_value_discarded
	twn.interpolate_property(
		self,
		"speed",
		speed,
		speed_target,
		duration * 0.5, # Let the enemy travel at a constant speed for the last half of its movement
		Tween.TRANS_LINEAR,
		Tween.EASE_IN
	)
	# Start the tweens
# warning-ignore:return_value_discarded
	twn.start()
	# Update the `walking` flag
	walking = !walking
	# Set timer until next movement change
# warning-ignore:unsafe_property_access
	($ChangeMovementTimer as Timer).wait_time = duration
	($ChangeMovementTimer as Timer).start()

# Fires when the enemy exits the Playground.
func _on_WalkingEnemy_area_exited(area):
	# The enemy exited SOMETHING. Is it the Playground?
	if area == playground:
		# Yes it is! Set out-of-bounds flag
		oob = true
		# Stop the timer and course-correct immediately
		($ChangeMovementTimer as Timer).stop()
		change_movement()

# Fires when the enemy re-enters the playground,
# or when the enemy collides with another enemy.
func _on_WalkingEnemy_area_entered(area):
	# The enemy entered SOMETHING. Is it the Playground or an Enemy?
	if area == playground:
		# It's the Playground! Turn off out-of-bounds flag
		oob = false
	elif area.find_node("EnemyCollision"):
		# It's another Enemy! Stop tweening speed and direction.
# warning-ignore:return_value_discarded
		twn.stop_all()
		# Calculate the vector between our positions,
		# a.k.a. the normal vector
		var vector_avoid = (self.position - area.position).normalized()
		# Calculate the vector I'm heading right now
		var vector_current = Vector2(1, 0).rotated(direction)
		# Calculate which way to head in order to avoid the other Enemy
		# which is a weighted average of the current vector and
		# the normal vector
		var vector_new = vector_current * 0.6 + vector_avoid * 0.8
		direction = vector_new.angle()
		# A very short Tween, in order to swap the parameters without
		# clobbering my speed/direction or the other's.
		if "speed" in area:
# warning-ignore:return_value_discarded
			twn.interpolate_property(
				self,
				"speed",
				speed,
				area.speed,
				0.01
			)
# warning-ignore:return_value_discarded
			twn.start()
