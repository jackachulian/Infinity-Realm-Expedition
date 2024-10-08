class_name ShieldState
extends State

@export var animation_name: String = "Shield"

@export var idle_state: State

func check_transition(delta: float) -> State:	
	# check for general action input. Prevent looping from shield back into shield
	var requested_action: State = entity.input.request_action()
	if requested_action and requested_action != self:
		return requested_action
		
	# once shield and move is no longer inputted, transition back to idle
	if not entity.input.is_shield_requested() and not entity.input.is_move_requested():
		return idle_state
		
	return null
	
func update(delta: float):
	# TODO: Shield should face aim direction
	pass
	
func physics_update(delta: float):
	pass

func on_enter_state():
	entity.anim.play(animation_name)
	entity.movement.direction = Vector3.ZERO

	if entity.velocity.length() > entity.movement.speed:
		entity.velocity = entity.velocity.normalized() * entity.movement.speed
