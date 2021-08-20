extends Node2D

# Zakładam, że jest w miarę mało tilemap
# Jest dużo tilemap o tej samej nazwie
func get_current_tilemap(pos : Vector2, tilemap_name : String) -> TileMap:
	var tilemaps := Array()
	for child in get_children():
		for grand_child in child.get_children():
			if (grand_child.is_class("tile_map") && 
				grand_child.name == tilemap_name && 
				grand_child.get_used_rect().has_point(pos)):
				return grand_child
	return null

func _ready():
	pass


