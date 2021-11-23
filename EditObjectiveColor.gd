extends Control

export var value = 0
var currently_block_mode = false

func set_value(new_value):
	value = new_value;
	for index in len(get_children()):
		get_child(index).pressed = value >> index & 1

func _on_child_toggled(new_state, index):
	if new_state:
		value = value ^ (1 << index)
	else:
		value = value & ~(1 << index)
	find_parent("EditObjective").recalculate()

func sprite_mode(block: bool = false):
	print("EditObjectiveColor - sprite_mode ", block)
	if block == currently_block_mode:
		return
	currently_block_mode = block
	if block:
		$C0.hide()
		$C0.disabled = true
		for i in range(1, 6):
			get_child(i).get_child(0).set_sprite("Block%d" % i)
	else:
		$C0.show()
		$C0.disabled = false
		for i in range(1, 6):
			get_child(i).get_child(0).set_sprite("V%d" % i)
