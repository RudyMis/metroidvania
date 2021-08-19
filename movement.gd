extends Node

export (float) var max_speed
export (float) var acceleration_time := 0.2
export (float) var deceleration_time := 0.1
export (float) var jump_speed
export (float) var jump_height # Skacze ciutkę ponad tą wysokość bo jakieś błędy

onready var character : KinematicBody2D = get_parent()

var input_value := Vector2.ZERO
var b_do_jump := false

var velocity := Vector2.ZERO
var b_is_jumping := false

func movement(delta : float):
	if input_value.x != 0:
		# Turning
		if sign(velocity.x) != sign(input_value.x) && character.is_on_floor(): 
			velocity.x = 0
		
		if abs(velocity.x) >= max_speed: return
		velocity.x += (max_speed / acceleration_time) * delta * input_value.x
	else:
		if velocity.x == 0: return
		
		var s = sign(velocity.x)
		velocity.x -= max_speed / deceleration_time * delta * s
		if s != sign(velocity.x) || velocity.x == 0:
			velocity.x = 0


# Calculates only first half of jump (when character goes up)
func jump(delta : float):
	if !b_do_jump: # Stop jumping
		velocity.y = max(velocity.y, 0)
		b_is_jumping = false
		return
	
	if (velocity.y > 0 && !character.is_on_floor()) || character.is_on_ceiling(): # Fall
		b_is_jumping = false
		b_do_jump = false
		return

	if character.is_on_floor(): # Start jumping
		b_is_jumping = true
		velocity.y = -jump_speed

func fall(delta : float):
	if character.is_on_floor() && velocity.y >= 0:
		velocity.y = 1 # If it was 0, body wouldn't touch continously the ground
		return
	
	if velocity.y >= jump_speed: return
	velocity.y += delta * (jump_speed * jump_speed) / (2 * jump_height)


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
	if Input.is_action_just_released("jump"):
		b_do_jump = false

# Called when the node enters the scene tree for the first time.
func _ready():
	pass # Replace with function body.

func _physics_process(delta):
	movement(delta)
	fall(delta)
	jump(delta)
	character.move_and_slide(velocity, Vector2(0, -1))
