extends Node
class_name State

# Set by enclosing state machine on its ready()
var entity: Entity

# Time elapsed that this state has been active. Managed & incremented by StateMachine script
var time_elapsed: float = 0.0

# Set to true via StateMachine when the current animation finishes
var anim_finished: bool = false

# check if a new state should be transitioned to
# returns: the new state that should be transitioned to next, blank means no transition
func check_transition(delta: float) -> String:
	return ""
	
func update(delta: float):
	pass
	
func physics_update(delta: float):
	pass

# If 0 or higher, overrides movement deceleration during this state.
func get_decel_override():
	return -1

# If currently in delay. Player can only attack, dash, shield, etc. while not on delay.
func is_in_delay() -> bool:
	return false

func on_enter_state():
	pass
	
func on_exit_state():
	pass
