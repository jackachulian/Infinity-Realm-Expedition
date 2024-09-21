class_name IdleState
extends State

@export var animation_name: String = "Sword-Standby"

@export var state_on_anim_finished: String

func check_transition(delta: float) -> String:
	# Go to run (move) state when movement starts (does not matter if move key was just pressed)
	if entity.input.direction != Vector3.ZERO and entity.input.move_state:
		return entity.input.move_state.name
		
	# used for run-stop
	if anim_finished and state_on_anim_finished != "":
		return state_on_anim_finished
		
	# check for general action input (attack, dash, shield, etc)
	var requested_action = entity.input.request_action()
	if requested_action != "":
		return requested_action
		
	# check for fall
	if entity.velocity.y < 0:
		return "JumpFall";
		
	return ""
	
func physics_update(delta: float):
	pass

func on_enter_state():
	entity.anim.play(animation_name)
	entity.movement.direction = Vector3.ZERO
