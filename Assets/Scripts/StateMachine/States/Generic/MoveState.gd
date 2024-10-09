class_name MoveState
extends State

@export var animation_name: String = "Run"

@export var move_stop_state: State

@export var jump_state: State

@export var fall_state: State

# speed that the entity moves in this state
@export var speed: float = 5.0

# if above 0, rotation will be snapped to the nearest increment of this
@export var rotation_snap: float = 0.0

@onready var jump_check: RayCast3D = $JumpCheckRayCast3D


func check_transition(delta: float) -> State:
	# Go to idle when movement stops
	if entity.input.direction == Vector3.ZERO:
		if move_stop_state:
			return move_stop_state
		else:
			return entity.get_state("Idle")
			
	# When running into a wall, auto-jump
	if entity.is_on_floor() and entity.is_on_wall():
		# Only jump if wall normal is close to opposite of input vector
		if (entity.get_wall_normal() + entity.movement.direction).length() <= 0.5:
			# Check raycast to make sure there is a ledge the player can jump onto in front of them. 
			# if the ledge is too tall, the ray won't hit anything.
			if jump_check.is_colliding() and (jump_check.get_collision_point().y - entity.global_position.y) >= 0.01:
				return jump_state
		
	# Accept general action. but don't go into move while already in move 
	# (would cause incorrect anim loop)
	var requested_action: State = entity.input.request_action()
	if requested_action and requested_action.name != "Move":
		return requested_action
		
	# check for fall
	if entity.velocity.y < 0:
		return fall_state;
		
	return null
	
func physics_update(delta: float):
	entity.movement.direction = entity.input.direction
	
func update(delta: float):
	entity.rotation.y = entity.input.uniform_input_angle()
	
func on_enter_state():
	entity.anim.play(animation_name)
	entity.movement.speed = speed
