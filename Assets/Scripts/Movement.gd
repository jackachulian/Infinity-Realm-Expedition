extends Node
class_name Movement

# Top speed
# Modified by states. ex. infinity's run speed is stored in the run state 
# and it modifies this value within the state.
var speed := 5.0

@export var move_accel: float = 60.0
@export var air_accel: float = 30.0
@export var stop_decel: float = 45.0
@export var air_decel: float = 30.0
@export var stun_decel: float = 10.0
@export var rise_gravity: float = 25.0
@export var fall_gravity: float = 25.0

@export var root_motion_multiplier: float = 0.7

@onready var entity: Entity = $".."

# May be modified by move states
# ex. infinity's run state copies inputted direction to this move direction during run
var direction: Vector3 = Vector3.ZERO

# Current gravity multiplier. May be modified by states
var gravity_multiplier: float = 1.0

# The matrix that stretches out movements so that characters move at a uniform speed on the screen.
const scale_matrix = Transform3D()

# Points in the direction that objects should be scaled in to produce screen uniform movement
var camera_axis: Vector3
# amont to scale the camera forward axis movement by. set to 1 for no change
@onready var scale_factor: float = 1.25

var current_speed_multiplier: float
var current_accel_multiplier: float

func update_camera_screen_uniform():
	camera_axis = Camera3DTexelSnapped.instance.global_transform.basis.z
	camera_axis.y = 0
	camera_axis = camera_axis.normalized()
	
func screen_uniform_vector(v: Vector3) -> Vector3:
	var v_parallel = camera_axis * v.dot(camera_axis)
	var v_perpendicular = v - v_parallel
	var v_stretched = v_perpendicular + v_parallel * scale_factor
	return v_stretched
	
func inverse_screen_uniform_vector(v: Vector3) -> Vector3:
	var v_parallel = camera_axis * v.dot(camera_axis)
	var v_perpendicular = v - v_parallel
	var v_stretched = v_perpendicular + v_parallel / scale_factor
	return v_stretched
	
func _physics_process(delta):
	update_camera_screen_uniform()
	
	current_speed_multiplier = 1.0
	current_accel_multiplier = 1.0
	for status: StatusEffect in entity.status_effects.values():
		current_speed_multiplier *= status.speed_multiplier
		current_accel_multiplier *= status.accel_multiplier
	
	# Apply root motion (subtract instead of add because model is flipped 180 degrees)
	var root_motion_delta = entity.anim.get_root_motion_position()
	entity.position -= screen_uniform_vector(entity.get_quaternion() * root_motion_delta * root_motion_multiplier);
	
	# store y velocity and set to 0, so that x/z calculations do not use yvel at all
	var stored_yvel = entity.velocity.y;
	entity.velocity.y = 0
	
	# temporarily undo screen uniform velocity, to prevent uneven acceleration
	entity.velocity = inverse_screen_uniform_vector(entity.velocity);
	
	# Accelerate into in input direction if non-zero input and not stunned
	if direction != Vector3.ZERO and not entity.is_hit_stunned():
		var accel = move_accel if entity.is_on_floor() else air_accel
		entity.velocity = entity.velocity.move_toward(direction * speed * current_speed_multiplier, accel * delta * current_accel_multiplier)
	# Otherwise, decelerate towards zero if not in midair (simulates friction with ground)
	else:
		var decel;
		
		var decel_override = entity.state_machine.current_state.get_decel_override() if entity.state_machine and entity.state_machine.current_state else -1
		if decel_override >= 0:
			decel = decel_override
		elif entity.is_hit_stunned():
			decel = stun_decel
		elif not entity.is_on_floor():
			decel = air_decel
		else:
			decel = stop_decel
			
		entity.velocity = entity.velocity.move_toward(Vector3.ZERO, decel * delta * lerp(current_accel_multiplier, 1.0, 0.33))
	
	# re-apply screen uiform movement
	entity.velocity = screen_uniform_vector(entity.velocity);
	
	# restore stored yvel
	entity.velocity.y = stored_yvel
	
	if not entity.is_on_floor():
		entity.velocity.y -= (rise_gravity if entity.velocity.y > 0 else fall_gravity) * gravity_multiplier * delta * current_accel_multiplier
		
	entity.move_and_slide()
