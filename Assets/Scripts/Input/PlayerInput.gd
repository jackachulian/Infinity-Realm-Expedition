class_name PlayerInput
extends GenericInput

@onready var camera: Node3D = get_viewport().get_camera_3d()

# Amount of input buffer for the attack button (seconds)
@export var attack_buffer: float = 0.25

# When attack inputs are pressed, this statemachine's state will be changed if it is not in delay
@onready var state_machine: StateMachine = $"../StateMachine"

# counts down seconds for attack buffer
var attack_buffer_remaining: float = 0

func _process(delta):
	var input_dir = Input.get_vector("left", "right", "forward", "back")
	var forward = Vector3(input_dir.x, 0, input_dir.y).rotated(Vector3.UP, camera.global_rotation.y)
	direction = forward.normalized()
	
	if Input.is_action_just_pressed("attack"):
		main_attack_requested = true
		attack_buffer_remaining = attack_buffer
	elif attack_buffer_remaining > 0:
		attack_buffer_remaining -= delta
		if attack_buffer_remaining <= 0:
			main_attack_requested = false

# Check if a move input was just pressed. If so, attacks after delay can cancel into run, etc
func is_move_key_just_pressed():
	return Input.is_action_just_pressed("forward") or Input.is_action_just_pressed("back") or Input.is_action_just_pressed("left") or Input.is_action_just_pressed("right")

# Called when an attack is registered by the state machine. 
# ensures one attack input doesn't trigger multiple attacks.
func clear_main_attack_buffer():
	attack_buffer_remaining = 0
	main_attack_requested = false
