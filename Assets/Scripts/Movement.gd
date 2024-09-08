extends Node
class_name Movement

# Top speed
# Modified by states. ex. infinity's run speed is stored in the run state 
# and it modifies this value within the state.
var speed := 5.0

@export var move_accel: int = 60.0
@export var stop_decel: int = 45.0
@export var air_decel: int = 30.0
@export var stun_decel: int = 10.0
@export var gravity: float = 25.0

@onready var entity: Entity = $".."

# May be modified by move states
# ex. infinity's run state copies inputted direction to this move direction during run
var direction: Vector3 = Vector3.ZERO

func _physics_process(delta):
	# Apply root motion (subtract instead of add because model is flipped 180 degrees)
	var root_motion_delta = entity.anim.get_root_motion_position()
	entity.position -= entity.get_quaternion() * root_motion_delta;
	
	# store y velocity and set to 0, so that x/z calculations do not use yvel at all
	var stored_yvel = entity.velocity.y;
	entity.velocity.y = 0
	
	# Accelerate into in input direction if non-zero input and not stunned
	if direction != Vector3.ZERO and not entity.is_hit_stunned():
		entity.velocity = entity.velocity.move_toward(direction * speed, move_accel * delta)
	# Otherwise, decelerate towards zero if not in midair (simulates friction with ground)
	elif entity.is_on_floor():
		var decel;
		if entity.is_hit_stunned():
			decel = stun_decel
		elif not entity.is_on_floor():
			decel = air_decel
		else:
			decel = stop_decel
		entity.velocity = entity.velocity.move_toward(Vector3.ZERO, decel * delta)
	
	# restore stored yvel
	entity.velocity.y = stored_yvel
	
	if not entity.is_on_floor():
		entity.velocity.y -= gravity * delta
		
	entity.move_and_slide()
