extends Node
class_name Movement

# may be modified by states
var speed := 5.0

@export var move_accel: int = 40.0
@export var stop_decel: int = 30.0
@export var stun_decel: int = 10.0


@onready var entity: Entity = $".."

# May be modified by PlayerInput or AI nodes to change move direction
var direction := Vector2.ZERO


func _physics_process(delta):
	if direction != Vector2.ZERO and not entity.is_hit_stunned():
		entity.velocity.x = move_toward(entity.velocity.x, direction.x * speed, move_accel * delta)
		entity.velocity.z = move_toward(entity.velocity.z, direction.y * speed, move_accel * delta)
	else:
		var decel = stop_decel if entity.is_hit_stunned() else stop_decel
		entity.velocity.x = move_toward(entity.velocity.x, 0, decel * delta)
		entity.velocity.z = move_toward(entity.velocity.z, 0, decel * delta)

	# Apply root motion (subtract instead of add because model is flipped 180 degrees)
	var root_motion_delta = entity.anim.get_root_motion_position()
	entity.position -= entity.get_quaternion() * root_motion_delta;
		
	entity.move_and_slide()
