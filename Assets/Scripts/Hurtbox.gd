extends Area3D
class_name Hurtbox

@onready var entity: Entity = $".."

func _ready() -> void:
	# Only receive collisions from layer 2 (mask: 01)
	if entity.entity_type == entity.EntityType.PLAYER:
		collision_layer = 2
	elif entity.entity_type == entity.EntityType.ENEMY:
		collision_layer = 4
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
