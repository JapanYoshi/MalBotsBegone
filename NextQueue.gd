extends Node

const Next = preload("res://NextClass.gd").Next

# The array of the NEXT pieces.
# It does NOT delete already given pieces,
# in order to allow looping to a past point.
var next: Array = []
var index = 0
var data_length = 0

var Domino = preload("res://GameDomino.tscn")

# The RNG used for random pieces.
var rng: RandomNumberGenerator

func load_data(data):
	assert(data[0] is int)
	index = 0
	next = []
	data_length = 0
	var i = 0
	while i < len(data):
		match data[i]:
			0x00:
				# end
				next.push_back(Next.new(0, 0))
			0x02:
				i += 1
				# autogen
				next.push_back(Next.new(7, data[i]))
				data_length = -1
			_:
				if data[i] < 0x30:
					i += 1
					# loop
					next.push_back(Next.new(6, (data[i-1] & 15 << 6) + data[i]))
					data_length = -1
				else:
					# normal
					next.push_back(Next.new((data[i] >> 3) & 7, data[i] & 7))
					data_length += 1
		i += 1

func load_dominoes(dominoes):
	assert(!(dominoes[0] is int))
	index = 0
	next = dominoes
	if next[len(next) - 1].id_0 == 0:
		data_length = len(next) - 1
	else:
		data_length = -1
	var debug = true
	if debug:
		print("NextQueue - load_dominoes:")
		for i in dominoes:
			print("Domino: %d %d" % [i.id_0, i.id_1])
		print("Data length: %d" % data_length)

func load_tuples(dominoes):
	assert(len(dominoes[0]) == 2)
	var domino_nodes = []
	for tuple in dominoes:
		domino_nodes.push_back(Next.new(tuple[0], tuple[1]))
	load_dominoes(domino_nodes)

# Gives the next item in the NEXT queue.
# This function should be called as many times as there are
# displayed NEXT pieces. This function also deals with the special
# NEXT pieces, which cause randomization or looping.
# Return value: Next piece with id_0 of:
#   * 0
#     - end of queue, or:
#   * 1 to 5
#     - normal domino of 2 blocks.
func get_next(parent: Node) -> Node:
	if index >= len(next):
		# out of range
		printerr("NextQueue - get_next(): Index out of range! Pointing to last piece instead.")
		index = len(next) - 1
	else:
		print("NextQueue - get_next() called while index is %d." % index)
	if next[index].id_0 == 6:
		# looping to index
		print("NextQueue - Looping to index %d." % next[index].id_1)
		index = next[index].id_1
	elif next[index].id_0 == 7:
		# generate random pieces
		generate(next[index].id_1)
	elif next[index].id_0 == 0:
		# end of queue
		print("NextQueue - Queue ran out...")
	else:
		# normal piece
		pass
	# now that we have the correct index, make a node from the Next object
	print("NextQueue - Index is %d with data %d, %d" % [index, next[index].id_0, next[index].id_1])
	var node = make_node(next[index])
	parent.add_child(node)
	index += 1
	return node

func make_node(next_one) -> Node:
	var domino = Domino.instance()
	if 1 <= next_one.id_0 and next_one.id_0 <= 5:
		domino.id_0 = next_one.id_0
		domino.id_1 = next_one.id_1
	return domino

# Generates random pieces from the given bit mask (bits 0 - 4 inclusive).
# When n colors are allowed, this function generates
# (n * n+3) / 2 dominos of 2 pieces each,
# from a bag of (n * n+3) pieces.
func generate(bit_mask):
	if bit_mask == 0:
		printerr("NextQueue - Could not generate colors because no colors are allowed.")
		next.append(Next.new())
#	print("Generating random pieces...")
	var end_marker = next.pop_back()
	var allowed = []
	if (bit_mask & 0b00000001):
		allowed.append(1)
	if (bit_mask & 0b00000010):
		allowed.append(2)
	if (bit_mask & 0b00000100):
		allowed.append(3)
	if (bit_mask & 0b00001000):
		allowed.append(4)
	if (bit_mask & 0b00010000):
		allowed.append(5)
#	print("Colors allowed: ", allowed)
	var bag = []
	for color in allowed:
#		print("Color", color)
		for j in range(len(allowed) + 3): # add 3 to make sure there's an even number of pieces in the bag
			bag.append(color)
	assert(len(bag) % 2 == 0)
	next = []
	index = 0
	while len(bag):
#		print("Bag1", bag)
		var piece = Next.new()
		var roll = rand_int(len(bag))
		piece.id_0 = bag[roll]
		bag.remove(roll)
#		print("Bag2", bag)
		roll = rand_int(len(bag))
		piece.id_1 = bag[roll]
		bag.remove(roll)
		next.append(piece)
	assert(len(bag) == 0)
	next.append(end_marker)

# I didn't know that rng.randi_range was INCLUSIVE, so here I am.
# Generates a pseudo-random integer that is non-negative
# and less than `range_max`.
func rand_int(range_max):
	if range_max == 1:
		return 0
	return rng.randi_range(0, range_max - 1)
# Called every frame. 'delta' is the elapsed time since the previous frame.
#func _process(delta):
#	pass
