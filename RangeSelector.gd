extends Range

func _decrement(step = 1.0):
	print("RangeSelector - decrement by %d" % step)
	value -= step
	if find_parent("EditObjective"):
		find_parent("EditObjective").recalculate()

func _increment(step = 1.0):
	print("RangeSelector - increment by %d" % step)
	value += step
	if find_parent("EditObjective"):
		find_parent("EditObjective").recalculate()
