extends Control

signal game_clear_timer

var all_clear_rect: Node
var clear_rect: Node
var game_over_rect: Node
var bonus_rect: Node
var playing: int = 0

# Called when the node enters the scene tree for the first time.
func _ready():
	all_clear_rect = $Frame/AC
	clear_rect = $Frame/GC
	game_over_rect = $Frame/GO
	bonus_rect = $Frame/BN
	reset()

func reset():
	$AnimationPlayer.stop()
	all_clear_rect.hide()
	clear_rect.hide()
	game_over_rect.hide()
	bonus_rect.hide()

func all_clear():
	reset()
	$Frame.z_index = 1
	playing = 1
	all_clear_rect.show()
	$AnimationPlayer.play("PopUp")

func game_clear():
	reset()
	$Frame.z_index = 5
	playing = 2
	clear_rect.show()
	$AnimationPlayer.play("PopUp")
	# wait 5 seconds before returning to the previous menu
	$GameClearedTimer.start()

func game_over():
	reset()
	$Frame.z_index = 5
	playing = 3
	game_over_rect.show()
	$AnimationPlayer.play("PopUp")
	# wait 5 seconds before returning to the previous menu
	$GameClearedTimer.start()

func bonus():
	reset()
	$Frame.z_index = 1
	playing = 4
	bonus_rect.show()
	$AnimationPlayer.play("PopUp")

func _on_AnimationPlayer_animation_finished(anim_name):
	if anim_name == "PopUp" and (playing == 1 or playing == 4):
		$AnimationPlayer.play("FadeOut")

func _on_GameClearedTimer_timeout():
	emit_signal("game_clear_timer")
