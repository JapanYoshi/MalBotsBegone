extends Node2D
# A Domino is a pair of blocks, which the player controls.
# NEXT queue indicators should also be Dominoes.

# The parent element.
var game_root
# Flag that sets whether or not the piece is falling.
var active = false
# The direction uses quarter-turns as the unit, not radians.
var final_direction: float = 0.0 # Controls the animation.
var direction: int = 0           # Theoretical rotation.
								 # Clamped from 0 to 3 inclusive.

var vertical_position_cache: float = 0.0

# The GameDomino shifts the piece visual upward relative to the
# actual grid-wise position, to create the illusion of gradual descent.
# This variable deals with how much the piece should be shifted upward.
var subgrid_timer: float = 0.0
# How much of a grid-space the piece should descend PER SECOND.
var subgrid_speed: float = 1.0
# If the player is pressing Down, this should be true.
var fast_drop: bool = false
# How long the piece has touched the ground.
var stall_timer: float = 0.0

const tween_duration = 0.4

var id_0: int = 0; var id_1: int = 0

# Called when the node enters the scene tree for the first time.
func _ready():
	position = Vector2(20, 232)
	direction = 1
	final_direction = 1.0

func set_visual():
	game_root = find_parent("GameRoot")
	if !id_0:
		$VertTweener/BlockBox/BlockCenter.hide()
		$VertTweener/BlockBox/BlockOuter.hide()
		return
	$VertTweener/BlockBox/BlockCenter.frames = load(
		Root.SYSCON.sprite_root + game_root.theme_name + "/Block%1d.spriteframes.tres" % id_0
	)
	$VertTweener/BlockBox/BlockOuter.frames = load(
		Root.SYSCON.sprite_root + game_root.theme_name + "/Block%1d.spriteframes.tres" % id_1
	)
	$VertTweener/BlockBox/BlockCenter.auto_scale()
	$VertTweener/BlockBox/BlockOuter.auto_scale()

# Rotates the piece. Changes the visuals AND theoretical rotation.
# NOTE: Wall and floor kicks should be dealt with by the parent element!
# Named `rot()` because `rotate()` was taken.
func rot(times: int) -> void:
	final_direction = fmod(final_direction + times, 4.0)
	direction = posmod(direction + times, 4)
	print("Domino: Rotating %d times to final direction %f." % [times, final_direction])
	rot_interpolate()

# Absolute version of rot().
func set_rot(new_rot: int, instant: bool = false) -> void:
	final_direction = new_rot
	direction = new_rot
	print("Domino: Rotating automatically to final direction %f." % [final_direction])
	if !instant:
		rot_interpolate()
	else:
		$Tween.stop_all()
		var final_rad = final_direction * PI / 2
		$VertTweener/BlockBox.rotation = final_rad
		$VertTweener/BlockBox/BlockCenter.rotation = -final_rad
		$VertTweener/BlockBox/BlockOuter.rotation = -final_rad

func rot_interpolate():
	var final_rad = final_direction * PI / 2
	var current_rad = $VertTweener/BlockBox.rotation
	if current_rad - final_rad > PI:
		current_rad -= 2 * PI
	elif current_rad - final_rad < -PI:
		current_rad += 2 * PI
	$Tween.stop_all()
	$Tween.interpolate_property(
		$VertTweener/BlockBox, "rotation",
		current_rad, final_rad,  tween_duration / subgrid_speed,
		Tween.TRANS_QUART, Tween.EASE_OUT
	)
	$Tween.interpolate_property(
		$VertTweener/BlockBox/BlockCenter, "rotation",
		-current_rad, -final_rad,  tween_duration / subgrid_speed,
		Tween.TRANS_QUART, Tween.EASE_OUT
	)
	$Tween.interpolate_property(
		$VertTweener/BlockBox/BlockOuter, "rotation",
		-current_rad, -final_rad,  tween_duration / subgrid_speed,
		Tween.TRANS_QUART, Tween.EASE_OUT
	)
	$Tween.start()

func move_right_up(right: int, up: int) -> void:
	# what is the point of this function
	interpolate_position()

func floor_kick() -> void:
	vertical_position_cache = $VertTweener/BlockBox.get_transform().origin.y
	print("Domino will snap vertically to grid space.")
	subgrid_timer = 0.0

func graze_ceiling() -> void:
	vertical_position_cache = $VertTweener/BlockBox.get_transform().origin.y
	print("Domino grazed ceiling")
	subgrid_timer = 0.0

func _process(delta):
	if !game_root.input_allowed:
		return
	if !active:
		$VertTweener/BlockBox.position.y = 0
	else:
		#### DEBUG START
		# TEST ONLY:
		# $HitBox contains placeholder graphics that show the true hitbox
		# of the Domino. This moves the outer block to its intended position.
		match direction:
			0:
				$HitBox/BlockOuter.position = Vector2(0, -game_root.piece_size)
			1:
				$HitBox/BlockOuter.position = Vector2(game_root.piece_size, 0)
			2:
				$HitBox/BlockOuter.position = Vector2(0, game_root.piece_size)
			3:
				$HitBox/BlockOuter.position = Vector2(-game_root.piece_size, 0)
		# TEST ONLY:
		# Update $Label's text with the appropriate debug text.
		#$Label.text = "V%1.3f\nL%1.3f\nD%1d R%1.2f" % [subgrid_timer, stall_timer, direction,  $VertTweener/BlockBox.rotation / PI * 2]
		#### DEBUG END
		subgrid_timer -= delta * (min(subgrid_speed * 8, 40) if fast_drop else subgrid_speed)
		# Try to move the piece down if the subgrid timer is below 0
		if subgrid_timer <= 0.0:
			while subgrid_timer <= 0.0:
				if game_root and !game_root.domino_may_descend():
					#print("Domino on floor: Subgrid=%0.3f; Lock=%0.3f" % [subgrid_timer, stall_timer])
					stall_timer += delta * (8 if fast_drop else 1)
					subgrid_timer = 0.0
					$VertTweener/BlockBox.position.y = 0.0
					if stall_timer >= 3.0:
						# time's up, lock the piece
						game_root.lock_domino()
					return
				else:
					# Move the piece down
					#print("Domino not on floor; moving Domino down one grid space")
					subgrid_timer += 1.0
					game_root.moving_domino_y -= 1
					$VertTweener/BlockBox.position.y = subgrid_timer * -game_root.piece_size
		else:
			# Domino is DEFINITELY still in the air
			$VertTweener/BlockBox.position.y = subgrid_timer * -game_root.piece_size
		# After all that stuff is updated, pass back the final vertical position to the main root
		position.y = -16 + (-game_root.piece_size * game_root.moving_domino_y)

	pass

# If a GameDomino is active, it is falling.
# If a GameDomino is inactive, it is not falling.
func set_active(val):
	if active == val:
		return
	active = val
	if active:
		print("Domino has been activated")
		subgrid_timer = 1
		stall_timer = 0
		fast_drop = false
		$VertTweener/BlockBox/BlockCenter.animation = "glow"
	else:
		subgrid_timer = 0
		$VertTweener/BlockBox/BlockCenter.animation = "idle"

func interpolate_position():
	$TweenPos.stop_all()
	$TweenPos.interpolate_property(
		self, "position",
		null, Vector2(16 + game_root.moving_domino_x * 32, -16 + game_root.moving_domino_y * -32), tween_duration / subgrid_speed,
		Tween.TRANS_QUART, Tween.EASE_OUT
	)
	if vertical_position_cache:
		$TweenPos.interpolate_property(
			$VertTweener, "position",
			Vector2(0, vertical_position_cache), Vector2(0, 0), tween_duration / subgrid_speed,
			Tween.TRANS_QUART, Tween.EASE_OUT
		)
		vertical_position_cache = 0.0
	$TweenPos.start()

func _on_Tween_tween_completed(object, key):
	#print("GameDomino - Tween completed: %s.%s" % [object.name, key])
	pass

func _debug_label(content: String):
	$Label.set_text(content)
