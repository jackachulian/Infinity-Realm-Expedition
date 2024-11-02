class_name Projectile
extends RigidBody3D
# TODO: may want to make this work with PhysicsBody3D.
#what i will probably do instead though is make seperate classes.
# like one for non-standard projectiles via animatablebody3d or whatever it is,
# and a "Helper" class for summoned helper spells.
# probably also a separate mount class too

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

@export var max_snap_distance: float = 2.0

@export var max_snap_speed: float = 2.0

@export_flags("Neutral", "Fire", "Spirit", "Water", "Ice", "Stone", "Wind", "Electric", "Plant", "Copy", "Metal", "Light", "Dark"
	) var extinguish_elements: int

@onready var hitbox: Hitbox = $Hitbox

@onready var ground_snap: RayCast3D = $GroundSnapRayCast3D

@onready var particles: GPUParticles3D = $GPUParticles3D
@onready var burst_particles: GPUParticles3D = $BurstGPUParticles3D
@onready var extinguish_particles: GPUParticles3D = $ExtinguishGPUParticles3D
@onready var omni_light_3d: OmniLight3D = $OmniLight3D

@onready var collision_shape_3d: CollisionShape3D = $CollisionShape3D


var remaining_lifetime: float

var base_snap_height: float
var current_offset: float

# entity that shot this projectile, if any
var entity: Entity

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	set_process(false)
	freeze = true
	
	#if not entity:
		#print("clearing proj without an entity that shot it: ", self)
		#queue_free()
		#return
	
	# Should only be on the Projectiles layer, which will only collide with terrain and objects, not entities.
	collision_layer = 2

# entity: the entity shooting the projectile.
func shoot(entity: Entity):
	self.entity = entity
	remaining_lifetime = lifetime;
	set_process(true)
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
	#var shoot_basis: Basis = Basis(offset_direction.rotated(Vector3.UP, deg_to_rad(90)), Vector3.UP, offset_direction)
	linear_velocity = offset_direction * shoot_velocity.z;
	
	if destroy_on_hit_wall:
		body_entered.connect(on_body_entered)
	
	if hitbox:
		hitbox.deal_damage_persistent(entity)
		hitbox.on_deal_damage.connect(on_hitbox_deal_damage)
		
	if ground_snap:
		base_snap_height = global_position.y - entity.global_position.y
		ground_snap.target_position = (base_snap_height + max_snap_distance) * Vector3.DOWN
		
	if particles:
		particles.emitting = true
	
		
func on_hitbox_deal_damage(area: Area3D):
	max_hits -= 1
	if max_hits <= 0:
		destroy(true, false)

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _physics_process(delta: float) -> void:
	if remaining_lifetime > 0.0:
		remaining_lifetime -= delta;
		if remaining_lifetime <= 0.0:
			destroy(false, false)
			return
			
	if ground_snap and ground_snap.is_colliding():
		var point := ground_snap.get_collision_point()
		var prev_offset = current_offset
		current_offset = global_position.y - point.y
		if abs(current_offset - base_snap_height) < max_snap_distance:
			var target_height := point.y + base_snap_height
			var height = move_toward(global_position.y, target_height, max_snap_speed * delta)
			global_position = Vector3(global_position.x, height, global_position.z)
			
			
			
# On collision with a body that this projectile can collide with. 
# Includes StaticBody3D from terrain, CharacterBody3D for entities, etc.
func on_body_entered(body: Node):
	# destroy() will be called when hitting an enemy's hurtbox.
	if destroy_on_hit_wall:
		destroy(true, false)

# true if the projectile hit something and bursted. False if it despawned at the end of its lifetime.
var destroyed: bool = false
func destroy(collided: bool, extinguished: bool):
	if destroyed:
		return
	destroyed = true
	
	freeze = true
	
	collision_shape_3d.set_deferred("disabled", true)
	hitbox.queue_free()
	
	for node in get_children():
		if node is MeshInstance3D:
			node.visible = false
	
	if particles:
		particles.visible = true
		particles.emitting = false
	if collided and burst_particles:
		burst_particles.visible = true
		burst_particles.emitting = true
	elif extinguished and extinguish_particles:
		extinguish_particles.visible = true
		extinguish_particles.emitting = true
	
	if omni_light_3d:
		if collided:
			omni_light_3d.visible = true
			var anim_dur := burst_particles.lifetime*0.667 if burst_particles else 0.33
			get_tree().create_tween().tween_property(omni_light_3d, "omni_range", omni_light_3d.omni_range*1.5, anim_dur)
			get_tree().create_tween().tween_property(omni_light_3d, "light_energy", 0, anim_dur)
		else:
			omni_light_3d.visible = false
		
	await get_tree().create_timer(2.0).timeout
	
	queue_free()

	return
	
func on_element_touched(element: int):
	if not is_processing():
		return
	if element & extinguish_elements:
		destroy(false, true)
