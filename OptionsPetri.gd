extends Control
func _join_tree():
	Root.preload_scene("GameModePetri")

func _ready():
	# color count
	$ScrollContainer/Opts/A0/B0/Box/Val.suffix = TranslationServer.translate("I18N_UNIT_COLORS")
	# rows
	$ScrollContainer/Opts/A1/B0/Box/Val.suffix = TranslationServer.translate("I18N_UNIT_ROWS")
	# HP
	$ScrollContainer/Opts/A2/B0/Box/Val.suffix = TranslationServer.translate("I18N_UNIT_HP")

func _on_ButtonExit_pressed():
	Root.back_scene()

func _on_OK_pressed():
	var preloaded = Root.preloaded_scene
	if !preloaded:
		Root.preload_scene("GameModePetri")
		preloaded = Root.preloaded_scene
	Root.pass_between = {
		"mode": "Petri",
		"colors": $ScrollContainer/Opts/A0/B0/Box/Val.value,
		"rows": $ScrollContainer/Opts/A1/B0/Box/Val.value,
		"color_ratio": $ScrollContainer/Opts/A3/B0/Box/Val.value / 100.0,
		"hp": $ScrollContainer/Opts/A2/B0/Box/Val.value,
		"level": $ScrollContainer/Opts/A4/B0/Box/Val.index * 10
	}
	preloaded.set_params(
		$ScrollContainer/Opts/A0/B0/Box/Val.value,
		$ScrollContainer/Opts/A1/B0/Box/Val.value,
		$ScrollContainer/Opts/A3/B0/Box/Val.value / 100.0,
		$ScrollContainer/Opts/A2/B0/Box/Val.value,
		$ScrollContainer/Opts/A4/B0/Box/Val.index * 10
	)
	Root.change_scene_preloaded()
