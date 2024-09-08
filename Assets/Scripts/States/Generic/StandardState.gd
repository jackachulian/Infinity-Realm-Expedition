extends State
class_name NoBehaviourState

#Standard state that will fit a lot of use cases.

# Animtion to play on entering this state, if not empty.
@export var animation_name: String = "Idle"

# If not null, switch to this state depending on SwitchMode.
@export var state_on_anim_finish: String

# If not null, switch to this state when touching the ground.
@export var grounded_state: String

# If not null, switch to this state when falling (yvel less than 0).
@export var falling_state: String

# Immediate velocity force to apply to this entity upon entering this state (entity z forward).
@export var instant_velocity_on_enter: Vector3

# If true, player will face in inputted direction during this state
@export var face_input: bool = false

# if above 0, rotation will be snapped to the nearest increment of this if face_input
@export var rotation_snap: float = 45.0

# If true, movement will be set to 0 upon entering this state.
enum MovementMode {
	STOP,
	FROM_INPUT,
	NO_CHANGE
}
@export var movement_mode: MovementMode = MovementMode.STOP

@export var movement_speed: float

func check_transition(delta: float) -> String:	
	if anim_finished and state_on_anim_finish != "":
		return state_on_anim_finish
		
	if grounded_state != "" and entity.is_on_floor():
		return grounded_state
		
	if falling_state != "" and entity.velocity.y < 0:
		return falling_state
	
	return ""

func update(delta):
	if face_input:
		var angle = atan2(-entity.input.direction.x, -entity.input.direction.z)
		if rotation_snap > 0:
			var snap = deg_to_rad(rotation_snap)
			angle = round(angle / snap) * snap
		entity.rotation.y = angle

func physics_update(delta: float):
	if movement_mode == MovementMode.FROM_INPUT:
		entity.movement.direction = entity.input.direction

func on_enter_state():
	if movement_mode != MovementMode.NO_CHANGE:
		entity.movement.speed = movement_speed
	
	if animation_name != "":
		entity.anim.play(animation_name)
	if movement_mode == MovementMode.STOP:
		entity.movement.direction = Vector3.ZERO
	if instant_velocity_on_enter:
		entity.velocity += instant_velocity_on_enter.rotated(Vector3.UP, entity.rotation.y);
