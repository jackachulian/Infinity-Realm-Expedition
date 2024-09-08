extends GenericInput
class_name PlayerInput

@onready var camera: Node3D = get_viewport().get_camera_3d()

func _physics_process(delta):
	var input_dir = Input.get_vector("left", "right", "forward", "back")
	var forward = Vector3(input_dir.x, 0, input_dir.y).rotated(Vector3.UP, camera.global_rotation.y)
	direction = Vector2(forward.x, forward.z).normalized()

# Check if a move input was just pressed. If so, attacks after delay can cancel into run, etc
func is_move_key_just_pressed():
	return Input.is_action_just_pressed("forward") or Input.is_action_just_pressed("back") or Input.is_action_just_pressed("left") or Input.is_action_just_pressed("right")
