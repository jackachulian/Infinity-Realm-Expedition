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

# if true, projectile will be destroyed when colliding with another body (terrain, other objects, etc)
@export var destroy_on_hit_wall: bool = true

@onready var hitbox: Hitbox = $Hitbox

var remaining_lifetime: float

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	freeze = true
	
	# Should only be on the Projectiles layer, which will only collide with terrain and objects, not entities.
	collision_layer = 2

# entity: the entity shooting the projectile.
func shoot(entity: Entity):
	remaining_lifetime = lifetime;
	freeze = false
	#linear_velocity = entity.quaternion * shoot_velocity # forward
	
	var aim_origin := entity.global_position
	if entity.shoot_marker:
		aim_origin.y = entity.shoot_marker.global_position.y
	else:
		aim_origin.y = entity.global_position.y
	var aim_target := entity.input.get_aim_target()
	var offset_direction := (aim_target - aim_origin).normalized()
	look_at(aim_target)
	print("towards ", aim_target)
	#var shoot_basis: Basis = Basis(offset_direction.rotated(Vector3.UP, deg_to_rad(90)), Vector3.UP, offset_direction)
	linear_velocity = offset_direction * shoot_velocity.z;
	
	if destroy_on_hit_wall:
		body_entered.connect(on_collide)
	
	if hitbox:
		hitbox.deal_damage_persistent(entity)
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

func on_collide(body: Node):
	if destroy_on_hit_wall:
		destroy()

func destroy():
	queue_free()
	return
