class_name PlayerInput
extends GenericInput

# Amount of input buffer for the current requested attack. Used for main attack (0) and spells (1-6)
@export var attack_buffer: float = 0.25

# Amount of input buffer for the move buttons for cancelling actions (seconds)
@export var move_buffer: float = 0.25

# Amount of input buffer for dashing when move is just now inputted out of not moving (i.e. out of shield)
@export var dash_buffer: float = 0.1

# Amount of extra leeway time given to dash inputs to allow player to get both directional keys pushed down. Must be less than dash buffer.
@export var dash_input_direction_buffer: float = 0.08

# When attack inputs are pressed, this statemachine's state will be changed if it is not in delay
@onready var state_machine: StateMachine = $"../StateMachine"

@onready var camera: Camera3D = Camera3DTexelSnapped.instance

# Currently equipped spell that will be requested to use when right-clicking (input method may change since writing this)
# this value should be sent to and mirrored with the UI when changed
# 0 for none equipped (probably not possible), 1 for spell number, aka the number key used to select it
var equipped_spell_number: int = 0

# Requested attack. 0 for main attack requested, 1-6 for spell requested.
var requested_attack: int = 0

# counts down seconds for buffers
var attack_buffer_remaining: float = 0
var move_buffer_remaining: float = 0
var dash_buffer_remaining: float = 0

# total amt. of seconds that inputted direction has been non-zero
var move_input_hold_elapsed: float = 0

# true when dash requested. may need to wait until after brief multi-direction leeway window passes
var dash_press_queued: bool = false

# point the player is aiming towards. aka, the last mouse intersection with the Y plane of the character
var aim_target: Vector3

func _ready():
	await get_tree().process_frame
	equip_spell(1)

func _physics_process(delta):
	super._physics_process(delta)
	
	# movement direction input
	var input_dir = Input.get_vector("left", "right", "forward", "back")
	var forward = Vector3(input_dir.x, 0, input_dir.y).rotated(Vector3.UP, camera.global_rotation.y)
	direction = forward.normalized()
	
	if input_dir == Vector2.ZERO:
		move_input_hold_elapsed = 0
	else:
		move_input_hold_elapsed += delta
	
	# Aim target position from mouse
	var local_mouse_pos: Vector2 = MainTextureRect.instance.get_local_mouse_position()
	var viewport_size: Vector2 = camera.get_viewport().size
	var mouse_pos = local_mouse_pos * (viewport_size / MainTextureRect.instance.size)
			
	var ray_origin := camera.project_ray_origin(mouse_pos)
	var ray_dir := camera.project_ray_normal(mouse_pos)
	
	var shoot_plane := Plane(Vector3.UP, Vector3(0, entity.shoot_marker.global_position.y, 0))
	var target_position = shoot_plane.intersects_ray(ray_origin, ray_dir)
	
	if target_position:
		aim_target = target_position
	
	# Spell selection
	const spell_select_inputs := ["select_spell_1", "select_spell_2", "select_spell_3"]
	
	for i in len(spell_select_inputs):
		var action_name: String = spell_select_inputs[i]
		if Input.is_action_just_pressed(action_name):
			equip_spell(i+1)
			break
			
	# Attacking (main attack and spells)
	var inputted_attack: int = -1
	if Input.is_action_just_pressed("attack"):
		inputted_attack = 0
	elif Input.is_action_just_pressed("spell"):
		inputted_attack = equipped_spell_number
		
	# Set the attack buffer if an attack is requested, or countdown buffer timer if no attack requested
	if inputted_attack >= 0:
		requested_attack = inputted_attack
		attack_buffer_remaining = attack_buffer 
	elif attack_buffer_remaining > 0:
		attack_buffer_remaining = move_toward(attack_buffer_remaining, 0, delta)
		
	if is_move_key_just_pressed():
		move_buffer_remaining = move_buffer
	elif move_buffer_remaining > 0:
		move_buffer_remaining = move_toward(move_buffer_remaining, 0, delta)
		
	if Input.is_action_just_pressed("shield"):
		dash_buffer_remaining = dash_buffer
	elif dash_buffer_remaining > 0:
		dash_buffer_remaining = move_toward(dash_buffer_remaining, 0, delta)
	
func get_aim_target() -> Vector3:
	return aim_target
	
func equip_spell(spell_number: int):
	equipped_spell_number = spell_number
	BattleHud.instance.select_spell(spell_number)

func is_move_key_just_pressed():
	return Input.is_action_just_pressed("forward") or Input.is_action_just_pressed("back") or Input.is_action_just_pressed("left") or Input.is_action_just_pressed("right")
	
func is_dash_requested():
	# Dash while moving and shield just pressed 
	
	# move must be held for just a tiny bit longer than 0, allows leeway for diagonal dash input
	var move_to_dash = dash_buffer_remaining > 0 and direction != Vector3.ZERO
	# Likewise, dash while shielding and move just pressed
	var shield_to_dash = Input.is_action_pressed("shield") and move_input_hold_elapsed >= dash_input_direction_buffer and move_input_hold_elapsed < dash_buffer
	
	return move_to_dash or shield_to_dash
	
func is_main_attack_requested():
	# Will request attack while attack buffer is still counting down and not 0
	# When an attack is registered, attack buffer remaining will be set to 0
	return requested_attack == 0 and attack_buffer_remaining > 0
	
func get_spell_requested() -> int:
	if attack_buffer_remaining <= 0:
		return 0
	# will return 0 if main attack, which will be treated as no spell requested
	return requested_attack

func is_move_requested():
	return move_buffer_remaining > 0 and not is_shield_requested()
	
func is_shield_requested():
	return Input.is_action_pressed("shield") and not entity.is_in_state(move_state)

# Called when an attack is registered by the state machine. 
# ensures one attack input doesn't trigger multiple attacks.
func clear_main_attack_buffer():
	attack_buffer_remaining = 0
	move_buffer_remaining = 0
	
func clear_spell_buffer(spell_number: int):
	if requested_attack == spell_number:
		attack_buffer_remaining = 0
		move_buffer_remaining = 0
	
# Called when an attack is registered by the state machine. 
# ensures one attack input doesn't trigger multiple attacks.
func clear_move_buffer():
	move_buffer_remaining = 0
