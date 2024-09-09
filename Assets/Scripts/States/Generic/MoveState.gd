extends State
class_name MoveState

@export var animation_name: String = "Run"

@export var move_stop_state: State

# speed that the entity moves in this state
@export var speed: float = 5.0

# if above 0, rotation will be snapped to the nearest increment of this
@export var rotation_snap: float = 0.0

func check_transition(delta: float) -> String:
	# Go to idle when movement stops
	if entity.input.direction == Vector3.ZERO:
		if move_stop_state:
			return move_stop_state.name
		else:
			return "Idle"
		
	# Accept general action. but don't go into move while already in move 
	# (would cause incorrect anim loop)
	var requested_action = entity.input.request_action()
	if requested_action != "" and requested_action != "Move":
		return requested_action
		
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
