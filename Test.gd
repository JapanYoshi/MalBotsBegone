extends VBoxContainer

var piece_preview = preload("res://EditPiece.tscn")
var rng = RandomNumberGenerator.new()

	
func _on_Button_pressed():	
	rng.randomize()
	var enemy_health = $HBoxContainer/SpinBox.value
	var enemy_color_expected = $HBoxContainer2/SpinBox.value
	var rows = $HBoxContainer4/SpinBox.value
	var enemy_bitmask = 0
	for child in $GridContainer.get_children():
		child.free()
	var i = 1
	for child in $HBoxContainer3.get_children():
		if child is Button:
			if child.pressed:
				enemy_bitmask ^= 1 << i
			i += 1
	var result = generate_enemy_row(enemy_health, enemy_color_expected, enemy_bitmask, rows)
	var avg_health: float = 0
	var avg_color: float = 0
	for j in range(len(result)):
		print("Piece %d is %d" % [j, result[j]])
		var new_piece = piece_preview.instance()
		new_piece.set_piece(result[j] % 8 + 8, result[j] / 8)
		$GridContainer.add_child(new_piece)
		if result[j] % 8:
			avg_color += 1
		avg_health += result[j] / 8
	avg_health /= len(result)
	avg_color /= len(result)
	$stats.text = "Average health:\n%0.3f\nRatio of colored enemies:\n%0.3f" % [avg_health, avg_color]

func generate_enemy_row(average_enemy_health, enemy_color_ratio, enemy_color_mask, rows = 1):
	var time = OS.get_system_time_msecs()
	if enemy_color_ratio > 0 and enemy_color_mask == 0:
		printerr("Can't generate colored enemies with no allowed colors!")
		enemy_color_ratio = 0.0
	# Output is stored here.
	# It will be rows * 7 items long, matching the 7 columns per row.
	var row = PoolByteArray()
	var pieces = 7 * rows
	
	## First, convert the bit mask into an array of allowed colors,
	## for easy processing later.
	# An array of integers standing for an allowed color, from 1 to 5 inclusive.
	var colors = PoolByteArray()
	for i in range(1, 6):
		if (enemy_color_mask >> i) & 1:
			colors.push_back(i)
	
	## Each enemy will be either gray or a random allowed color,
	## at a ratio approximating enemy_color_ratio.
	# Expected value for how many enemies will NOT be gray.
	var expected_color = enemy_color_ratio * pieces
	
	## Each enemy will have either floor or ceil average_enemy_health,
	## at a ratio approximating the decimal portion of it.
	# Baseline for enemies' health.
	var health_baseline = floor(average_enemy_health)
	# Expected value for how many enemies will have one more hit point.
	var expected_health_add = (average_enemy_health - health_baseline) * pieces
	for i in range(0, pieces):
		var color = rng.randf_range(0, pieces - i) < expected_color
		var health = rng.randf_range(0, pieces - i) < expected_health_add
		if color:
			expected_color -= 1
			# Randomly generate an enemy of an allowed color.
			var new_color = colors[rng.randi_range(0, len(colors) - 1)]
			row.push_back(8 * health_baseline + new_color)
		else:
			row.push_back(8 * health_baseline)
		if health:
			expected_health_add -= 1
			row[i] += 8
	time = OS.get_system_time_msecs() - time
	print("Generated enemies in %dms" % time)
	return row
