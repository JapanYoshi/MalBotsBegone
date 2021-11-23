extends Button
var edit_next: Node
# Called when the node enters the scene tree for the first time.

func _init(id_0_: int = 0, id_1_: int = 0):
	print("EditDomino _init(%d, %d)" % [id_0_, id_1_])
	if id_0_:
		set_visual(id_0_, id_1_)

func _ready():
	edit_next = find_parent("EditNext")

func set_visual(id_0: int, id_1: int):
	print("EditDomino set_visual(%d, %d)" % [id_0, id_1])
	if id_0:
		$Block0.show()
		$Block1.show()
		$Plus.hide()
		$Block0.set_sprite("Block%d" % id_0)
		$Block1.set_sprite("Block%d" % id_1)
	else:
		$Block0.hide()
		$Block1.hide()
		$Plus.show()


func _on_EditDomino_pressed():
	edit_next.popup(get_index())
