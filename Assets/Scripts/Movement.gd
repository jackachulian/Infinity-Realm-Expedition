extends Node
class_name Movement

# may be modified by states
var speed := 5.0

@export var move_accel: int = 40.0
@export var stop_decel: int = 30.0
@export var stun_decel: int = 10.0

@onready var entity: Entity = $".."

# May be modified by move states
# ex. infinity's run state copies inputted direction to this move direction during run
var direction: Vector3 = Vector3.ZERO

func _physics_process(delta):
	
	if direction != Vector3.ZERO and not entity.is_hit_stunned():
		entity.velocity = entity.velocity.move_toward(direction * speed, move_accel * delta)
	else:
		var decel = stop_decel if entity.is_hit_stunned() else stop_decel
		entity.velocity = entity.velocity.move_toward(Vector3.ZERO, decel * delta)

	# Apply root motion (subtract instead of add because model is flipped 180 degrees)
	var root_motion_delta = entity.anim.get_root_motion_position()
	entity.position -= entity.get_quaternion() * root_motion_delta;
		
	entity.move_and_slide()
