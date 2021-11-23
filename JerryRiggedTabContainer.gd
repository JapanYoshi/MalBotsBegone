extends TabContainer

func _paginate(index):
	current_tab = index
	find_parent("EditNext").last_domino.id_0 = (0 if current_tab == 0 else current_tab + 5)
	if index == 0:
		if get_parent().find_node("Dominoes").get_child(0).get_child_count() == 0:
			get_parent().find_node("H").find_node("OptionButton").set_focus_neighbour(
				MARGIN_BOTTOM,
				null
			)
		else:
			get_parent().find_node("H").find_node("OptionButton").set_focus_neighbour(
				MARGIN_BOTTOM,
				get_parent().find_node("Dominoes").get_child(0).get_child(0).get_path()
			)
	elif index == 1:
		get_parent().find_node("H").find_node("OptionButton").set_focus_neighbour(
			MARGIN_BOTTOM,
			$B/C/Decrement.get_path()
		)
	elif index == 2:
		get_parent().find_node("H").find_node("OptionButton").set_focus_neighbour(
			MARGIN_BOTTOM,
			$A/B/EditColorButton0.get_path()
		)
		find_parent("EditNext").color_set_warning()
