tool
extends Node2D

export (String) var start_level
export (bool) var start = false setget load_start

var loaded_levels := Array()
var needed_levels := Array()

var thread := ThreadedLoad.new()

var current_level : LDtkLevel = null setget change_current_level

func load_start(_v : bool):
	loaded_levels = Array()
	needed_levels = Array()
	thread.queue_load(start_level)
	needed_levels.push_back(start_level)

func load_level():
	while thread.has_loaded_scenes():
		var level : LDtkLevel = thread.get_loaded_scene().instance()
		if find_node(level.name) != null: return
		add_child(level)
		level.set_owner(get_tree().get_edited_scene_root())
		level.connect("found_player", self, "_on_found_player")
		loaded_levels.push_back(level)

func find_levels_to_unload() -> Array:
	var res := Array()
	for child in get_children():
		if child.is_class("LDtkLevel") && !needed_levels.has(child.filename):
			res.push_back(child)
	return res

func unload_level(level : LDtkLevel):
	remove_child(level)
	level.queue_free()

func change_current_level(level : LDtkLevel):
	current_level = level

	var levels_to_load = Array()
	levels_to_load.append_array(current_level.neighbours)
	levels_to_load.push_back(current_level.filename)

	for l in levels_to_load:
		if !needed_levels.has(l):
			thread.queue_load(l)

	needed_levels = levels_to_load

func _ready():
	if Engine.editor_hint: return
	thread.start()
	
	$Garbage.start()
	load_start(true)

func _process(_delta):
	load_level()

func _on_garbage_timeout():
	var to_unload = find_levels_to_unload()
	for level in to_unload:
		unload_level(level)

func _on_found_player(level : LDtkLevel):
	change_current_level(level)
