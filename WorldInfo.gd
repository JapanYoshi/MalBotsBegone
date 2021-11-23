extends PanelContainer
var now_shown: bool = false
var now_animating: bool = false
var queue_resize: bool = false
onready var world = get_parent().get_parent().world_number

func _process(delta):
	if queue_resize:
		$v/Control/name.set_size(Vector2.ONE) # should resize to minimum allowable size
		print("rect = ", $v/Control/name.get_rect())
		if $v/Control/name.rect_size.x > $v.rect_size.x:
			var anim = $v/AnimationPlayer.get_animation("text_scroll")
			anim.track_set_key_value(0, 1, -$v/Control/name.rect_size.x)
			var pixels_to_scroll = 256 + $v/Control/name.rect_size.x
			var speed_to_scroll = 96
			anim.set_length(pixels_to_scroll / speed_to_scroll)
			anim.track_set_key_time(0, 1, pixels_to_scroll / speed_to_scroll)
			$v/AnimationPlayer.stop()
			$v/AnimationPlayer.play("text_scroll")
			$v/AnimationPlayer.seek(256 / speed_to_scroll)
		else:
			$v/Control/name.rect_position.x = 0
			$v/AnimationPlayer.stop()
		$v/Control/name.modulate.a = 1
		queue_resize = false
	if now_animating:
		self.rect_position.x = 0 # make the CenterContainer do the job
		if !$AnimationPlayer.is_playing():
			now_animating = false

func show_info(tier, id, title, highscore):
	if tier == -1:
		if now_shown:
			$AnimationPlayer.play_backwards("show")
			now_animating = true
			now_shown = false
	else:
		$v/Control/name.modulate.a = 0
		var level_id = ("W%1d.%1d.%1d" % [world, 1 + tier, 1 + id]) if id < 4 else ("W%1d.%1d" % [world, 1 + tier])
		$v/h/num.set_text(level_id)
		if highscore == -1:
			$v/h/score.set_text("")
			if !now_shown:
				$AnimationPlayer.play("show")
				now_animating = true
			now_shown = true
			$v/Control/name.set_text(TranslationServer.translate("I18N_TIER_LOCKED"))
		else:
			$v/h/score.set_text("%08dpt" % highscore)
			if !now_shown:
				$AnimationPlayer.play("show")
				now_animating = true
			now_shown = true
			$v/Control/name.set_text(title)
		print("rect = ", $v/Control/name.get_rect())
		queue_resize = true
