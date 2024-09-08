extends GenericInput
class_name BasicAIInput

var target: Node3D

# Time between attacks
@export var main_attack_cooldown: float = 5.0

@onready var entity: Entity = $".."


var attack_cooldown_remaining: float


func _ready():
	target = $"../../infinity"
	
	if target:
		print(name+" is targeting "+target.name)
	else:
		print(name+": could not find player to track")

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	# face/move towards target
	if target:
		direction = (target.global_position - global_position)
		direction.y = 0
		direction = direction.normalized()
		
	# Adjust attack cooldown
	attack_cooldown_remaining = move_toward(attack_cooldown_remaining, 0, delta)
	# If cooldown is at 0, request an attack
	if attack_cooldown_remaining <= 0:
		main_attack_requested = true

# As soon as the attack is registered, start counting down the time for when the next attack can be inputted
# This means the timer will still count down during the current attack
func clear_main_attack_buffer():
	attack_cooldown_remaining = main_attack_cooldown
	main_attack_requested = false
