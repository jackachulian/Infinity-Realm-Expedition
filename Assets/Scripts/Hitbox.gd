extends Area3D
class_name Hitbox

@export var damage := 5

@export var knockback: Vector3 = Vector3.BACK

@onready var shape: CollisionShape3D = get_child(0)

func _init() -> void:
	# Only send collisions to hurtboxes, which have mask of 01
	collision_layer = 0
	collision_mask = 2
	
func _ready():
	disable_shape()

# Trigger this hitbox one and deal damage to all overlapping bodies once.
func deal_damage():
	print("attacking with hitbox "+name)
	for area in get_overlapping_areas():
		print("overlapping with area "+area.name)
		if area.has_method("take_damage"):
			area.take_damage(damage)
		if knockback.length_squared() > 0:
			area.take_knockback(knockback * quaternion)

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
