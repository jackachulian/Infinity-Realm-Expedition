extends Node
class_name Attack

# State switched to when the attack button is pressed while not in delay
@export var attack_state : State

# When attack inputs are pressed, this statemachine's state will be changed if it is not in delay
@onready var state_machine: StateMachine = $"../StateMachine"

func _process(delta):
	if Input.is_action_just_pressed("attack"):
		if state_machine and state_machine.current_state and not state_machine.current_state.is_in_delay():
			# If state machine's current attack combos into another, switch to that
			var state = state_machine.current_state
			if state is AttackState and state.combos_into != "":
				state_machine.switch_to(state.combos_into)
			else:
				state_machine.switch_to(attack_state.name)
