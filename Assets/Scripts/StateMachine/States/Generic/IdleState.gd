class_name IdleState
extends State

@export var animation_name: String = "Sword-Standby"

@export var limit_aerial_velocity: bool = true

@export var state_on_anim_finished: State

func check_transition(delta: float) -> State:
	# used for run-stop
	if anim_finished and state_on_anim_finished:
		return state_on_anim_finished
		
	# check for general action input (attack, dash, shield, etc)
	if entity.input:
		var requested_action: State = entity.input.request_action()
		if requested_action:
			return requested_action
		
	# check for fall
	if entity.velocity.y < 0:
		return entity.get_state("JumpFall");
		
	return null
	
func physics_update(delta: float):
	pass

func on_enter_state():
	entity.anim.play(animation_name)
	if entity.movement:
		entity.movement.direction = Vector3.ZERO
	
		if limit_aerial_velocity:
			if entity.velocity.length() > entity.movement.speed:
				entity.velocity = entity.velocity.normalized() * entity.movement.speed
