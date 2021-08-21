tool
extends Node2D

export (String) var scene_path
export (bool) var create = false setget set_create
export (PackedScene) var ps_placeholder
export (String) var save_file
export (float) var load_distance = 100
export (float) var unload_distance = 200

var player : KinematicBody2D = null

var data := MapData.new()
var loader = ThreadedLoad.new()

func set_create(value : bool):
	destroy_map()
	load_map()
#	pass

func create_placeholder(node : Node2D):
	var new_node = ps_placeholder.instance()
	new_node.name = node.name
	new_node.rect = node.rect if "rect" in node else Rect2(node.position, Vector2.ZERO)
	new_node.scene_path = node.filename
	add_child(new_node)
	new_node.set_owner(get_tree().get_edited_scene_root())
	return new_node

func load_map():
	if ps_placeholder == null: return
	
	data.init(self)
	
	# TODO: ResourceLoader.load_interactive
	# Raczej mało ważne
	var scene : Node2D = load(scene_path).instance()
	if scene == null:
		print("Nie ma takiego poziomu")
		return
	
	for child in scene.get_children():
		if !child.is_in_group("Player"):
			var ph = create_placeholder(child)
			data.placeholders.push_back(ph)
		else:
			player = load(child.filename).instance()
			player.position = child.position
			add_child(player)
			player.set_owner(get_tree().get_edited_scene_root())
	
	data.sort()
	data.save(save_file)

func destroy_map():
	data.clear()
	for child in get_children():
		remove_child(child)
		child.queue_free()

func queue_load(ph : Node):
	if !("scene_path" in ph): return
	

func add_loaded_scenes():
	var scene = loader.get_loaded_scene()
	if scene == null: return
	add_child(scene.instance())
	add_loaded_scenes()

func first_load():
	player = get_tree().get_nodes_in_group("Player")[0]
	
	data = MapData.load_data(save_file, self)
	data.init(self)
	
	var current_level = data.find_current_level(player.position)
	if current_level == null || !("scene_path" in current_level): return
	loader.queue_load(current_level.scene_path)


func _ready():
	if Engine.editor_hint: return
	
	loader.start()
	loader.connect("loaded", self, "add_loaded_scenes")
	
	first_load()
