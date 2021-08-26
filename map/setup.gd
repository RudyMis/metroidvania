tool
extends Node

export (bool) var neighbours setget set_neighbours
export (bool) var placeholders setget set_placeholders

func set_neighbours(value : bool):
	for child in get_parent().get_children():
		if child.is_class("LDtkLevel"):
			child.set_neighbours(Array())

			for another_child in get_parent().get_children():
				if another_child.is_class("LDtkLevel") && another_child != child:
					if child.rect.intersects(another_child.rect, true):
						child.add_neighbour(another_child)

			child.save_level()

func set_placeholders(value : bool):
	pass

func _ready():
	pass
