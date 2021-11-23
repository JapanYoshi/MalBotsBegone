extends Node2D

# needlessly checks for nil, real, and string even though only ints should come in for value
func set_value(value, integer_digits: int = 2, decimal_digits: int = 1):
	if typeof(value) == TYPE_NIL:
		$Label.set_text("")
	elif typeof(value) == TYPE_INT:
		$Label.set_text("%0*d" % [integer_digits, value])
	elif typeof(value) == TYPE_REAL:
		$Label.set_text("%0*.*f" % [integer_digits, decimal_digits, value])
	else:
		$Label.set_text(str(value))
