extends Resource

class_name MapData

var map_loader

export var p_paths := Array()
export var right := Array()
export var left := Array()
export var up := Array()
export var down := Array()

var placeholders := Array()

func sort_right(a : int, b : int):
	return placeholders[a].rect.position.x > placeholders[b].rect.position.x
func sort_left(a : int, b : int):
	return placeholders[a].rect.end.x < placeholders[b].rect.end.x
func sort_up(a : int, b : int):
	return placeholders[a].rect.position.y > placeholders[b].rect.position.y
func sort_down(a : int, b : int):
	return placeholders[a].rect.end.y < placeholders[b].rect.end.y

func init(ml : Node2D):
	map_loader = ml

func sort():
	for i in range(placeholders.size()):
		right.push_back(i)
		left.push_back(i)
		up.push_back(i)
		down.push_back(i)
	right.sort_custom(self, "sort_right")
	left.sort_custom(self, "sort_left")
	up.sort_custom(self, "sort_up")
	down.sort_custom(self, "sort_down")

func clear():
	right = Array()
	left = Array()
	up = Array()
	down = Array()
	placeholders = Array()
	p_paths = Array()

func nodes_to_paths(nodes : Array) -> Array:
	var res := Array()
	for n in nodes:
		res.push_back(map_loader.get_path_to(n))
	return res

func paths_to_nodes(paths : Array) -> Array:
	var res := Array()
	for path in paths:
		res.push_back(map_loader.get_node(path))
	return res

static func load_data(from : String, node : Node) -> MapData:
	var data : MapData = ResourceLoader.load(from, "MapData")
	data.map_loader = node
	data.placeholders = data.paths_to_nodes(data.p_paths)
	return data

func save(to : String):
	p_paths = nodes_to_paths(placeholders)
	ResourceSaver.save(to, self)

func find_current_level(position : Vector2):
	for node in placeholders:
		if node.rect.has_point(position):
			return node
	print("Gracz wypadł z mapy potencjalnie")
	return null

func _init():
	clear()
