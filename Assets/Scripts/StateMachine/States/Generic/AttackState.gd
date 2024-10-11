# Make sure all main attack / spell states are AttackStates!
# Either that or change how attacks are registered in GenericInput's request_action() method

extends State
class_name AttackState

# Name of the animation to play for this attack
@export var animation_name: String

# When attack button is pressed again, once cancel delay is over, this attack is used next in the combo. if empty, same attack is used again.
@export var combos_into: State

# Player can cancel the attack and start a new attack/action after this many seconds into the attack
@export var cancel_delay: float = 0.1

# Amount of frames before the hitbox should attack
# this will probably be turned into a more robust system later, i.e. multiple hitboxes per state
@export var attack_delay: float = 0.1

# Object(s) that should be enabled/disabled when entering/exiting this state. (slash effect)
@export var slash_effect: SlashEffect

# Projectile to shoot after attack_delay. If null, no projectile shot
@export var projectile: Projectile

@onready var hitbox: Hitbox = $Hitbox

# if htbox's attack has already happened during this state
var hitbox_activated: bool = false 

func _ready():
	if hitbox:
		hitbox.visible = false
	if slash_effect:
		slash_effect.visible = false
	if projectile:
		projectile.visible = false

func check_transition(delta: float) -> State:
	# go to idle after anim is completely finished
	if anim_finished:
		return entity.get_state("Idle")
		
	# can cancel into action if cancel delay passed
	if not is_in_delay():
		var requested_action: State = entity.input.request_action()
		if requested_action:
			return requested_action
	
	return null
	
func is_in_delay() -> bool:
	return time_elapsed < cancel_delay

func physics_update(delta: float):
	if not hitbox_activated and time_elapsed >= attack_delay:
		hitbox_activated = true
		if hitbox:
			hitbox.deal_damage()
		if slash_effect:
			instantiate_slash_effect()
		if projectile:
			var new_projectile: Projectile = projectile.duplicate()
			remove_child(new_projectile)
			entity.get_parent().add_child(new_projectile)
			new_projectile.visible = true
			new_projectile.freeze = false
			new_projectile.global_transform = projectile.global_transform
			print("shooting ", new_projectile.name, " at ", new_projectile.global_position)
			new_projectile.shoot(entity)
			
func instantiate_slash_effect():
	var slash: SlashEffect = slash_effect.duplicate()
	slash.global_transform = entity.global_transform
	entity.get_parent().add_child(slash, true)
	slash.animate()
	

func on_enter_state():
	if hitbox:
		hitbox.enable_shape()
	hitbox_activated = false
	
	# upon entering this attack state, turn to face the input direction
	if entity.input.direction:
		var input_angle = atan2(-entity.input.direction.x, -entity.input.direction.z)
		entity.face_angle(input_angle)
	
	entity.movement.direction = Vector3.ZERO
	
	if entity.anim.has_animation(animation_name):
		entity.anim.play(animation_name)
	
func on_exit_state():
	if hitbox:
		hitbox.disable_shape()
