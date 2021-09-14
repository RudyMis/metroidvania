tool
extends Node

# Saves node if it is it's owner 
func save(node : Node, save_path : String = ""):
	if node.filename == "" && save_path == "":
		print("Nie ma co zapisywać")
		return
	var pack := PackedScene.new()
	if pack.pack(node) != 0:
		print("Błąd przy pakowaniu")
	
	
	save_path = save_path if node.filename == "" else node.filename
	if ResourceSaver.save(save_path, pack) != 0:
		print("Błąd przy zapisywaniu")

func _ready():
	pass
