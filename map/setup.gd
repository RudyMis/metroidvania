tool
extends Node

export (bool) var neighbours setget set_neighbours

func set_neighbours(_value : bool):
	for child in get_parent().get_children():
		if child.is_class("LDtkLevel"):
			child.set_neighbours(Array())

			for another_child in get_parent().get_children():
				if another_child.is_class("LDtkLevel") && another_child != child:
					if child.rect.intersects(another_child.rect, true):
						child.add_neighbour(another_child)

			Saver.save(child)

func _ready():
	pass
