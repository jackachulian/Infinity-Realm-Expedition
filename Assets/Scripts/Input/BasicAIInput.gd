extends GenericInput
class_name BasicAIInput

var target: Node3D

# Time between attacks
@export var move_cooldown: float = 0.0

@export var main_attack_cooldown: float = 1.5

@export var spell_cooldown: float = 1.5

@export var remove_cooldown_on_hit: bool = true

# Will not move towards the target if already this close to the target.
@export var min_approach_distance: float = 5.0

var move_cooldown_remaining: float
var attack_cooldown_remaining: float
var spell_cooldown_remaining: float

var distance_from_target: float

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
func _physics_process(delta: float) -> void:
	super._physics_process(delta)
	
	# face/move towards target
	if is_instance_valid(target):	
		facing = (target.global_position - global_position)
		facing.y = 0
		facing = facing.normalized()
		
		var pos = Vector2(global_position.x, global_position.z)
		var target_pos = Vector2(target.global_position.x, target.global_position.z)
		distance_from_target = pos.distance_to(target_pos)
	else:
		target = null
	
	move_cooldown_remaining = move_toward(move_cooldown_remaining, 0, delta)
	if move_cooldown_remaining <= 0:
		direction = facing
	
	if entity.input.main_attack_state or entity.weapon:
		attack_cooldown_remaining = move_toward(attack_cooldown_remaining, 0, delta)
		
	spell_cooldown_remaining = move_toward(spell_cooldown_remaining, 0, delta)
		
	var current_state := entity.get_current_state()
	if current_state and remove_cooldown_on_hit and current_state.name == "Hurt":
		move_cooldown_remaining = 0
		attack_cooldown_remaining = 0
	#if target and current_state is not AttackState:
	if target:
		current_aim_target = target.global_position + Vector3.UP * 1.5

func is_move_requested():
	return target and move_cooldown_remaining <= 0 and distance_from_target > min_approach_distance and entity.get_current_state().name == "Idle"

func clear_move_buffer():
	move_cooldown_remaining = move_cooldown


func is_main_attack_requested():
	if target and attack_cooldown_remaining <= 0 and entity.weapon and entity.weapon.entry_state:
		if distance_from_target <= entity.weapon.ai_distance:
			return true
			
	return false

func clear_main_attack_buffer():
	attack_cooldown_remaining = main_attack_cooldown


func get_spell_requested() -> int:
	if not target or spell_cooldown_remaining > 0 or len(entity.spells) == 0:
		return 0
		
	# try to use a random spell while this ai is not on spell cooldown
	# this is different from the actual spells' cooldowns. spell use wll not work if on cooldown
	var spell_number = randi_range(1, len(entity.spells))
	var spell := entity.spells[spell_number-1]
	
	#return spell_number
	
	if spell.ai_distance >= distance_from_target:
		return spell_number
	else:
		return 0

func clear_spell_buffer(spell_number: int):
	spell_cooldown_remaining = spell_cooldown

	
var current_aim_target: Vector3
func get_aim_target() -> Vector3:
	
	return current_aim_target;
