extends State
class_name IdleState

@export var animation_name: String = "Sword-Standby"

@export var state_on_anim_finished: String

func check_transition(delta: float) -> String:
	if entity.input.direction != Vector3.ZERO:
		return "Run"
		
	if anim_finished and state_on_anim_finished != "":
		return state_on_anim_finished
		
	return ""
	
func physics_update(delta: float):
	pass

func on_enter_state():
	entity.anim.play(animation_name)
	entity.movement.direction = Vector3.ZERO
