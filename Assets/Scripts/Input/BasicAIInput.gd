extends GenericInput
class_name BasicAIInput

var target: Node3D

# Time between attacks
@export var move_cooldown: float = 0.0

@export var main_attack_cooldown: float = 1.5

@export var spell_cooldown: float = 1.5

@export var remove_cooldown_on_hit: bool = true

var move_cooldown_remaining: float
var attack_cooldown_remaining: float
var spell_cooldown_remaining: float

func _ready():
	target = Entity.player
	
	if target:
		print(entity.name+" is targeting "+target.name)
	else:
		print(entity.name+": could not find player to track")
		
	move_cooldown_remaining = move_cooldown
	attack_cooldown_remaining = main_attack_cooldown
	spell_cooldown_remaining = spell_cooldown

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
	
	if entity.input.main_attack_state or entity.weapon:
		attack_cooldown_remaining = move_toward(attack_cooldown_remaining, 0, delta)
		
	spell_cooldown_remaining = move_toward(spell_cooldown_remaining, 0, delta)
		
	if remove_cooldown_on_hit and entity.get_current_state().name == "Hurt":
		move_cooldown_remaining = 0
		attack_cooldown_remaining = 0


func is_move_requested():
	return target and move_cooldown_remaining <= 0

func clear_move_buffer():
	move_cooldown_remaining = move_cooldown


func is_main_attack_requested():
	if target and attack_cooldown_remaining <= 0 and entity.weapon and entity.weapon.entry_state:
		var pos = Vector2(global_position.x, global_position.z)
		var target_pos = Vector2(target.global_position.x, target.global_position.z)
		var distance_from_target = pos.distance_to(target_pos)
		if distance_from_target <= entity.weapon.ai_distance:
			return true
			
	return false

func clear_main_attack_buffer():
	attack_cooldown_remaining = main_attack_cooldown


func get_spell_requested() -> int:
	if spell_cooldown_remaining > 0:
		return 0
		
	# try to use a random spell while this ai is not on spell cooldown
	# this is different from the actual spells' cooldowns. spell use wll not work if on cooldown
	return randi_range(1, len(entity.spells))

func clear_spell_buffer(spell_number: int):
	spell_cooldown_remaining = spell_cooldown

	
func get_aim_target() -> Vector3:
	if target:
		return target.global_position
	else:
		return Vector3.ZERO
