tool
extends Node

# Saves node if it is it's owner 
func save(node : Node, save_path : String = ""):
	if node.filename == "" && save_path == "":
		print("Nie ma co zapisywać")
		return
	var pack := PackedScene.new()
	pack.pack(node)
	
	save_path = save_path if node.filename == "" else node.filename
	var err = ResourceSaver.save(save_path, pack)
	if err != 0:
		print(err)

func _ready():
	pass
