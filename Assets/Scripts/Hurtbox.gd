extends Area3D
class_name Hurtbox

@export var entity: Entity

# amount of damage taken for this hurtbox. Is lower for shields.
@export var damage_multiplier: float = 1.0

func _ready() -> void:
	collision_mask = 0
	
	if not entity:
		entity = $".."
	if not entity:
		collision_layer = 0
		return
	
	# Only get collisions from the type of hurtbox this is
	# Hitboxes will only see this layer
	if entity.entity_type == entity.EntityType.PLAYER:
		collision_layer = 128 # only take damage from enemy hitbox layer
	elif entity.entity_type == entity.EntityType.ENEMY:
		collision_layer = 64 # only take damage from player hitbox layer
	elif entity.entity_type == entity.EntityType.OBJECT:
		collision_layer = 8
	
# pass incoming damage/stun/knockback signals to entity parent
func take_damage(damage: float):
	entity.take_damage(damage * damage_multiplier)

func take_hit_stun(duration: float):
	entity.take_hit_stun(duration)

func take_knockback(force: Vector3):
	entity.take_knockback(force)
