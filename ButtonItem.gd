extends Control

var Menu
export var action_name = "I18N_MOVE_LEFT"
export var gamepad = false
export var texture = preload("res://gamepad/gamepad_L.png")
var is_key_config_item = true

# Called when the node enters the scene tree for the first time.
func _ready():
	Menu = find_parent("KeyConfig")
	$HBoxContainer/TextureRect.texture = texture

func _input(event):
	if !($HBoxContainer/Remap.has_focus()): return;
	if event.is_action_pressed("ui_down"):
		var neighbor = get_parent().get_child(get_index() + 1)
		if is_instance_valid(neighbor) and "is_key_config_item" in neighbor:
			accept_event()
			# find the "remap" button in the button below, if it exists.
			var focus_next = neighbor.find_node("Remap", true)
			if not is_instance_valid(focus_next):
				# can't find it, fallback to default neighbor
				focus_next = get_node(focus_neighbour_bottom)
				# and scroll the list to the bottom while we're at it
				get_parent().get_parent().scroll_vertical = 99999
			if not is_instance_valid(focus_next):
				# can't find it, uh oh panic
				printerr("Can't find the bottom neighbor!")
			focus_next.grab_focus()
	elif event.is_action_pressed("ui_up"):
		var neighbor = get_parent().get_child(get_index() - 1)
		if is_instance_valid(neighbor) and "is_key_config_item" in neighbor:
			accept_event()
			neighbor.find_node("Remap", true).grab_focus()
			# the first element is index 1, because
			# the animated banner we want to show is index 0
			if get_index() <= 2:
				# scroll the list to the top, because we're at the top
				get_parent().get_parent().scroll_vertical = -100

func change_value(value):
	$HBoxContainer/VBoxContainer/Map.text = value

# Called every frame. 'delta' is the elapsed time since the previous frame.
#func _process(delta):
#    pass

func _on_Remap_pressed():
	Menu.remap(gamepad, action_name)
