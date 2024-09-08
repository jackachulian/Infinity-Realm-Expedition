extends Node
class_name Movement

# may be modified by states
var speed := 5.0

@onready var entity: Entity = $".."

# May be modified by PlayerInput or AI nodes to change move direction
var direction := Vector2.ZERO


func _physics_process(delta):
	var input_dir = Input.get_vector("left", "right", "forward", "back")

	if direction:
		entity.velocity.x = direction.x * speed
		entity.velocity.z = direction.y * speed
	else:
		entity.velocity.x = move_toward(entity.velocity.x, 0, speed)
		entity.velocity.z = move_toward(entity.velocity.z, 0, speed)
		
	# Apply root motion (subtract instead of add because model is flipped 180 degrees)
	var root_motion_delta = entity.anim.get_root_motion_position()
	entity.velocity -= entity.get_quaternion() * root_motion_delta / delta;
		
	entity.move_and_slide()
	
	

# Check if a move input was just pressed. If so, attacks after delay can cancel into run, etc
func is_move_key_just_pressed():
	return Input.is_action_just_pressed("forward") or Input.is_action_just_pressed("back") or Input.is_action_just_pressed("left") or Input.is_action_just_pressed("right")
