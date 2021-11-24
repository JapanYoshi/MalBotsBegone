extends Control

var readied = false
var config
var config_defaults
var element_dict

func _ready():
	if readied:
		return
	readied = true
	Root.preload_sfx("slider")
	Root.preload_sfx("tab")
	Root.preload_sfx("on")
	Root.preload_sfx("off")
	Root.preload_sfx("save")
	Root.preload_sfx("discard")
	config_defaults = Root.SYSCON.config_defaults
	config_defaults.main.language = Root.default_locale
	$VBoxContainer/ScrollContainer/PageSelect.get_child(0).grab_focus()
	element_dict = {
		"a11y": {
			"font_size": [
				"slider",
				$VBoxContainer/TabContainer/I18N_PAGE_A11Y/VBoxContainer/Slider_FONT_SIZE
			],
			"disable_particles": [
				"bool",
				$VBoxContainer/TabContainer/I18N_PAGE_A11Y/VBoxContainer/Bool_DISABLE_PARTICLES
			],
			"setup": [
				"button",
				$VBoxContainer/TabContainer/I18N_PAGE_A11Y/VBoxContainer/Button_SETUP
			]
		},
		"main": {
			"vol_bgm": [
				"slider",
				$VBoxContainer/TabContainer/I18N_PAGE_MAIN/VBoxContainer/Slider_VOL_BGM
			],
			"vol_sfx": [
				"slider",
				$VBoxContainer/TabContainer/I18N_PAGE_MAIN/VBoxContainer/Slider_VOL_SFX
			],
			"language": [
				"choice",
				$VBoxContainer/TabContainer/I18N_PAGE_MAIN/VBoxContainer/Choice_LANGUAGE
			]
		},
		"ctrl": {
			"key_config": [
				"button",
				$VBoxContainer/TabContainer/I18N_PAGE_CTRL/VBoxContainer/Button_KEY_CONFIG
			],
			"type": [
				"choice",
				$VBoxContainer/TabContainer/I18N_PAGE_CTRL/VBoxContainer/Choice_TYPE
			],
			"rot_delay": [
				"slider",
				$VBoxContainer/TabContainer/I18N_PAGE_CTRL/VBoxContainer/Slider_ROT_DELAY
			],
			"rot_inv": [
				"bool",
				$VBoxContainer/TabContainer/I18N_PAGE_CTRL/VBoxContainer/Bool_ROT_INV
			],
			"das": [
				"slider",
				$VBoxContainer/TabContainer/I18N_PAGE_CTRL/VBoxContainer/Slider_DAS
			],
			"arr": [
				"slider",
				$VBoxContainer/TabContainer/I18N_PAGE_CTRL/VBoxContainer/Slider_ARR
			],
			"move_sens": [
				"slider",
				$VBoxContainer/TabContainer/I18N_PAGE_CTRL/VBoxContainer/Slider_MOVE_SENS
			],
			"soft_sens": [
				"slider",
				$VBoxContainer/TabContainer/I18N_PAGE_CTRL/VBoxContainer/Slider_SOFT_SENS
			],
			"hard_sens": [
				"slider",
				$VBoxContainer/TabContainer/I18N_PAGE_CTRL/VBoxContainer/Slider_HARD_SENS
			]
		},
		"custom": {
			"skin_name": [
				"skin",
				$VBoxContainer/TabContainer/I18N_PAGE_SKIN/Panel/SkinBox
			]
		}
	}
	for loc in Root.locales:
		element_dict.main.language[1].add_item(Root.SYSCON.autonyms[loc])
	print("ready is finished.")
	load_all()

func _input(event):
	var focused = get_focus_owner()
	if is_instance_valid(focused):
		var a = 0
		if event.is_action_pressed("ui_up"):
			a = -1
		elif event.is_action_pressed("ui_down"):
			a = 1
		else:
			return
		print("custom up/down behavior")
		var tabs = $VBoxContainer/TabContainer
		var nodepath = tabs.get_path_to(focused)
		var page: String
		var index: int = -1
		match nodepath.get_name(0):
			"I18N_PAGE_A11Y":
				page = "a11y"
			"I18N_PAGE_MAIN":
				page = "main"
			"I18N_PAGE_CTRL":
				page = "ctrl"
			"I18N_PAGE_SKIN":
				page = "custom"
				index = 0
			"..":
				print("nodepath was %s" % nodepath)
				if nodepath.get_name(1) == "ScrollContainer":
					var section = element_dict[element_dict.keys()[$VBoxContainer/TabContainer.current_tab]]
					print(section.keys()[0])
					section[section.keys()[0]][1].grab_focus()
					Root.request_sfx("cursor")
					accept_event()
				return
			_:
				print("no match: nodepath was %s" % nodepath)
		accept_event()
		var node = tabs.get_node(
			nodepath.get_name(0) + "/" + nodepath.get_name(1) + "/" + nodepath.get_name(2)
		)
		var keys = element_dict[page].keys()
		if index == -1:
			for i in len(keys):
				var key = keys[i]
				if element_dict[page][key][1] == node:
					index = i
					break
		print("SettingsMenuRoot - page, index: %s, %d" % [page, index])
		if index + a == -1:
			# return to this page's header
			$VBoxContainer/ScrollContainer/PageSelect.get_node(page).grab_focus()
		elif index + a == len(element_dict[page]):
			# hover on save button
			$Bottombar/SaveButton.grab_focus()
		else:
			print("SettingsMenuRoot - focusing index %d which is %s" % [index + a, keys[index+a]])
			element_dict[page][keys[index+a]][1].grab_focus()
		Root.request_sfx("cursor")

func load_all():
	if !readied:
		_ready()
	config = Root.config
	if !config:
		Root.config.save("user://settings.cfg")
		print("Load error. Creating default config data.")
		for section in config_defaults.keys():
			for key in config_defaults[section].keys():
				print("config defaults: ", section, ".", key)
				config.set_value(section, key, config_defaults[section][key])
				element_dict[section][key][1].set_value(config_defaults[section][key])
		element_dict["main"]["language"][1].set_value(
			Root.locales.find(
				Root.default_locale
			)
		)
	else:
		print("Config loaded")
		for section in element_dict.keys():
			for key in element_dict[section].keys():
				print(section, ".", key, "=", config.get_value(section, key, "undefined"), ". Type ID ", typeof(config.get_value(section, key, "undefined")), " (0:NIL, 1:BOOL, 2:INT, 3:REAL, 4:STRING, ..., 20:RAW_ARRAY)")
				if section == "main" and key == "language":
					element_dict["main"]["language"][1].set_value(
						Root.locales.find(
							config.get_value("main", "language", Root.default_locale)
						)
					)
				elif element_dict[section][key][0] == "button":
					pass
				else:
					print("applying value: ", section, ".", key, "=", config.get_value(section, key))
					element_dict[section][key][1].set_value(
						config.get_value(
							section, key, config_defaults[section][key]
						)
					)

func apply_all():
	for section in element_dict.keys():
		for key in element_dict[section].keys():
			if section == "main" and key == "language":
				if typeof(element_dict.main.language[1].get_value()) == TYPE_INT:
					config.set_value(
						"main", "language",
						Root.locales[element_dict.main.language[1].get_value()]
					)
				else:
					config.set_value("main", "language", "en")
			elif element_dict[section][key][0] == "button":
				pass
			else:
				config.set_value(section, key, element_dict[section][key][1].get_value())
	change_locale()
	config.save("user://settings.cfg")
	Root.config = config

func change_locale():
	var locale = Root.locales[element_dict.main.language[1].get_value()]
	print("Changing locale to ", locale)
	TranslationServer.set_locale(locale)
	assert (TranslationServer.get_locale() == locale)

func request_slider_sfx(ratio):
	Root.request_sfx("slider", pow(2, ratio - 0.5))

func _on_Button_pressed():
	Root.request_sfx("back")
	Root.set_vol_bgm(config.get_value("main", "vol_bgm", config_defaults.main.vol_bgm))
	Root.set_vol_sfx(config.get_value("main", "vol_sfx", config_defaults.main.vol_sfx))
	Root.unload_sfx("slider")
	Root.unload_sfx("tab")
	Root.unload_sfx("on")
	Root.unload_sfx("off")
	Root.unload_sfx("save")
	Root.unload_sfx("discard")
	Root.change_scene("MainMenuRoot")

func on_bool(state):
	print("on_bool")
	if state:
		Root.request_sfx("on")
	else:
		Root.request_sfx("off")

func on_choice_focused(index, count, option_name = ""):
	request_slider_sfx((index as float) / (count - 1))

func on_choice_chosen(index, count, option_name = ""):
	assert(Root, "Root wasn't found!!")
	Root.request_sfx("decide")
	change_locale()

func on_slider_change(value, range_min, range_max, name = ""):
	if !readied:
		_ready()
	assert(Root, "Root wasn't found!!")
	#print("slider change: ", value, ", ", name)
	if name == "I18N_VOL_BGM":
		Root.set_vol_bgm(value)
	elif name == "I18N_VOL_SFX":
		Root.set_vol_sfx(value)
	elif name == "I18N_FONT_SIZE":
		var fonts = Root.apply_font(value)
		for section in element_dict.keys():
			for key in element_dict[section].keys():
				#print("on slider change: ", section, " ", key)
				if element_dict[section][key][0] != "button":
					element_dict[section][key][1].reload_font(fonts)
		for tab in $VBoxContainer/ScrollContainer/PageSelect.get_children():
			tab.set("custom_fonts/font", fonts[1])
		for page in $VBoxContainer/TabContainer.get_children():
			for child_node in page.get_children():
				if !(child_node is VBoxContainer or child_node is PanelContainer):
					continue
				for grandchild_node in child_node.get_children():
					if child_node is Label or child_node is Button:
						child_node.set("custom_fonts/font", fonts[1])
	request_slider_sfx((value - range_min) / (range_max - range_min))

func _on_TabContainer_tab_changed(tab):
	assert(Root, "Root wasn't found!!")
	Root.request_sfx("tab")

func _on_LoadButton_pressed():
	assert(Root, "Root wasn't found!!")
	Root.request_sfx("discard")
	Root.reset_settings()
	load_all()

func _on_SaveButton_pressed():
	assert(Root, "Root wasn't found!!")
	Root.request_sfx("save")
	apply_all()

func _on_KeyConfig_pressed():
	Root.request_sfx("decide")
	Root.change_scene("KeyConfig")

func _on_Setup_pressed():
	Root.request_sfx("decide")
	Root.request_bgm_stop()
	Root.change_scene("FirstTime")

func _on_Reset_pressed():
	# todo: make custom modal for this specific purpose
	Root.show_confirm(
		"I18N_DELETE_SAVE_CONFIRM",
		1, # warning
		self,
		"_on_Reset_confirmed"
	)

func _on_Reset_confirmed(result, _id):
	if result == true:
		Root.reset_game()
