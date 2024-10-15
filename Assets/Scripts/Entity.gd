class_name Entity
extends CharacterBody3D # as of writing only CharacterBody3D uses but going to write work with any node for now

# Stores a reference to the current Player entity that can be accesible anywhere while in any level
static var player: Entity

enum EntityType {
	PLAYER,
	ENEMY,
	OBJECT
}

# True if this should take damage from enemy attacks and any hitbox that can damage players.
@export var entity_type: EntityType

# Currently equipped weapon, if any. Null for no weapon
@export var weapon: EquippedWeapon

# All spells this entity has equipped. Should be located in the spells node that is a child of this entity
@export var spells: Array[EquippedSpell]

# Amount of damage this entity can take before it is defeated.
@export var hit_points: int = 10

# If a material is assigned, character will flash with that material when damaged.
@export var damage_flash_mat: Material

#Equipped weapons should be parented to this node (usually an exposed armature bone)
@export var weapon_model_parent: Node3D

# Nodes that may be used by states to get various info
# idk how godot works but may want to make these get_node_or_null
@onready var input: GenericInput = $Input # must have direction: Vector3 property
@onready var state_machine: StateMachine = $StateMachine
@onready var movement: Movement = $Movement
@onready var anim: AnimationPlayer = $AnimationPlayer

@onready var weapon_parent: Node3D = $Loadout/Weapon
@onready var spells_parent: Node3D = $Loadout/Spells


# Point that projectiles from spells are shot from
var shoot_marker: Marker3D

# Amount of seconds this character will show damage_flash_mat for on all meshes
var flash_timer: float = 0

# Amount of seconds of hit stun remaining.
# Entity is hit stunned if this is above 0.
# Will not be able to control movement during hit stun, input attacks, etc
var hit_stun_timer: float = 0

# All meshes on this character, saved to this array on ready, for use with damage flashes.
var flash_meshes: Array[MeshInstance3D]

func _ready():
	if entity_type == EntityType.PLAYER:
		Entity.player = self
	
	if damage_flash_mat:
		for mesh in $Armature.find_children("*", "MeshInstance3D", true):
			flash_meshes.append(mesh)
			
	# Check if entity already has a weapon in the weapon node - it will equip this withotu need for extra code
	if not weapon:
		if weapon_parent and weapon_parent.get_child_count() > 0:
			weapon = weapon_parent.get_child(0) as EquippedWeapon
	if weapon:
		weapon.equip(self)
		
	# Check if entity already has spells - it will equip these
	var spell_parent: Node = get_node_or_null("Loadout/Spells")
	if spell_parent:
		for spell: EquippedSpell in spell_parent.get_children():
			if not spell:
				continue
			if spell not in spells:
				print(name, ": added spell ", spell.name, " from loadout")
				spells.append(spell)
	
	for spell in spells:
		if spell:
			spell.equip(self)
		
	shoot_marker = get_node_or_null("ShootMarker")

func _process(delta: float):
	if flash_timer > 0:
		damage_flash_tick(delta)

func _physics_process(delta: float):
	hit_stun_timer = move_toward(hit_stun_timer, 0, delta)

func get_state(state_name: String) -> State:
	return state_machine.get_node_or_null(state_name)

func get_current_state() -> State:
	return state_machine.current_state

func is_in_state(state: State):
	return state_machine.current_state == state

# Face the given angle. Snap to the nearest increment if rotation_snap is above 0
func face_angle(angle: float, rotation_snap: float = 45):
	if rotation_snap > 0:
		var snap = deg_to_rad(rotation_snap)
		angle = round(angle / snap) * snap
	rotation.y = angle

func take_damage(damage: int):
	hit_points -= damage
	damage_flash()
	state_machine.switch_to_state_name("Hurt")
	print(name+" took "+str(damage)+" damage - HP: "+str(hit_points))

func damage_flash():
	flash_timer = 0.125
	for mesh in flash_meshes:
		mesh.material_override = damage_flash_mat
		
func damage_flash_tick(delta: float):
	flash_timer -= delta
	if flash_timer <= 0:
		for mesh in flash_meshes:
			mesh.material_override = null

func take_hit_stun(duration: float):
	hit_stun_timer = maxf(hit_stun_timer, duration)
	print(name+" stunned for "+str(duration)+"s")

func take_knockback(force: Vector3):
	print(name+" taking knockback with force "+str(force))
	velocity = force;

func is_hit_stunned():
	return hit_stun_timer > 0

func is_shoot_obstructed() -> bool:
	var space_state = get_world_3d().direct_space_state
	var origin = Vector3(global_position.x, shoot_marker.global_position.y, global_position.z)
	var end = shoot_marker.global_position
	var query = PhysicsRayQueryParameters3D.create(origin, end)
	query.collide_with_bodies = true
	var result = space_state.intersect_ray(query)
	return not result.is_empty()
