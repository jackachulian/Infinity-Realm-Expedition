extends GenericInput
class_name BasicAIInput

var target: Node3D

# Time between attacks
@export var main_attack_cooldown: float = 5.0

var attack_cooldown_remaining: float

func _ready():
	target = $"../../infinity"
	
	if target:
		print(name+" is targeting "+target.name)
	else:
		print(name+": could not find player to track")
		
	attack_cooldown_remaining = main_attack_cooldown

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	# face/move towards target
	if target and entity.state_machine.current_state and entity.state_machine.current_state.name in ["Idle", "Jump-Start"]:
		direction = (target.global_position - global_position)
		direction.y = 0
		direction = direction.normalized()
		
	attack_cooldown_remaining = move_toward(attack_cooldown_remaining, 0, delta)
	
func clear_main_attack_buffer():
	attack_cooldown_remaining = main_attack_cooldown

func is_main_attack_requested():
	return attack_cooldown_remaining <= 0
