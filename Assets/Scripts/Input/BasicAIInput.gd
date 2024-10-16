extends GenericInput
class_name BasicAIInput

var target: Node3D

# Time between attacks
@export var move_cooldown: float = 0.0

@export var main_attack_cooldown: float = 1.5

@export var remove_cooldown_on_hit: bool = true

var move_cooldown_remaining: float
var attack_cooldown_remaining: float

func _ready():
	target = Entity.player
	
	if target:
		print(name+" is targeting "+target.name)
	else:
		print(name+": could not find player to track")
		
	move_cooldown_remaining = move_cooldown
	attack_cooldown_remaining = main_attack_cooldown

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	# face/move towards target
	
	if target:	
		facing = (target.global_position - global_position)
		facing.y = 0
		facing = facing.normalized()
	
	move_cooldown_remaining = move_toward(move_cooldown_remaining, 0, delta)
	if move_cooldown_remaining <= 0:
		direction = facing
	
	if entity.input.main_attack_state:
		attack_cooldown_remaining = move_toward(attack_cooldown_remaining, 0, delta)
		
	if remove_cooldown_on_hit and entity.get_current_state().name == "Hurt":
		move_cooldown_remaining = 0
		attack_cooldown_remaining = 0
	
func clear_main_attack_buffer():
	attack_cooldown_remaining = main_attack_cooldown

func is_main_attack_requested():
	return target and attack_cooldown_remaining <= 0

func clear_move_buffer():
	move_cooldown_remaining = move_cooldown

func is_move_requested():
	return target and move_cooldown_remaining <= 0
