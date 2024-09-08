extends Area3D
class_name Hitbox

@export var damage := 5

func _init() -> void:
	# Only send collisions to hurtboxes, which have mask of 01
	collision_layer = 0
	collision_mask = 2

# Trigger this hitbox one and deal damage to all overlapping bodies once.
func deal_damage():
	print("attacking with hitbox "+name)
	for area in get_overlapping_areas():
		print("overlapping with area "+area.name)
		if area.has_method("take_damage"):
			area.take_damage(damage)
