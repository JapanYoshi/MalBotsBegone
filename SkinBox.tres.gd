extends VBoxContainer

var value
var index
var skin_dict: Dictionary
var skin_list: Array
# Called when the node enters the scene tree for the first time.
func _ready():
	skin_dict = Root.SYSCON.skin_sizes
	skin_list = skin_dict.keys()

func set_value(new_value, new_index = -1):
	# find the index
	value = new_value
	if new_index == -1:
		index = skin_list.find(value)
	else:
		index = index
	# size check
	var size = skin_dict[new_value]
	
	var children = $PanelContainer/PreviewGrid.get_children()
	for i in range(0, len(children)):
		children[i].change_skin(value, i, size)
	$SkinLabel/SkinDescContainer/SkinNumber.text = "%d/%d" % [index + 1, len(skin_list)]
	$SkinLabel/SkinDescContainer/SkinName.text = "I18N_SKIN_" + value + "A"
	$SkinDesc.text = "I18N_SKIN_" + value + "B"
	
	
func get_value():
	return value

func increment():
	print("skin increment from ", value)
	index = (index + 1) % len(skin_list)
	print("next key is ", skin_list[index])
	set_value(skin_list[index], index)
	find_parent("SettingsMenuRoot").request_slider_sfx(index as float / (len(skin_list) - 1))

func decrement():
	print("skin decrement from ", value)
	index = posmod(index - 1 + len(skin_list), len(skin_list))
	print("prev key is ", skin_list[index])
	set_value(skin_list[index], index)
	find_parent("SettingsMenuRoot").request_slider_sfx(index as float / (len(skin_list) - 1))

func _on_AnimSwitchTimer_timeout():
	var children = $PanelContainer/PreviewGrid.get_children()
	# print("toggle animation")
	for i in range(0, len(children)):
		children[i].toggle_animation()

func reload_font(fonts):
	print("reloading font in type skin")
	$Label.set("custom_fonts/font", fonts[0])
	$SkinLabel/SkinDescContainer/SkinNumber.set("custom_fonts/font", fonts[2])
	$SkinLabel/SkinDescContainer/SkinName.set("custom_fonts/font", fonts[1])
	$SkinDesc.set("custom_fonts/font", fonts[0])

func grab_focus():
	$SkinLabel/BackButton.grab_focus()
