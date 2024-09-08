extends State
class_name IdleState

@export var animation_name: String = "Sword-Standby"

@export var state_on_anim_finished: String

func check_transition(delta: float) -> String:
	# Go to run (move) state when movement starts
	if entity.input.direction != Vector3.ZERO:
		return "Run"
		
	# used for run-stop
	if anim_finished and state_on_anim_finished != "":
		return state_on_anim_finished
		
	# Attack from idle (and run-stop which also uses this script)
	if entity.input.main_attack_requested:
		entity.input.clear_main_attack_buffer()
		return entity.input.main_attack_state.name
		
	return ""
	
func physics_update(delta: float):
	pass

func on_enter_state():
	entity.anim.play(animation_name)
	entity.movement.direction = Vector3.ZERO
