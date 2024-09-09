extends State
class_name NoBehaviourState

#Standard state that will fit a lot of use cases.

# Animtion to play on entering this state, if not empty.
@export var animation_name: String = "Idle"

# If true, will try to use a requested action at the end of the animation
@export var action_on_anim_finish: bool = false

# If not null, switch to this state depending on SwitchMode. 
# If action_on_anim_finish is true, that will be checked first, then to this state if no requested action.
@export var state_on_anim_finish: String



# If not null, switch to this state when touching the ground.
@export var grounded_state: String

# If not null, switch to this state when falling (yvel less than 0).
@export var falling_state: String

# Immediate velocity force to apply to this entity upon entering this state (entity z forward).
@export var instant_velocity_on_enter: Vector3

enum RotateMode {
	NONE,
	FACE_INPUT_AT_START, # player turns to face input direction when entering the state
	FACE_INPUT_DURING, # player will face in inputted direction during this state
	FACE_KNOCKBACK # player will face opposite the velocity direction (used for hurt states)
}
@export var rotate_mode: RotateMode = RotateMode.NONE

# if above 0, rotation will be snapped to the nearest increment of this if face_input
@export var rotation_snap: float = 45.0

# If true, movement will be set to 0 upon entering this state.
enum MovementMode {
	STOP,
	FROM_INPUT,
	NO_CHANGE,
	SET_SPEED_ON_ENTER
}
@export var movement_mode: MovementMode = MovementMode.STOP

@export var movement_speed: float

# if above 0, overrides movement deceleration during this state
@export var decel_override: float = -1

# If true, can cancel into 
@export var can_use_actions: bool

# If can_use_actions, minimum state time elapsed before actions can be registered.
@export var action_delay: float = 0.0

# If true, this state cannot switch to itself via action request.
@export var prevent_self_action_request: bool = false

func check_transition(delta: float) -> String:	
	if anim_finished:
		if action_on_anim_finish:
			var requested_action = entity.input.request_action()
			if requested_action != "":
				return requested_action
	
		# after possible action check, if branch skipped or no action requested, go to state on anim finished.
		if state_on_anim_finish != "":
			return state_on_anim_finish
		
	if grounded_state != "" and entity.is_on_floor():
		return grounded_state
		
	if falling_state != "" and entity.velocity.y < 0:
		return falling_state
		
	if can_use_actions and time_elapsed >= action_delay:
		var requested_action = entity.input.request_action()
		# If a state is requested, return that action
		# Prevent same state if prevent_self_action_request bool is true, 
		# but ignore that clause if requested action isn't this state
		if requested_action != "" and (not prevent_self_action_request or requested_action != name):
			return requested_action
	
	return ""

func update(delta: float):
	update_rotation(delta)
	
func update_rotation(delta: float):
	if rotate_mode == RotateMode.NONE:
		return
	
	var input_angle
	
	if rotate_mode == RotateMode.FACE_INPUT_DURING:
		input_angle = entity.input.uniform_input_angle()
	elif rotate_mode == RotateMode.FACE_KNOCKBACK:
		if entity.velocity == Vector3.ZERO:
			return
		var screen_uniform_vel = entity.movement.screen_uniform_vector(entity.velocity)
		input_angle = atan2(screen_uniform_vel.x, screen_uniform_vel.z)
		var snap_rad = deg_to_rad(45)
		input_angle = round(input_angle / snap_rad) * snap_rad
	else:
		return
		
	entity.face_angle(input_angle)

func physics_update(delta: float):
	if movement_mode == MovementMode.FROM_INPUT:
		entity.movement.direction = entity.input.direction

func on_enter_state():
	if movement_mode == MovementMode.SET_SPEED_ON_ENTER:
		entity.movement.speed = movement_speed
	
	if animation_name != "":
		entity.anim.play(animation_name)
	if movement_mode == MovementMode.STOP:
		entity.movement.direction = Vector3.ZERO
	
	var input_angle = entity.input.uniform_input_angle()
	if rotate_mode == RotateMode.FACE_INPUT_AT_START or rotate_mode == RotateMode.FACE_INPUT_DURING:
		entity.face_angle(input_angle)
	if instant_velocity_on_enter:
		entity.velocity = entity.movement.screen_uniform_vector(instant_velocity_on_enter.rotated(Vector3.UP, input_angle));

func get_decel_override():
	return decel_override
