# Class for a piece in the NEXT queue.
# It either contains a pair of blocks, or a
# special instruction for this Object to process.
# `id_0`: Either the first  block color, or a sentinel for a special value.
# `id_1`: Either the second block color, or the parameter for a special value.
#   `id_0` == 0
#     * the end of the queue
#       * id_1 is unused
#   id_0 == 1 ~ 5
#     * normal block, contains first block ID
#       * id_1 contains the other block ID
#   id_0 == 6
#     * looping to index
#       * id_1 contains index to loop to
#   id_0 == 7
#     * generating random pieces of specific colors
#       * id_1 contains bit mask of colors (bits 0 through 4)
class Next:
	var id_0: int = 0
	var id_1: int = 0
	func _init(int_0: int = 0, int_1: int = 0):
		id_0 = int_0
		id_1 = int_1
	func _to_string():
		return "[%d, %d]" % [id_0, id_1]
