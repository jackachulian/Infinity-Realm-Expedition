class_name MoveState
extends State

@export var animation_name: String = "Run"

@export var move_stop_state: State

@export var jump_state: State

@export var fall_state: State

# speed that the entity moves in this state
@export var speed: float = 5.0

@onready var jump_check: RayCast3D = $JumpCheckRayCast3D

# The wall in front of the player can be at most this high above the entity's feet to trigger an auto jump
@export var max_height_to_jump: float = 1.5

func check_transition(delta: float) -> State:
	# Go to idle when movement stops
	if entity.input.direction == Vector3.ZERO:
		if move_stop_state:
			return move_stop_state
		else:
			return entity.get_state("Idle")
			
	# When running into a wall, auto-jump
	if jump_state and entity.is_on_floor() and entity.is_on_wall():
		# Only jump if wall normal is close to opposite of input vector
		# Check raycast to make sure there is a ledge the player can jump onto in front of them. 
		if (entity.get_wall_normal() + entity.movement.direction.normalized()).length() <= 0.65 and jump_check.is_colliding():
			var wall_height = jump_check.get_collision_point().y - entity.global_position.y
			var max_height = max_height_to_jump / sqrt(entity.movement.current_accel_multiplier)
			if wall_height >= 0.05 and wall_height < max_height and jump_check.get_collision_normal() != Vector3.ZERO:
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
	entity.rotation.y = entity.input.uniform_input_angle(false)
	
func on_enter_state():
	entity.anim.play(animation_name)
	entity.movement.speed = speed
