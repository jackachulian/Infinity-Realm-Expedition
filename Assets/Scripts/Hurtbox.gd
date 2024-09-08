extends Area3D
class_name Hurtbox

@export var defense: int = 5

func _init() -> void:
	# Only receive collisions from layer 2 (mask: 01)
	collision_layer = 2
	collision_mask = 0
	
func take_damage(damage: int):
	get_parent().take_damage(damage)
