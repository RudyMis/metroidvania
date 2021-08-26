tool
extends Node2D

class_name LDtkLevel
func is_class(name): return name == "LDtkLevel" || .is_class(name)
func get_class(): return "LDtkLevel"

signal found_player

export (Rect2) var rect
export (float) var refresh_time := 1.0
export (String) var ground_child_name := "Ground"

export (Array, String) var neighbours := Array() setget set_neighbours
func set_neighbours(arr : Array): neighbours = arr


var t_refresh : Timer
var b_has_player := false

onready var ground : TileMap = get_node(ground_child_name)


func save_level():
	var pack = PackedScene.new()
	pack.pack(self)
	ResourceSaver.save(filename, pack)

func add_neighbour(node : Node):
	neighbours.push_back(node.filename)


func has_player():
	if ground == null:
		printerr("Nie mam ziemi")
		return false
	
	var players = get_tree().get_nodes_in_group("Player")
	if players.size() == 0: return false
	
	return ground.get_used_rect().has_point(players[0].position)

func _ready():
	t_refresh = Timer.new()
	t_refresh.set_wait_time(refresh_time)
	t_refresh.connect("timeout", self, "_on_refresh")
	add_child(t_refresh)

func _on_refresh():
	if has_player():
		if b_has_player == false:
			emit_signal("found_player")
		b_has_player = true
	else:
		b_has_player = false
