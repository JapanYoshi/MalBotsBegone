extends Panel
onready var scroller = get_parent().get_parent()
export var tier: int = 1
var tier_accessible: bool = false
signal level_hovered(tier, level)
signal level_selected(tier, level)
onready var buttons = $hl.get_children()

func _ready():
	var tier_text = TranslationServer.translate("I18N_WORLD_TIER%d")
	$Label.set_text(tier_text % (tier + 1))

func set_clear_status(level: int, cleared: bool):
	buttons[level].get_node("s").visible = cleared

func _on_button_focus_entered(extra_arg_0):
	emit_signal("level_hovered", tier, extra_arg_0)

func _on_button_pressed(extra_arg_0):
	if scroller.focused_tier == tier and scroller.focused_index == extra_arg_0:
		if tier_accessible:
			emit_signal("level_selected", tier, extra_arg_0)
		else:
			Root.show_error("I18N_TIER_LOCKED")
	else:
		emit_signal("level_hovered", tier, extra_arg_0)

#func _input(event):
#	if event is InputEventMouseMotion:
#		accept_event()

func set_access(accessible: bool):
	tier_accessible = accessible
	if tier_accessible:
		modulate = Color.white
	else:
		modulate = Color(1.0, 1.0, 1.0, 0.25)
