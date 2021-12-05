extends Node2D
const DEBUG = false

# A GamePiece is a Piece that falls in the game board.
# It is a Block, an Enemy, a Wall, or a Ball.

# The ID this node is registered as in the game_root.
var id = 0

var which = 0

# How many times an Enemy should be attacked to defeat it.
# Set to 0 if not an Enemy.
var count = 0
# Flag for whether the Piece should fall.
var affected_by_gravity = true
# Flag for whether the Piece is currently falling.
# If the block is not affected by gravity, it tracks
# whether or not any piece below it is falling,
# in order to stop checking if the piece below has
# bumped into the bottom of it.
var falling = false
# The current vertical velocity in pixels per second.
var velocity: float = 0.0
# The imagined mass of the object, in no particular unit.
# This is taken in account during collision.
var mass: float = 1.0
# The size of one grid space.
var piece_size = 32 # redundant with GameRoot
# Reference to the Piece directly below it,
# skipping empty spaces. If it has nothing below it,
# it will be a null reference.
var piece_below
# The height the Piece will be at after the fall.
var final_y: float = 0.0
# Whether the Piece should "squish" or not.
# This controls the animation of the sprite
# and how elastic the collision will be.
var squishy = true
# How much the pieces should accelerate.
# Pixels per second per second.
var gravity = 600
# This flag will be reset before every physics calculation,
# and set aftter a collision occurs.
# This aids in the simulation of Pieces "sandwiching"
# between two other Pieces in the same frame.
var just_collided = false
# If the delta is longer than this value,
# then the frame is subdivided, in order to provide
# a more accurate physics simluation.
# In order to prevent lag, the maximum subdivision count
# is set at 5.
# Its reciprocal is stored as "physics_fps" in SYSCON.
var target_delta = 1.0/120.0
# The playfield, the direct parent of every Piece.
var game_root
# The directory that stores all the Sprites.
# Stored as "sprite_root" in SYSCON.
var sprite_root = "res://sprites/"
# The currently selected theme.
# Stored as "custom/skin_name" in Config.
var theme_name = "Gen3"

var disable_particles: bool = false

var emoting: bool = false

# Called when the node enters the scene tree for the first time.
func _ready():
	if Root:
		if "sprite_root" in Root.SYSCON:
			sprite_root = Root.SYSCON.sprite_root
		if "gravity" in Root.SYSCON:
			gravity = Root.SYSCON.gravity
		if "physics_fps" in Root.SYSCON:
			target_delta = 1.0 / Root.SYSCON.physics_fps
		if Root.has_config("custom", "skin_name"):
			theme_name = Root.get_config("custom", "skin_name")
		if Root.has_config("a11y", "disable_particles"):
			disable_particles = Root.get_config("a11y", "disable_particles")
	game_root = find_parent("GameRoot")
	
	if game_root and !disable_particles:
		var part_scale = game_root.theme_scale
		var p = $Particles
		p.process_material.set_param(ParticlesMaterial.PARAM_SCALE, part_scale)
	#$Particles.texture = load(sprite_root + theme + "/P1.texture.tres")
	$Particles.set_z_index(10)

# "sprite_name" stores name of sprite; "count" is 0 for non-Enemies, its HP for Enemies
func set_piece(which_, sprite_name, count_, id_):
#	dp("GamePiece - set_piece(%d, %s, %d, %d)" % [which_, sprite_name, count_, id_])
	which = which_
	# load and init sprite
	$Node/AnimatedSprite.frames = load(
		sprite_root + theme_name + "/" + sprite_name
		+ ".spriteframes.tres"
	)
	$Node/AnimatedSprite.animation = "idle"
	# adjust sprite position and sprite
	$Node/AnimatedSprite.auto_scale()
	$Node/AnimatedSprite.position += Vector2(piece_size, -piece_size) / 2
	if sprite_name == "Wall":
		affected_by_gravity = false
	else:
		affected_by_gravity = true
	# find how much each object is nudged after the collision
	if count_ < 1:
		mass = 4.0
		squishy = false
	else:
		mass = 1.0
		squishy = true
		emoting = true
		_on_IdleTimer_timeout()
		if count_ > 1:
			$Label.text = str(count_)
	count = count_
	id = id_
	init_particles()
	#dp("Piece loaded: ", which, ", ", sprite_name, " * ", count, " with mass ", mass)

func stop_falling():
	falling = false
	position.y = final_y
	game_root.decrement_dropping()

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	if !falling:
		return
	elif !affected_by_gravity:
		# first, check if the object below has settled
		var piece_checking = self
		var piece_to_check = piece_below
		if !piece_to_check:
			stop_falling()
			return
		elif !piece_to_check.falling:
			stop_falling()
			return
		# then recursively check if the block below needs to be nudged away
		while piece_checking:
			#dp("piece checking: ", piece_checking, "; piece to check: ", piece_to_check)
			# check if the block below collides
			if piece_to_check == null:
				# no piece to check. end physics.
				#dp("No piece below")
				return
			elif piece_checking.position.y - piece_to_check.position.y > -piece_size:
				piece_to_check.position.y = piece_checking.position.y + piece_size
				piece_to_check.velocity = 0
				# advance to next block
				piece_checking = piece_to_check
				piece_to_check = piece_checking.piece_below
			else:
				# no need to continue checking
				#dp("Piece below has enough distance")
				return
	assert(affected_by_gravity and falling)
	just_collided = false
	# Reminder: Contrary to board data, DOWN is positive Y.
	# Debug text on the pieces
	#$Label.text = 
	# subdivide frames for accurate physics, but don't subdivide in more than five
	var step_count = max(1, min(ceil(delta / target_delta), 5))
	var sub_delta = min(delta / step_count, target_delta)
	for i in step_count:
		# get the height of the piece below;
		# if none, get the height of the floor + one grid space
		# same with the velocity; if none, get 0 because the floor is stationary
		# same with softness; if none, get false because the floor is hard
		var height_b 	= piece_size
		var velocity_b 	= 0
		var mass_b 		= 5
		var falling_b   = false
		var squishy_b	= false
		var collided_b	= true
		if piece_below != null:
			height_b = 		piece_below.position.y
			velocity_b = 	piece_below.velocity
			mass_b = 		piece_below.mass
			falling_b =		piece_below.falling && piece_below.affected_by_gravity
			squishy_b =		piece_below.squishy
			collided_b =	piece_below.just_collided
		if position.y - height_b > -piece_size:
			# collision happened!
			just_collided = true
			# send current velocity to the root
			game_root.submit_velocity(abs(velocity - velocity_b))
			#print(position.y - final_y, " v", velocity, " vd", velocity * delta)
			if squishy:
				squish()
			if squishy_b:
				piece_below.squish()
			var rebound = 0.2 if squishy else 0.1
			var rebound_b = 0.2 if squishy_b else 0.1
			if !falling_b:
				# other object is stationary
				if position.y - final_y > -1.0 and abs(velocity) < 1 / sub_delta:
					# settle
#					print(id, " in final position! ", velocity * sub_delta, ", ", game_root.gravity / 640.0)
					stop_falling()
					return
				else:
					# don't settle
#					print(id, " collided with stationary object at speed ", velocity)
					velocity = -velocity * min(0.5, mass / mass_b * (rebound + rebound_b))
					assert(velocity < 0)
					position.y = height_b - piece_size + velocity * sub_delta - 0.5
			else:
				# other object is moving
				# https://www.varsitytutors.com/ap_physics_c_mechanics-help/understanding-elastic-and-inelastic-collisions
#				print(id, " collided with moving object at speed ", velocity)
				var vf_2 = (2 * mass   * velocity   + (mass_b - mass) * velocity_b) / (mass + mass_b)
				var vf_1 = (2 * mass_b * velocity_b + (mass - mass_b) * velocity  ) / (mass_b + mass)
				var v_1  = rebound   * vf_1 + (1 - rebound  ) * velocity
				var v_2  = rebound_b * vf_2 + (1 - rebound_b) * velocity_b
#				dp("vf_1=", vf_1, ",vf_2=", vf_2, ",v_1=",  v_1, ",v_2=",  v_2)
				if piece_below.falling:
					if collided_b:
#						dp("Piece below is sandwiched")
						position.y = height_b - piece_size + min(0.0, v_1) * sub_delta - 1.0
						velocity = velocity_b + rebound * vf_1
						piece_below.velocity = (velocity_b + v_2) / 2.0
					else:
#						dp("Piece below is mid-air")
						position.y = height_b - piece_size + v_1 * sub_delta
						velocity = v_1
						piece_below.velocity = v_2
				else:
					position.y = final_y
				# clamp maximum speed
				velocity = max(-0.5 * game_root.gravity, velocity)
		else:
			# no collision
			velocity += game_root.gravity * sub_delta
			position.y += velocity * sub_delta

func drop(new_piece_below, new_final_y):
	#dp("Piece below is ", new_piece_below)
	piece_below = new_piece_below
	if !falling:
		game_root.now_falling += 1
		falling = true
	final_y = new_final_y
	velocity = 0

func squish():
	$Tween.stop($Node, "scale")
	$Tween.interpolate_property(
		$Node, "scale",
		Vector2(1, max(0.5, 1 - velocity * 0.001)), Vector2(1, 1),
		0.25, # duration
		Tween.TRANS_CUBIC,
		Tween.EASE_IN
	)
	$Tween.start()

func damage(strength: int = 1):
	if count > strength:
		# give damage
		count -= strength
		if count == 1:
			$Label.text = ""
		else:
			$Label.text = str(count)
	else:
		# HP ran out!
		$Label.hide()
		$Tween.interpolate_property(
			$Node/AnimatedSprite, "scale",
			$Node/AnimatedSprite.scale, $Node/AnimatedSprite.scale * 1.25,
			0.25, # duration
			Tween.TRANS_CUBIC,
			Tween.EASE_OUT
		)
		$Tween.start()
		# pop
		count = -1
		var anims = $Node/AnimatedSprite.frames.get_animation_names()
		if "pop" in anims:
			$Node/AnimatedSprite.animation = "pop"
		elif "glow" in anims:
			$Node/AnimatedSprite.animation = "glow"
		else:
			assert(true, "Wait, you don't have a pop or glow animation?")
		game_root.find_node("PopTimer").connect("timeout", self, "_on_PopTimer_timeout")

func init_particles():
	var particles = $Particles
	if disable_particles:
		particles.queue_free()
	else:
		var color = (0 if (which == 0 or which == 6 or which == 7) else which % 8)
		particles.texture = load(Root.SYSCON.sprite_root + theme_name + "/Dots.spriteframes.tres").get_frame("default", color)
		#particles.scale = $Node/AnimatedSprite.scale
		var free_timer = particles.find_node("FreeTimer")
		free_timer.wait_time = particles.lifetime
		free_timer.connect("timeout", particles, "queue_free")

func _on_PopTimer_timeout():
	#print(self, " called _on_PopTimer_timeout()")
	var particles = $Particles
	if particles:
		$Particles/FreeTimer.start()
		var pos = particles.get_global_transform_with_canvas().get_origin()
		particles.restart()
		remove_child(particles)
		game_root.get_parent().add_child(particles)
		particles.position = pos
	$Node.hide()
	$Label.hide()
	game_root.free_me(id)
	queue_free()

func shove_free(object, key):
	print(object, key)
	self.queue_free()
	pass # Replace with function body.

func joy():
	$Node/AnimatedSprite.play("joy")

func _on_IdleTimer_timeout():
	if emoting:
		emoting = false
		dp("GamePiece - Piece %d, which is a %d, stopped emoting." % [id, which])
		$Node/AnimatedSprite.stop()
		$Node/AnimatedSprite.frame = 0
		$IdleTimer.wait_time = game_root.decorative_rng.randf_range(10.0, 50.0)
	else:
		emoting = true
		dp("GamePiece - Piece %d, which is a %d, started emoting." % [id, which])
		$Node/AnimatedSprite.play("idle")
		$IdleTimer.wait_time = 2.0
	$IdleTimer.start()


func _on_Tween_tween_completed(object, key):
	if key == ":position":
		pass#breakpoint

func dp(content: String):
	if DEBUG:
		print(content)
