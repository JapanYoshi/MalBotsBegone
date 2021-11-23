extends Node2D

func set_bbcode(text):
	$PanelContainer/RichTextLabel.set_bbcode(TranslationServer.translate(text))
	$PanelContainer.set_size(Vector2(0, 0)) # should resize to minimum allowable size
