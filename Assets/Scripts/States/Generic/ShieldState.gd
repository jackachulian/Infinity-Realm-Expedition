extends State
class_name ShieldState

@export var animation_name: String = "Shield"

func check_transition(delta: float) -> String:	
	# check for general action input. Prevent looping from shield back into shield
	var requested_action = entity.input.request_action()
	if requested_action != "" and requested_action != name:
		return requested_action
		
	# once shield is no longer inputted, transition back to idle
	if not entity.input.is_shield_requested():
		return "Idle"
		
	return ""
	
func update(delta: float):
	# TODO: Shield should face aim direction
	pass
	
func physics_update(delta: float):
	pass

func on_enter_state():
	entity.anim.play(animation_name)
	entity.movement.direction = Vector3.ZERO
