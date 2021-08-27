extends Node

class_name ThreadedLoad

signal loaded

var mutex : Mutex
var thread : Thread
var semaphore : Semaphore
var exit := false # lock
var scenes_to_load := Array() # lock
var loaded_scenes := Array() # lock
var started = false

func start():
	if started: return
	started = true
	mutex = Mutex.new()
	thread = Thread.new()
	semaphore = Semaphore.new()
	
	thread.start(self, "_thread")

func stop():
	started = false

	mutex.lock()
	exit = true
	mutex.unlock()
	
	semaphore.post()

func has_loaded_scenes() -> bool:
	mutex.lock()
	var b_has_scene = !loaded_scenes.empty()
	mutex.unlock()
	
	return b_has_scene

func get_loaded_scene() -> PackedScene:
	mutex.lock()
	var scene = loaded_scenes.pop_front()
	mutex.unlock()
	
	return scene

func queue_load(path : String):
	if mutex == null: return
	mutex.lock()
	scenes_to_load.push_back(path)
	mutex.unlock()
	
	semaphore.post()

func _thread(_u):
	while true:
		mutex.lock()
		var number_of_scenes = scenes_to_load.size()
		mutex.unlock()
		
		if number_of_scenes != 0:
			for i in range(number_of_scenes):
				mutex.lock()
				var to_load = scenes_to_load.pop_front()
				mutex.unlock()
				
				var scene = load(to_load)
				
				mutex.lock()
				loaded_scenes.push_back(scene)
				mutex.unlock()
			call_deferred("emit_signal", "loaded")
		else:
			semaphore.wait()
		
		mutex.lock()
		var should_quit = exit
		mutex.unlock()
		
		if should_quit: return

func _ready():
	pass
