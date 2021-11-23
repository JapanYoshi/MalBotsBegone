extends "res://WorldTier.gd"


func _ready():
	var tier_text = TranslationServer.translate("I18N_WORLD_BOSS")
	$Label.set_text(tier_text)
