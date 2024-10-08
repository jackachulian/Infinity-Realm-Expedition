extends Node3D
class_name GenericInput

# State switched to when the move button is pressed while not in delay
@export var move_state : State

# Melee attack state that is used if there is no weapon equipped. only really used on enemies who don't use weapons. 
# don't think im going to give playable characters weaponless melee attacks
@export var main_attack_state: State

# State switched to when dash is requested while not in delay
@export var dash_state: State

# State switched to when shield is requested while not in delay
@export var shield_state: State

# Cooldown between when dash inputs will be accepted
@export var dash_cooldown: float = 1.0

# Amount of times the player can dash in a row while still on cooldown
@export var dash_count: int = 2

@onready var entity: Entity = $".."

# movement-related states read from this to decide behaviour for move state, dash state, etc.
var direction: Vector3 :
	set(value):
		direction = value
		if direction != Vector3.ZERO:
			facing = direction

# same as direction, but is not updated when input direction is zero (not moving).
var facing: Vector3 = Vector3.FORWARD

# current amount of times player can dash while on cooldown.
# reset to dash_count after dash cooldown
var dashes_left: int = 0

var dash_cooldown_remaining: float = 0

# Clear the attack buffer and lets this input know its attack was registered just now
func clear_main_attack_buffer():
	pass
	
# Clear the move buffer and lets this input know its move *or attack* was registered just now
func clear_move_buffer():
	pass

func is_dash_requested() -> bool:
	return false

func is_main_attack_requested() -> bool:
	return false
	
func is_shield_requested() -> bool:
	return false

func is_move_requested() -> bool:
	return false


func _process(delta):
	dash_cooldown_remaining = move_toward(dash_cooldown_remaining, 0, delta)
	if (dash_cooldown_remaining <= 0):
		dashes_left = dash_count

func uniform_input_angle(snap: bool = true):
	var uniform_input = entity.movement.screen_uniform_vector(Vector3(-facing.x, 0, -facing.z))
	var angle = atan2(uniform_input.x, uniform_input.z)
	if snap:
		var snap_rad = deg_to_rad(45)
		angle = round(angle / snap_rad) * snap_rad
	return angle

# Returns the action that the entity is trying to perform.
# May interact with buffers and/or clear them in the process of generating the input
# to be returned to state machine, meaning it should be called once per check_transition,
# only within states
func request_action() -> State:
	# Dash
	# Can only dash when on the ground... sorry no air dash
	if is_dash_requested() and dash_state and entity.is_on_floor():
		# dash if not on cooldown or can still dash multiple times in a row
		if dashes_left > 0:
			# Must either not be touching a wall or not facing straight into it
			var moving_towards_wall = entity.is_on_wall() and entity.get_wall_normal().angle_to(-entity.movement.direction) < deg_to_rad(15)
			if not moving_towards_wall:
				dash_cooldown_remaining = dash_cooldown
				dashes_left -= 1
				return dash_state
	
	# Main Attack
	if is_main_attack_requested():
		clear_main_attack_buffer()
		clear_move_buffer()
		
		# if current state combos into another attack, return that
		# otherwise, return main attack
		var state = entity.state_machine.current_state
		if state is AttackState and state.combos_into:
			return entity.state_machine.current_state.combos_into
		elif entity.weapon:
			return entity.weapon.entry_state
		else:
			return main_attack_state
			
	# Shield
	if is_shield_requested() and shield_state:
		return shield_state
			
	# Move
	if is_move_requested() and move_state:
		clear_move_buffer()
		
		return move_state
		
	return null
