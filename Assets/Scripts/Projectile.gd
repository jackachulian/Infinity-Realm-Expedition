class_name Projectile
extends RigidBody3D

# Elemental type. used for damage calculation and may be used for elemental reactions
@export var type: Elements.Element

# Total lifetime (seconds) before this projectile disappears
@export var lifetime: float = 0.5

# velocity upon firing, relative to entity using this spell
@export var shoot_velocity: Vector3 = Vector3.BACK * 10;

var remaining_lifetime: float

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	freeze = true

func shoot(entity: Entity):
	remaining_lifetime = lifetime;
	freeze = false
	linear_velocity = entity.quaternion * shoot_velocity

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _physics_process(delta: float) -> void:
	if remaining_lifetime > 0.0:
		remaining_lifetime -= delta;
		if remaining_lifetime <= 0.0:
			queue_free()
			return
