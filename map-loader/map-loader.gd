tool
extends Node2D

export (String) var scene_path
export (bool) var create = false setget set_create, get_create
export (PackedScene) var placeholder

func set_create(value : bool):
	create = value
	if create: load_map()
	else: destroy_map()

func get_create() -> bool:
	return create

func create_placeholder(node : Node2D):
	var new_node = placeholder.instance()
	new_node.rect = node.rect
	new_node.scene_path = node.filename
	add_child(new_node)
	new_node.set_owner(self)

func load_map():
	# TODO: ResourceLoader.load_interactive
	var scene : Node2D = load(scene_path).instance()
	if scene == null:
		print("Nie ma takiego poziomu")
		return
	
	for child in get_children():
		pass

func destroy_map():
	pass

func _ready():
	pass
