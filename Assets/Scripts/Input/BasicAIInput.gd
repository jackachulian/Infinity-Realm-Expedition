extends GenericInput
class_name BasicAIInput

var target: Node3D

# Time between attacks
@export var move_cooldown: float = 0.0

@export var main_attack_cooldown: float = 5.0

@export var max_main_attack_range: float = 5.0

var move_cooldown_remaining: float
var attack_cooldown_remaining: float

func _ready():
	target = $"../../infinity"
	
	if target:
		print(name+" is targeting "+target.name)
	else:
		print(name+": could not find player to track")
		
	move_cooldown_remaining = move_cooldown
	attack_cooldown_remaining = main_attack_cooldown

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	# face/move towards target
	
		
	facing = (target.global_position - global_position)
	facing.y = 0
	facing = facing.normalized()
	
	move_cooldown_remaining = move_toward(move_cooldown_remaining, 0, delta)
	if move_cooldown_remaining <= 0:
		direction = facing
	
	if entity.input.main_attack_state:
		attack_cooldown_remaining = move_toward(attack_cooldown_remaining, 0, delta)
	
func clear_main_attack_buffer():
	attack_cooldown_remaining = main_attack_cooldown

func is_main_attack_requested():
	return attack_cooldown_remaining <= 0

func clear_move_buffer():
	move_cooldown_remaining = move_cooldown

func is_move_requested():
	return move_cooldown_remaining <= 0
