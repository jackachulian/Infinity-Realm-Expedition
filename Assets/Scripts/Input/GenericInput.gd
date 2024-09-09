extends Node3D
class_name GenericInput

# State switched to when the move button is pressed while not in delay
@export var move_state : State

# State switched to when attack is requested while not in delay (has buffer on player)
@export var main_attack_state : State

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
var direction: Vector3

# current amount of times player can dash while on cooldown.
# reset to dash_count after dash cooldown
var dashes_left: int = 0

var dash_cooldown_remaining: float = 0

# Clear the attack buffer and lets this input know its attack was registered just now
func clear_main_attack_buffer():
	pass

func is_dash_requested() -> bool:
	return false

func is_main_attack_requested() -> bool:
	return false
	
func is_shield_requested() -> bool:
	return false

func is_move_just_pressed() -> bool:
	return false


func _process(delta):
	dash_cooldown_remaining = move_toward(dash_cooldown_remaining, 0, delta)
	if (dash_cooldown_remaining <= 0):
		dashes_left = dash_count

# Returns the action that the entity is trying to perform.
# May interact with buffers and/or clear them in the process of generating the input
# to be returned to state machine, meaning it should be called once per check_transition,
# only within states
func request_action() -> String:
	# Dash
	if is_dash_requested() and dash_state:
		# dash if not on cooldown or can still dash multiple times in a row
		if dashes_left > 0:
			dash_cooldown_remaining = dash_cooldown
			dashes_left -= 1
			return dash_state.name
	
	# Main Attack
	if is_main_attack_requested():
		clear_main_attack_buffer()
		
		# if current state combos into another attack, return that
		# otherwise, return main attack
		var state = entity.state_machine.current_state
		if state is AttackState and state.combos_into != "":
			return entity.state_machine.current_state.combos_into
		elif main_attack_state:
			return main_attack_state.name	
			
	# Shield
	if is_shield_requested() and shield_state:
		return shield_state.name
			
	# Move
	if is_move_just_pressed() and move_state:
		return move_state.name
		
	return ""
