extends ScrollContainer

var world_directory: String = "tutorial"
var world_number: int = 0
var tier_count: int = 1
signal level_hovered(tier, id)
signal level_selected(tier, id)
onready var back_button = $l/h/H/Back
var tier_list: Array = []
var focused_tier: int = -1
var focused_index: int = 0
const scroll_margin: int = 160
var _scroll_value: float = 0.0
var _scroll_is_tweening: bool = false

func initialize(world_directory_, world_number_, tier_count_):
	world_directory = world_directory_
	world_number = world_number_
	tier_count = tier_count_
	$l/h/H/v/w.set_text(TranslationServer.translate(
		"I18N_WORLD_%d"
	) % world_number)
	$l/h/H/v/t.set_text(TranslationServer.translate(
		"I18N_WORLD_%dA" % world_number
	))
	$l/advance/label.set_bbcode(TranslationServer.translate(
		"I18N_WORLD_ADVANCE"
	))
	# set up tiers
	var tier_elem = $l/tier
	tier_list.append(tier_elem)
	if tier_count > 1:
		for i in range(1, tier_count):
			var tier = tier_elem.duplicate()
			tier.set_access(false)
			tier.tier = i
			$l.add_child(tier)
			tier_list.append(tier)
		var bottom = $l/margin_bottom
		$l.remove_child(bottom)
		$l.add_child(bottom)
	var boss = $l/final_tier
	boss.tier = len(tier_list)
	tier_list.append(boss)

func set_clear_status(tier, i, clear_bit):
	tier_list[tier].set_clear_status(i, clear_bit)

func _process(delta):
	if _scroll_is_tweening:
		#if _scroll_value != get_v_scroll():
			set_v_scroll(_scroll_value)
		#else:
		#	_scroll_is_tweening = false

func _input(event):
	var moved: bool = false
	var focused = get_focus_owner()
	if event.is_action_pressed("ui_left"):
		if focused_tier == -1:
			return
		else:
			focused_index = posmod(focused_index - 1, 4)
			moved = true
	elif event.is_action_pressed("ui_right"):
		if focused_tier == -1:
			return
		else:
			focused_index = posmod(focused_index + 1, 4)
			moved = true
	elif event.is_action_pressed("ui_up"):
		if focused_tier == -1:
			focused_tier = len(tier_list) - 1
			moved = true
		else:
			focused_tier -= 1
			moved = true
	elif event.is_action_pressed("ui_down"):
		if focused_tier == len(tier_list) - 1:
			focused_tier = -1
			moved = true
		else:
			focused_tier += 1
			moved = true
	elif event.is_action_pressed("ui_cancel"):
		if focused_tier == -1:
			_on_Back_pressed()
			return
		else:
			focused_tier = -1
			moved = true
	elif event.is_action_pressed("ui_accept"):
		if focused_tier == -1:
			_on_Back_pressed()
			return
		else:
			# this was causing a bug where locked levels can be entered
			# _on_tier1_level_selected(focused_tier, focused_index)
			return
	if moved:
		accept_event()
		_on_tier1_level_hovered(focused_tier, focused_index)
	else:
		pass

func _on_tier1_level_hovered(tier, level):
	Root.request_sfx("cursor")
	focused_tier = tier
	focused_index = level
	print("Current focus: Tier %d Level %d" % [tier, level])
	if focused_tier == -1:
		back_button.grab_focus()
		emit_signal("level_hovered", -1, 0)
	else:
		if focused_tier == tier_count:
			tier_list[focused_tier].buttons[0].grab_focus()
			emit_signal("level_hovered", focused_tier, 4)
		else:
			tier_list[focused_tier].buttons[focused_index].grab_focus()
			emit_signal("level_hovered", focused_tier, focused_index)
	_scroll_margin()

func _scroll_margin():
	var selected = get_focus_owner()
	if !is_instance_valid(selected):
		return
	var selected_path = $l.get_path_to(selected)
	selected = $l.get_node(selected_path.get_name(0))
	var pos = selected.get_margin(MARGIN_TOP)
	var size = selected.get_size().y
	print(get_v_scroll(), " ", pos, " ", size)
	if get_v_scroll() > pos - scroll_margin:
		_smooth_scroll(pos - scroll_margin)
	elif get_v_scroll() + get_size().y < pos + size + scroll_margin:
		_smooth_scroll(pos + size + scroll_margin - get_size().y)

func _smooth_scroll(scroll_to):
	$Tween.stop(self, "_scroll_value")
	$Tween.interpolate_property(self, "_scroll_value", get_v_scroll(), scroll_to, 0.25, Tween.TRANS_CUBIC, Tween.EASE_OUT)
	$Tween.start()
	_scroll_is_tweening = true

func _on_tier1_level_selected(tier, level):
	print("level selected: tier ", tier, " lv ", level)
	emit_signal("level_selected", tier, level)

func _on_Back_mouse_entered():
	_on_tier1_level_hovered(-1, focused_index)

func _on_Back_pressed():
	if focused_tier == -1:
		Root.request_sfx("back")
		print("Back pressed")
		Root.back_scene()
	else:
		_on_tier1_level_hovered(-1, focused_index)

func _on_Tween_tween_completed(object, key):
	if key == ":_scroll_value":
		_scroll_is_tweening = false
	else:
		print("WorldScroller tween completed, object |", object, "| key |", key, "|")
