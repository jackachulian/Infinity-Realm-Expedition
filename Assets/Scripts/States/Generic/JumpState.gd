class_name JumpState
extends State

# =======================================
# === CURRENTLY UNUSED!!!!!!!! ===
# =======================================

@export var animation_name: String = "JumpRise"

@export var falling_state: State


func check_transition(delta: float) -> String:	
	# check for general action input (attack, dash, shield, etc)
	# do not allow this to go to the Move state, that's only for when grounded
	var requested_action = entity.input.request_action()
	if requested_action != "" and requested_action != "Move":
		return requested_action
		
	# if falling, go to the fall state
	if entity.velocity.y <= 0 and falling_state:
		return falling_state.name
		
	return ""
	
func physics_update(delta: float):
	pass

func on_enter_state():
	entity.anim.play(animation_name)
