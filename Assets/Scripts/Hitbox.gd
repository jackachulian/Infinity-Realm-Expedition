extends Area3D
class_name Hitbox

# Damage dealt to the target on unshielded hit
@export var damage := 5

# Amount of frames to briefly pause both characters when the attack lands, for more weighty attacks
@export var hit_pause: float = 0.1

# Amount of frames the target will lose control over their character when this attack hits (unable to move, attack, etc)
@export var hit_stun: float = 0.25

# The knockback force of this attack. faces in this hitbox's global -z direction
@export var knockback: float = 5

@export var hit_players: bool = true

@export var hit_enemies: bool = true

@export var hit_objects: bool = true

@export var hit_self: bool = false

@onready var shape: CollisionShape3D = get_child(0)

signal on_deal_damage(to: Area3D)

func _init() -> void:
	# 8 = objects layer (4)
	# 64 = player hitbox layer (7)
	# 128 = enemy hitbox player (8)
	collision_mask = (64 if hit_players else 0) + (128 if hit_enemies else 0) + (8 if hit_objects else 0)
	collision_layer = 0

# Trigger this hitbox once during only this frame and deal damage to all overlapping bodies once.
# entity: the attacking entity, if any. null for no entity
func deal_damage(attacker: Entity):
	print("attacking with hitbox "+name)
	for area in get_overlapping_areas():
		deal_damage_to(area, attacker)
		
# area = the area to deal damage to
# attacker - the entity that using the attack that is dealing this damage to the other
func deal_damage_to(area: Area3D, attacker: Entity):
	if area is Hurtbox:
		# Don't deal damage to self
		if attacker and area.entity == attacker:
			return 
			
		# Don't deal damage to fellow players or enemies
		if area.entity and attacker and attacker.entity_type == area.entity.entity_type:
			return
	
	print("overlapping with area "+area.name)
	if area.has_method("take_damage"):
		area.take_damage(damage)
	if area.has_method("take_hit_stun"):
		area.take_hit_stun(hit_stun)
	if area.has_method("take_knockback") and knockback > 0:
		area.take_knockback(knockback * -global_basis.z)
	on_deal_damage.emit(area)

# Will deal damage to any entity it comes in contact with during any frame, though it will hit each entity only once.
func deal_damage_persistent(attacker: Entity):
	print("persistently dealing damage with ", name)
	area_entered.connect(func(area): deal_damage_to(area, attacker))

func enable_shape():
	visible = true
	monitoring = true
	monitorable = true
	# disable and reenable collision shape for editor debug drawing purposes, and performance maybe
	shape.disabled = false
	
func disable_shape():
	visible = false
	monitoring = false
	monitorable = false
	shape.disabled = true
