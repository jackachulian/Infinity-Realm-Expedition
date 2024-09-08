extends State
class_name AttackState

# Name of the animation to play for this attack
@export var attack_name: String

# When attack button is pressed again, once cancel delay is over, this attack is used next in the combo. if empty, same attack is used again.
@export var combos_into: String

# Player can cancel the attack and start a new attack after this many seconds into the attack
@export var cancel_delay: float = 0.1

# Amount of frames before the hitbox should attack
# this will probably be turned into a more robust system later, i.e. multiple hitboxes per state
@export var attack_delay: float = 0.1

# Object(s) that should be enabled/disabled when entering/exiting this state. (slash effect)
@export var slash_effect: SlashEffect


@onready var hitbox: Hitbox = $Hitbox

# if htbox's attack has already happened during this state
var hitbox_activated: bool = false 

func _ready():
	if hitbox:
		hitbox.visible = false

func check_transition(delta: float) -> String:
	# go to idle after anim is completely finished
	if anim_finished:
		return "Idle"
		
	# can cancel into move state if cancel delay passed and move key pressed
	if not is_in_delay() and entity.input.has_method("is_move_key_just_pressed"):
		if entity.input.is_move_key_just_pressed():
			return "Run"
			
	# Move to next attack if not in delay and input requested another main attack
	if not is_in_delay() and entity.input.main_attack_requested:
		if entity.input.has_method("clear_main_attack_buffer"):
			entity.input.clear_main_attack_buffer()
			
		# Combo into next skill if there is one. if not use main attack.
		if combos_into != "":
			return combos_into
		else:
			return entity.input.main_attack_state.name
	
	return ""
	
func is_in_delay() -> bool:
	return time_elapsed < cancel_delay

func physics_update(delta: float):
	if not hitbox_activated and time_elapsed >= attack_delay:
		hitbox_activated = true
		if hitbox:
			hitbox.deal_damage()

func on_enter_state():
	if hitbox:
		hitbox.enable_shape()
	hitbox_activated = false
	
	if slash_effect:
		slash_effect.play()
	
	entity.movement.direction = Vector3.ZERO
	entity.anim.play(attack_name)
	
func on_exit_state():
	if hitbox:
		hitbox.disable_shape()
