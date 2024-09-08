extends State
class_name MoveState

# speed that the entity moves in this state
@export var speed: float = 5.0

func check_transition(delta: float) -> String:
	if entity.input.direction == Vector2.ZERO:
		return "Run-Stop"
	return ""
	
func physics_update(delta: float):
	entity.movement.direction = entity.input.direction
	
func update(delta: float):
	entity.rotation.y = atan2(-entity.input.direction.x, -entity.input.direction.y)
	
func on_enter_state():
	if entity.anim_tree:
		pass
	else:
		entity.anim.play("Run")
	entity.movement.speed = speed
