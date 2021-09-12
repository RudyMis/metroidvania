extends Node

class State:
	var b_jumping = false
	var b_falling = false
	var b_hooked = false
	var b_moving = false

export (float) var max_speed
export (float) var acceleration_time := 0.2
export (float) var deceleration_time := 0.1
export (float) var turn_speed_precent := 0.8
export (float) var jump_speed
export (float) var jump_height # Skacze ciutkę ponad tą wysokość bo jakieś błędy
export (float) var late_jump_time = 0.1

onready var character : KinematicBody2D = get_parent()

var input_value := Vector2.ZERO
var b_do_jump := false
var b_do_float := false

var velocity := Vector2.ZERO
var state = State.new()

onready var t_late_jump := $"Late Jump"

func movement(delta : float):
	if input_value.x != 0:
		state.b_moving = true
		var b_has_right_direction = sign(velocity.x) == sign(input_value.x)
		
		# Turning
		if !b_has_right_direction && character.is_on_floor():
			velocity.x = -velocity.x * turn_speed_precent

		if b_has_right_direction && abs(velocity.x) >= max_speed:
			return
		
		var acceleration = (max_speed / acceleration_time) * input_value.x
		velocity.x += acceleration * delta
	
	else:
		if velocity.x == 0:
			state.b_moving = false
			return
		
		var previous_direction = sign(velocity.x)
		velocity.x -= max_speed / deceleration_time * delta * previous_direction
		if previous_direction != sign(velocity.x):
			velocity.x = 0

func can_jump():
	return (character.is_on_floor() || t_late_jump.get_time_left() > 0)

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

func hook():
	pass

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

# Called when the node enters the scene tree for the first time.
func _ready():
	pass

func _physics_process(delta):
	movement(delta)
	
	gravity(delta)
	
	character.move_and_slide(velocity, Vector2.UP)
	collision()
