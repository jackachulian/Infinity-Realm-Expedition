class_name PlayerInput
extends GenericInput

@onready var camera: Node3D = get_viewport().get_camera_3d()

# Amount of input buffer for the attack button (seconds)
@export var attack_buffer: float = 0.25

# Amount of input buffer for the move buttons for cancelling actions (seconds
@export var move_buffer: float = 0.25

# When attack inputs are pressed, this statemachine's state will be changed if it is not in delay
@onready var state_machine: StateMachine = $"../StateMachine"


# counts down seconds for attack buffer
var attack_buffer_remaining: float = 0

# counts down seconds for move buffer
var move_buffer_remaining: float = 0

# total amt. of seconds that inputted direction has been non-zero
var move_input_hold_elapsed: float = 0

# true when dash requested. may need to wait until after brief multi-direction leeway window passes
var dash_press_queued: bool = false

func _process(delta):
	super._process(delta)
	var input_dir = Input.get_vector("left", "right", "forward", "back")
	var forward = Vector3(input_dir.x, 0, input_dir.y).rotated(Vector3.UP, camera.global_rotation.y)
	direction = forward.normalized()
	
	if input_dir == Vector2.ZERO:
		move_input_hold_elapsed = 0
	else:
		move_input_hold_elapsed += delta
	
	if Input.is_action_just_pressed("attack"):
		attack_buffer_remaining = attack_buffer
	elif attack_buffer_remaining > 0:
		attack_buffer_remaining = move_toward(attack_buffer_remaining, 0, delta)
		
	if is_move_key_just_pressed():
		move_buffer_remaining = move_buffer
	elif move_buffer_remaining > 0:
		move_buffer_remaining = move_toward(move_buffer_remaining, 0, delta)
	
func is_move_key_just_pressed():
	return Input.is_action_just_pressed("forward") or Input.is_action_just_pressed("back") or Input.is_action_just_pressed("left") or Input.is_action_just_pressed("right")
	
func is_dash_requested():
	# Dash while moving and shield just pressed 
	
	# move must be held for just a tiny bit longer than 0, allows leeway for diagonal dash input
	var move_to_dash = Input.is_action_just_pressed("shield") and direction != Vector3.ZERO and move_input_hold_elapsed > 0.05
	# Likewise, dash while shielding and move just pressed
	var shield_to_dash = Input.is_action_pressed("shield") and is_move_requested()
	
	return move_to_dash or shield_to_dash
	
func is_main_attack_requested():
	# Will request attack while attack buffer is still counting down and not 0
	# When an attack is registered, attack buffer remaining will be set to 0
	return attack_buffer_remaining > 0

func is_move_requested():
	# When move is registered OR an attack is registered, will be set to 0. prevents move inputs from messing up attacks before they start.
	return move_buffer_remaining > 0
	
func is_shield_requested():
	# Shield while holding shield button and not moving
	# Dash is checked before shield in GenericInput. Otherwise, shield would always be inputted
	return Input.is_action_pressed("shield")

# Called when an attack is registered by the state machine. 
# ensures one attack input doesn't trigger multiple attacks.
func clear_main_attack_buffer():
	attack_buffer_remaining = 0
	move_buffer_remaining = 0
	
# Called when an attack is registered by the state machine. 
# ensures one attack input doesn't trigger multiple attacks.
func clear_move_buffer():
	move_buffer_remaining = 0
