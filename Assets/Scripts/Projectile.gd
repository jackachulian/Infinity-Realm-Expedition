class_name Projectile
extends RigidBody3D

# Elemental type. used for damage calculation and may be used for elemental reactions
@export var type: Elements.Element

# Total lifetime (seconds) before this projectile disappears
@export var lifetime: float = 0.5

# Max amount of enemies this can hit or pierce before being destroyed
@export var max_hits: int = 1

# velocity upon firing, relative to entity using this spell
@export var shoot_velocity: Vector3 = Vector3.BACK * 10;

@onready var hitbox: Hitbox = $Hitbox

var remaining_lifetime: float

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	freeze = true

func shoot(entity: Entity):
	remaining_lifetime = lifetime;
	freeze = false
	#linear_velocity = entity.quaternion * shoot_velocity # forward
	
	var aim_target := entity.input.get_aim_target()
	look_at(aim_target)
	print("towards ", aim_target)
	var offset_direction := (aim_target - entity.shoot_marker.global_position).normalized()
	var shoot_basis: Basis = Basis(offset_direction.rotated(Vector3.UP, deg_to_rad(90)), Vector3.UP, offset_direction)
	linear_velocity = shoot_basis * shoot_velocity;
	
	if hitbox:
		hitbox.deal_damage_persistent()
		hitbox.on_deal_damage.connect(on_hitbox_deal_damage)
		
func on_hitbox_deal_damage(area: Area3D):
	max_hits -= 1
	if max_hits <= 0:
		destroy()

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _physics_process(delta: float) -> void:
	if remaining_lifetime > 0.0:
		remaining_lifetime -= delta;
		if remaining_lifetime <= 0.0:
			destroy()

func destroy():
	queue_free()
	return
