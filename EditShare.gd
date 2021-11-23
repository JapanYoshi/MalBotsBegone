extends NinePatchRect

var active: bool = false
var androidPI

var last_saved = ""
var last_saved_image: Image

var EditRoot: Node
var version_new_flag: bool = false

func set_active(x: bool):
	active = x
	if x:
		show()
		$scrl/A/LevelData.grab_focus()
	else:
		hide()

# Called when the node enters the scene tree for the first time.
func _ready():
	EditRoot = find_parent("EditResize")
	print("EditShare - Trying to initialize GodotGetImage")
	if Engine.has_singleton("GodotGetImage"):
		print("EditShare - GodotGetImage 0")
		androidPI = Engine.get_singleton("GodotGetImage")
		print("EditShare - GodotGetImage 1")
		androidPI.connect("image_request_completed", self, "_android_image_loaded")
		print("EditShare - GodotGetImage 2")
		androidPI.connect("error", self, "_android_image_error")
		print("EditShare - GodotGetImage 3")
		androidPI.connect("permission_not_granted_by_user", self, "_android_not_permitted")
		print("EditShare - GodotGetImage 4")
		androidPI.setOptions({
			"image_height": 1080,
			"image_width": 1920,
			"keep_aspect": true,
			"image_format": "png"
		})
		print("EditShare - GodotGetImage 5")
	print("EditShare - Initialized GodotGetImage")

func _on_Generate_pressed():
	# name_as_bytes: PoolByteArray, mission: PoolByteArray, next: Array, field: Array
	var data = generate_data()
	$scrl/A/LevelData.text = Root.base64(Array(data))


func _on_Load_pressed():
	_set_status(
		"Loading from text..."
	)
	var bytes = Root.decode_base64(
			$scrl/A/LevelData.text
		)
	load_data(bytes)

func generate_data():
	version_new_flag = $scrl/A/Setting_Bool/HBoxContainer/CheckButton.pressed
	
	var new_next = EditRoot.find_node("EditNext").dominoes.duplicate(true);
	new_next.append(EditRoot.find_node("EditNext").last_domino);
	var level_data = {
		"ver": "1" if version_new_flag else "0",
		"name": EditRoot.find_node("EditObjective").title,
		"name_16": Array(EditRoot.find_node("EditObjective").title_as_utf16_bytes),
		"auth": EditRoot.find_node("EditObjective").author,
		"auth_16": Array(EditRoot.find_node("EditObjective").author_as_utf16_bytes),
		"mission": Array(EditRoot.find_node("EditObjective").objective),
		"next": new_next,
		"field": EditRoot.find_node("EditPlayfield").playfield_data,
		"level": EditRoot.find_node("EditObjective").level,
		"solved": EditRoot.get_parent().solved,
		"solution": EditRoot.get_parent().solution,
		"seed": EditRoot.find_node("EditObjective").rng_seed
	}
	print(JSON.print(level_data, "  "))
	return Root.level_data_to_bytes(level_data)

func load_data(bytes):
	var data = Root.bytes_to_level_data(
		bytes
	)
	var time = OS.get_datetime()
	var timestamp = "%02d:%02d.%02d" % [time.hour, time.minute, time.second]
	if data.result != "SUCCESS":
		_set_status(
			timestamp + " Could not load level data: %s" % data.result
		)
		return
	else:
		_set_status(
			timestamp + " Level data has been loaded! %s" % data.result
		)
	for key in data.keys():
		if data[key] is Dictionary:
			for subkey in data[key].keys():
				print("data.", key, ".", subkey, ":", str(data[key][subkey]))
		elif data[key] is Array:
			for i in range(len(data[key])):
				print("data.", key, "[", i, "]:", str(data[key][i]))
		else:
			print("data.", key, ":", str(data[key]))
	EditRoot.find_node("EditObjective").set_title(data.name)
	EditRoot.find_node("EditObjective").set_author(data.auth)
	EditRoot.find_node("EditObjective").set_level(data.level)
	EditRoot.get_parent().find_node("GameRoot").find_node("ObjectiveBox").parse_objective(data.mission)
	if data.has("seed"):
		EditRoot.find_node("EditObjective").rng_seed = data.seed
	EditRoot.find_node("EditObjective").objective = data.mission
	EditRoot.find_node("EditObjective").get_node("S/A/Objective").select(0)
	EditRoot.find_node("EditObjective").get_node("S/A/Objective").select(
		EditRoot.get_parent().find_node("GameRoot").find_node("ObjectiveBox").objective_id
	)
	EditRoot.find_node("EditNext").set_dominoes(data.next)
	EditRoot.find_node("EditPlayfield").playfield_data = data.field
	EditRoot.find_node("EditPlayfield").reload_board()
	if data.has("solved"):
		EditRoot.get_parent().solved = data.solved
		EditRoot.get_parent().solution = data.solution

func reset_data():
	load_data([ # version 0 code for empty level
		0x4D, 0x42, 0x30, 0x00,
		0xF0, 0x00, 0x00, 0x00,
		0x00, 0x20, 0x00, 0x00,
		0x20, 0xEF, 0x11
	])

func _on_ButtonExit_pressed():
	set_active(false)
	find_parent("EditMode").back_to_menu()

func _on_LoadQR_pressed():
	_set_status(
		"Loading from QR code is unimplemented."
	)

const use_base64: bool = false

func _on_GenerateQR_pressed():
	_set_status(
		"Generating QR code is unimplemented."
	)
	var data = generate_data()
	var b64 = Root.base64(Array(data))
	$scrl/A/LevelData.text = b64
	var frame = load("res://qr_frame.png")
	print("Frame image size is ", frame.get_size(), " (should be 1920x1080)")
	# generate the qr code!
	var img: Image
	if use_base64:
		pass#img = qr.GenerateImage(b64, frame)
	else:
		print("Start of data is %d %d %d" % [data[0], data[1], data[2]])
		pass#img = qr.GenerateImage(data, frame)
	
	#var time = OS.get_datetime()
	#var timestamp = "%02d%02d%02d-%02d%02d%02d" % [time.year, time.month, time.day, time.hour, time.minute, time.second]
	#var filename = "MalBots_%s_%s.png" % [timestamp, EditRoot.find_node("EditObjective").title]

func _on_FileDialog_file_selected(path):
	pass
	#var selected = Image.new()
	#selected.load(path)
	#var data_out = qr.ReadFromGodot(selected)
	#print("EditShare - Loaded data from image")
	#load_data(data_out)

func _set_status(text):
	$scrl/A/status.set_text(text)

func _set_viewport_things():
	$Viewport/Title.set_text(EditRoot.find_node("EditObjective").title)
	EditRoot.get_parent().find_node("GameRoot").find_node("ObjectiveBox").parse_objective(EditRoot.find_node("EditObjective").objective)
	$Viewport/Objective.set_bbcode(EditRoot.get_parent().find_node("GameRoot").find_node("ObjectiveBox").find_node("Text").get_bbcode())
	$Viewport/Author.set_text(EditRoot.find_node("EditObjective").author)
	$Viewport/TileMap.clear()
	var tiledata = EditRoot.find_node("EditPlayfield").playfield_data
	print("tiledata size is ", len(tiledata))
	for y in range(0, 12):
		for x in range(0, Root.COLUMNS):
			if len(tiledata) > y and len(tiledata[y]) > x:
				print("setting cell (%2d,%2d) to %2d..." % [x, y, tiledata[y][x]])
				$Viewport/TileMap.set_cell(x, 11 - y, tiledata[y][x])
				print("cell value is %2d" % $Viewport/TileMap.get_cell(x, 11 - y))
	var next_length = EditRoot.find_node("EditNext").get_length()
	$Viewport/Next.set_text("Infinite" if next_length == -1 else "%d" % next_length)
	$Viewport/Speed.set_text("%d / 20" % EditRoot.find_node("EditObjective").level)
	var difficulty = EditRoot.find_node("EditObjective").difficulty
	var max_difficulty = EditRoot.find_node("EditObjective").max_difficulty
	$Viewport/Difficulty.set_text("Undeclared" if difficulty == 0 else "★".repeat(difficulty) + "☆".repeat(max_difficulty - difficulty))
	var date = OS.get_date()
	$Viewport/Date.set_text("%04d-%02d-%02d" % [date.year, date.month, date.day])

func _clear_viewport_things():
	$Viewport/Title.set_text("")
	$Viewport/Objective.set_bbcode("")
	$Viewport/Author.set_text("")
	$Viewport/TileMap.clear()
	$Viewport/Next.set_text("")
	$Viewport/Speed.set_text("")
	$Viewport/Difficulty.set_text("")
	$Viewport/Date.set_text("")

func _on_SaveDialog_file_selected(path: String):
	var img = last_saved_image
	var save_err = img.save_png(path)
	var time = OS.get_datetime()
	var timestamp = "%02d:%02d.%02d" % [time.hour, time.minute, time.second]
	match save_err:
		OK:
			_set_status(
				timestamp + " " + TranslationServer.translate("I18N_QR_SAVED")
			)
		13:
			_set_status(
				timestamp + " " + TranslationServer.translate("I18N_QR_ERROR")
				+ TranslationServer.translate("I18N_ERROR_13")
			)
		15:
			_set_status(
				timestamp + " " + TranslationServer.translate("I18N_QR_ERROR")
				+ TranslationServer.translate("I18N_ERROR_15")
			)
		_:
			_set_status(
				timestamp + " " + TranslationServer.translate("I18N_QR_ERROR")
				+ TranslationServer.translate("I18N_ERROR_FALLBACK") % save_err
			)
