extends Control

signal ready_finished
# Called when the node enters the scene tree for the first time.
func _ready():
	Root.request_bgm("arcade")
	$Carousel/VBoxContainer/Panel/VBoxContainer/RichTextLabel.bbcode_text = TranslationServer.translate("I18N_MODE_MARATHON_HELP")
	$Carousel/VBoxContainer/Panel2/VBoxContainer/RichTextLabel.bbcode_text = TranslationServer.translate("I18N_MODE_PETRI_HELP")
	$Carousel/VBoxContainer/Panel3/VBoxContainer/RichTextLabel.bbcode_text = TranslationServer.translate("I18N_MODE_ONSLAUGHT_HELP")
	$Carousel/VBoxContainer/Panel4/VBoxContainer/RichTextLabel.bbcode_text = TranslationServer.translate("I18N_MODE_MISSION_HELP")
	$Carousel/VBoxContainer/Panel5/VBoxContainer/RichTextLabel.bbcode_text = TranslationServer.translate("I18N_MODE_ZEN_HELP")

	var template = "[center]" + TranslationServer.translate("I18N_HIGHSCORE_%s") + "[/center]";
	$Carousel/VBoxContainer/Panel/VBoxContainer/HS.bbcode_text = template % ("[b]%08d[/b]" % Root.save_dict.arcade.highscores.marathon)
	$Carousel/VBoxContainer/Panel2/VBoxContainer/HS.bbcode_text = template % ("[b]%08d[/b]" % Root.save_dict.arcade.highscores.petri)
	$Carousel/VBoxContainer/Panel3/VBoxContainer/HS.bbcode_text = template % ("[b]%08d[/b]" % Root.save_dict.arcade.highscores.onslaught)
	$Carousel/VBoxContainer/Panel4/VBoxContainer/HS.bbcode_text = template % ("[b]%08d[/b]" % Root.save_dict.arcade.highscores.mission)
	$Carousel/VBoxContainer/Panel5/VBoxContainer/HS.bbcode_text = template % ("[b]%08d[/b]" % Root.save_dict.arcade.highscores.zen)
	$Carousel/VBoxContainer/Panel/VBoxContainer/Button.grab_focus()
	emit_signal("ready_finished")

func _on_ButtonExit_pressed():
	Root.back_scene()

func _on_Marathon_pressed():
	Root.change_scene("GameModeMarathon")

func _on_Petri_pressed():
	Root.change_scene("OptionsPetri")

func _on_Onslaught_pressed():
	Root.change_scene("GameModeOnslaught")

func _on_Mission_pressed():
	Root.show_message("I18N_MODE_NOT_DONE", 0)

func _on_Zen_pressed():
	Root.change_scene("GameModeZen")
