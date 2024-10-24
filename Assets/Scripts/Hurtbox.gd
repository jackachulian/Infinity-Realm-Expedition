extends Area3D
class_name Hurtbox

@onready var entity: Entity = $".."

func _ready() -> void:
	# Only get collisions from the type of hurtbox this is
	# Hitboxes will only see this layer
	if entity.entity_type == entity.EntityType.PLAYER:
		collision_layer = 128 # only take damage from enemy hitbox layer
	elif entity.entity_type == entity.EntityType.ENEMY:
		collision_layer = 64 # only take damage from player hitbox layer
	elif entity.entity_type == entity.EntityType.OBJECT:
		collision_layer = 8
	collision_mask = 0
	
# pass incoming damage/stun/knockback signals to entity parent
func take_damage(damage: int):
	entity.take_damage(damage)

func take_hit_stun(duration: float):
	entity.take_hit_stun(duration)

func take_knockback(force: Vector3):
	entity.take_knockback(force)
