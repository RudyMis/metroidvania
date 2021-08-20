tool
extends EditorImportPlugin


enum Presets { PRESET_DEFAULT, PRESET_COLLISIONS }
var LDtk = preload("LDtk.gd").new()

var prefixes : Dictionary = {"A" : Area2D}


func get_importer_name():
	return "LDtk.import"


func get_visible_name():
	return "LDtk Scene"


func get_priority():
	return 1


func get_import_order():
	return 100


func get_resource_type():
	return "PackedScene"


func get_recognized_extensions():
	return ["ldtk"]


func get_save_extension():
	return "tscn"


func get_preset_count():
	return Presets.size()


func get_preset_name(preset):
	match preset:
		Presets.PRESET_DEFAULT:
			return "Default"
		Presets.PRESET_COLLISIONS:
			return "Import Collisions"

func get_import_options(preset):
	return [
		{
			"name": "Import_Collisions",
			"default_value": preset == Presets.PRESET_COLLISIONS
		},
		{
			"name": "Import_Custom_Entities",
			"default_value": true,
			"hint_string": "Import entities as this project's scenes."
		},
		{
			"name": "Import_Metadata",
			"default_value": true,
			"hint_string": "Import entity fields as metadata."
		},
		{
			"name": "Import_YSort_Entities_Layer",
			"default_value": false
		},
		{
			"name": "Subscenes_Save_Folder",
			"default_value": "res://"
		}
	]

func get_option_visibility(option, options):
	return true

func import(source_file, save_path, options, platform_v, r_gen_files):
	# load LDtk map
	LDtk.map_data = source_file

	var map = Node2D.new()
	map.name = source_file.get_file().get_basename()
	
	# add levels as Node2D
	for level in LDtk.map_data.levels:
		var new_level = load(import_level(level, options)).instance()
		map.add_child(new_level)
		new_level.set_owner(map)

	var packed_scene = PackedScene.new()
	packed_scene.pack(map)

	return ResourceSaver.save("%s.%s" % [save_path, get_save_extension()], packed_scene)

func import_level(level, options) -> String:
	var new_level = preload("LDtkLevel/LDtkLevel.tscn").instance()
	var save_path = options.Subscenes_Save_Folder + "/" + level.identifier + "." + get_save_extension() 
	 
	new_level.name = level.identifier
	new_level.scene_path = save_path
	new_level.rect = Rect2(Vector2(level.worldX, level.worldY), Vector2(level.pxWid, level.pxHei))

	# add layers
	var layerInstances = get_level_layerInstances(level, options)
	for layerInstance in layerInstances:
		var pref = get_matching_prefix(layerInstance.name)
		if pref != "":
			var node = prefixes[pref].new()
			new_level.add_child(node)
			node.set_owner(new_level)
			node.add_child(layerInstance)
			layerInstance.set_name(layerInstance.name.right(pref.length() + 1))
			node.set_name(layerInstance.name)
			layerInstance.set_collision_use_parent(true)
		else:
			new_level.add_child(layerInstance)
		layerInstance.set_owner(new_level)

		for child in layerInstance.get_children():
			child.set_owner(new_level)
			
			if not options.Import_Custom_Entities:
				for grandchild in child.get_children():
					grandchild.set_owner(new_level)
	
	# Save level as separate file
	var packed_level = PackedScene.new()
	packed_level.pack(new_level)
	var err = ResourceSaver.save(save_path, packed_level)
	if err != OK:
		print("Error while saving files %i" % err)
		return ""
	
	return save_path

#create layers in level
func get_level_layerInstances(level, options):
	var layers = []
	var i = level.layerInstances.size()
	for layerInstance in level.layerInstances:
		match layerInstance.__type:
			'Entities':
				var new_node = null
				if options.Import_YSort_Entities_Layer and layerInstance.__identifier.begins_with("YSort"):
					new_node = YSort.new()
				else:
					new_node = Node2D.new()
				new_node.z_index = i
				new_node.name = layerInstance.__identifier
				var entities = LDtk.get_layer_entities(layerInstance, level, options)
				for entity in entities:
					new_node.add_child(entity)

				layers.push_front(new_node)
			'Tiles', 'IntGrid', 'AutoLayer':
				var new_layer = LDtk.new_tilemap(layerInstance, level)
				if new_layer:
					new_layer.z_index = i
					layers.push_front(new_layer)

		if layerInstance.__type == 'IntGrid':
			var collision_layer = LDtk.import_collisions(layerInstance, level, options)
			if collision_layer:
				collision_layer.z_index = i
				layers.push_front(collision_layer)

		i -= 1

	return layers

func get_matching_prefix(text : String) -> String:
	for pref in prefixes: # Iteruje po kluczach
		if (text.begins_with(pref) && 
			(text.length() > pref.length() && text[pref.length()] == '_')):
			return pref
	return ""
