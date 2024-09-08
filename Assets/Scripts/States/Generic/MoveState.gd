extends State
class_name MoveState

@export var animation_name: String = "Run"

# speed that the entity moves in this state
@export var speed: float = 5.0

# if above 0, rotation will be snapped to the nearest increment of this
@export var rotation_snap: float = 0.0

func check_transition(delta: float) -> String:
	# Go to idle when movement stops
	if entity.input.direction == Vector3.ZERO:
		return "Run-Stop"
		
	# Can attack from move
	if entity.input.main_attack_requested:
		if entity.input.has_method("clear_main_attack_buffer"):
			entity.input.clear_main_attack_buffer()
		return entity.input.main_attack_state.name
		
	return ""
	
func physics_update(delta: float):
	entity.movement.direction = entity.input.direction
	
func update(delta: float):
	var angle = atan2(-entity.input.direction.x, -entity.input.direction.z)
	if rotation_snap > 0:
		var snap = deg_to_rad(rotation_snap)
		angle = round(angle / snap) * snap
	entity.rotation.y = angle
	
func on_enter_state():
	entity.anim.play(animation_name)
	entity.movement.speed = speed
