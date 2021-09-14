extends Node2D

class State:
	var b_jumping = false
	var b_falling = false
	var b_hooked = false
	var b_moving = false
	var disable_movement = false
	var disable_gravity = false

export (float) var max_speed
export (float) var acceleration_time := 0.2
export (float) var deceleration_time := 0.1
export (float) var turn_speed_precent := 0.8
export (float) var movement_damp := 1000

export (float) var jump_speed
export (float) var jump_height # Skacze ciutkę ponad tą wysokość bo jakieś błędy
export (float) var late_jump_time = 0.1

export (float) var hook_length := 50
export (float) var hook_speed := 400
export (float) var one_way_height_boost := 8

onready var character : KinematicBody2D = get_parent()

var input_value := Vector2.ZERO
var b_do_jump := false
var b_do_float := false
var b_enable_damping := false

var velocity := Vector2.ZERO
var state = State.new()

onready var t_late_jump := $"Late Jump"
onready var t_movement_damp := $"Movement Damping"
onready var hook_ray := $Hook

func accelerate(delta : float):
	var b_has_right_direction = sign(velocity.x) == sign(input_value.x)
		
	# Turning
	if !b_has_right_direction && character.is_on_floor():
		velocity.x = -velocity.x * turn_speed_precent

	if abs(velocity.x) >= max_speed:
		return
	
	var acceleration = (max_speed / acceleration_time) * input_value.x
	velocity.x += acceleration * delta

func damping(delta : float):
	if !b_enable_damping:
		b_enable_damping = true
		t_movement_damp.start()

	if t_movement_damp.get_time_left() > 0:
		return
	
	velocity.x = max(max_speed, abs(velocity.x) - movement_damp * delta) * sign(velocity.x)

func movement(delta : float):
	if input_value.x != 0:
		state.b_moving = true
		accelerate(delta)
	else:
		state.b_moving = false
		var deceleration = max_speed / deceleration_time * delta
		velocity.x = max(0, abs(velocity.x) - deceleration) * sign(velocity.x)
	
	if abs(velocity.x) > max_speed && character.is_on_floor():
		damping(delta)
	else:
		b_enable_damping = false

func can_jump():
	var res = true
	res = res and (character.is_on_floor() || t_late_jump.get_time_left() > 0)
	res = res and !state.b_hooked
	return res

# Calculates only first half of jump (when character goes up)
func jump():
	if !can_jump():
		return
	
	state.b_jumping = true
	t_late_jump.stop()
	velocity.y = -jump_speed

func gravity(delta : float):
	if character.is_on_floor() && velocity.y >= 0:
		velocity.y = 1 # If it was 0, body wouldn't touch continously the ground
		state.b_falling = false
		return
	
	# Start fall
	if !state.b_falling:
		state.b_falling = true
		# Last-time jump
		if velocity.y >= 0:
			t_late_jump.start()
	
	if velocity.y >= jump_speed: return
	
	var gravity = (jump_speed * jump_speed) / (2 * jump_height)
	
	if !b_do_jump:
		gravity *= 2
	
	velocity.y += delta * gravity

# Given direction, returns collision point if it is nearer than hook_length
# Otherwise returns inf
func cast_ray(direction : Vector2) -> Vector2:
	assert(direction.is_normalized())
	
	var cast_to = direction * hook_length
	
	hook_ray.set_cast_to(cast_to)
	hook_ray.force_raycast_update()
	if hook_ray.is_colliding():
		return hook_ray.get_collision_point()
	return Vector2.INF

func is_one_way_hooked() -> bool:
	assert(hook_ray.is_colliding())
	assert(hook_ray.get_collider().is_class("TileMap"))
	
	var collision_position = hook_ray.get_collision_point()
	collision_position -= hook_ray.get_collision_normal()
	var map : TileMap = hook_ray.get_collider()
	var cell : Vector2 = map.world_to_map(collision_position - map.position)
	return map.get_tileset().tile_get_shape_one_way(map.get_cellv(cell), 0)


func hook(direction : Vector2):
	var collision_point : Vector2 = cast_ray(direction)
	if collision_point == Vector2.INF: return
	
	state.b_hooked = true
	
	if is_one_way_hooked():
		collision_point.y -= one_way_height_boost
		direction = (collision_point - character.position).normalized() 
	
	
	var end_velocity = direction * hook_speed
	var distance = character.position.distance_to(collision_point)
	var time = 2 * distance / hook_speed
	
	var tween = Tween.new()
	add_child(tween)
	tween.interpolate_property(self, "velocity", Vector2.ZERO, end_velocity, time, Tween.TRANS_LINEAR)
	tween.start()
	yield(tween, "tween_all_completed")
	remove_child(tween)
	
	state.b_hooked = false


func collision():
	
	if character.is_on_ceiling():
		velocity.y = max(velocity.y, 0)
	
	if character.is_on_wall():
		velocity.x = 0
	
func _input(event : InputEvent):
	input_value = Vector2.ZERO
	if Input.is_action_pressed("left"):
		input_value.x -= 1
	if Input.is_action_pressed("right"):
		input_value.x += 1
	if Input.is_action_pressed("duck"):
		input_value.y -= 1
	if Input.is_action_just_pressed("jump"):
		b_do_jump = true
		jump()
	if Input.is_action_just_released("jump"):
		b_do_jump = false
		state.b_jumping = false
	
	if Input.is_action_just_pressed("hook"):
		hook((get_global_mouse_position() - character.position).normalized())

# Called when the node enters the scene tree for the first time.
func _ready():
	pass

func _physics_process(delta):
	
	if !state.b_hooked:
		movement(delta)
		gravity(delta)
	
	character.move_and_slide(velocity, Vector2.UP)
	collision()
