class_name ShieldState
extends State

@export var animation_name: String = "Shield"

@export var idle_state: State

@export var shield_delay: float = 0.15

@onready var shield_mesh: Node3D = $shield

@onready var shield_hurtbox: Hurtbox = $ShieldHurtbox
@onready var shield_hurtbox_shape: CollisionShape3D = $ShieldHurtbox/CollisionShape3D


func _ready() -> void:
	shield_mesh.visible = false
	shield_hurtbox_shape.disabled = true

func check_transition(delta: float) -> State:	
	# check for general action input. Prevent looping from shield back into shield
	var requested_action: State = entity.input.request_action()
	if requested_action and requested_action != self:
		return requested_action
		
	# once shield and move is no longer inputted, transition back to idle
	if not entity.input.is_shield_requested() and not entity.input.is_move_requested():
		return idle_state
		
	return null
	
func update(delta: float):
	# TODO: Shield should face aim direction
	pass
	
func physics_update(delta: float):
	# Point shield towards aim target persistently
	var offset = (entity.input.get_aim_target() - entity.global_position).normalized()
	var aim_angle = atan2(-offset.x, -offset.z);
	entity.face_angle(aim_angle, 22.5);
	
	if time_elapsed >= shield_delay:
		shield_hurtbox_shape.disabled = false
		shield_mesh.visible = true

func on_enter_state():
	shield_mesh.visible = false
	entity.anim.play(animation_name)
	entity.movement.direction = Vector3.ZERO

	if entity.velocity.length() > entity.movement.speed:
		entity.velocity = entity.velocity.normalized() * entity.movement.speed

func on_exit_state():
	shield_mesh.visible = false
	shield_hurtbox_shape.disabled = true
