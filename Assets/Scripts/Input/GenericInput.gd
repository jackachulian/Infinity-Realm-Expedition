extends Node3D
class_name GenericInput

# State switched to when the attack button is pressed while not in delay
@export var main_attack_state : State

# move states may read from this to decide movmeent behaviour
var direction: Vector3

# Requested state. 
# if true, states may react to this. ex. idle state, attack state cambo into another, etc
var main_attack_requested: bool

# Clear the attack buffer and lets this input know its attack was registered just now
func clear_main_attack_buffer():
	pass
