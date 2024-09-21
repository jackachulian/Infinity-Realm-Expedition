extends State
class_name AttackState

# Name of the animation to play for this attack
@export var attack_name: String

# When attack button is pressed again, once cancel delay is over, this attack is used next in the combo. if empty, same attack is used again.
@export var combos_into: String

# Player can cancel the attack and start a new attack/action after this many seconds into the attack
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
		
	# can cancel into action if cancel delay passed
	if not is_in_delay():
		var requested_action = entity.input.request_action()
		if requested_action != "":
			return requested_action
	
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
	
	# upon entering this attack state, turn to face the input direction
	if entity.input.direction:
		var input_angle = atan2(-entity.input.direction.x, -entity.input.direction.z)
		entity.face_angle(input_angle)
	
	if slash_effect:
		slash_effect.play()
	
	entity.movement.direction = Vector3.ZERO
	entity.anim.play(attack_name)
	
func on_exit_state():
	if hitbox:
		hitbox.disable_shape()
