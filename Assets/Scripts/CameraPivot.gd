extends Node3D

@export var follow: Node3D

# target y rotation
var target_angle: float = 0

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	if follow:
		global_position = follow.global_position
	
	if Input.is_action_just_pressed("rotate_left"):
		target_angle -= deg_to_rad(45);
	elif Input.is_action_just_pressed("rotate_right"):
		target_angle += deg_to_rad(45);
	
	var current_rot = Quaternion(transform.basis)
	var target_rot = Quaternion(Vector3.UP, target_angle)
	var smooth_rot = current_rot.slerp(target_rot, 10.0*delta)
	transform.basis = Basis(smooth_rot)
