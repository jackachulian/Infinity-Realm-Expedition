class_name Entity
extends CharacterBody3D # as of writing only CharacterBody3D uses but going to write work with any node for now

# Stores a reference to the current Player entity that can be accesible anywhere while in any level
static var player: Entity

enum EntityType {
	PLAYER,
	ENEMY,
	OBJECT
}

# Name displayed over health bar (used for enemy GUI above their head sometimes)
@export var display_name: String

# True if this should take damage from enemy attacks and any hitbox that can damage players.
@export var entity_type: EntityType

# Currently equipped weapon, if any. Null for no weapon
@export var weapon: EquippedWeapon

# All spells this entity has equipped. Should be located in the spells node that is a child of this entity
@export var spells: Array[EquippedSpell]

# Amount of damage this entity can take before it is defeated.
@export var max_hit_points: int = 10

# If a material is assigned, character will flash with that material when damaged.
@export var damage_flash_mat: Material = preload("res://Assets/Materials/damage-flash.tres")

#Equipped weapons should be parented to this node (usually an exposed armature bone)
@export var weapon_model_parent: Node3D

# Nodes that may be used by states to get various info
# idk how godot works but may want to make these get_node_or_null
@onready var input: GenericInput = $Input # must have direction: Vector3 property
@onready var state_machine: StateMachine = $StateMachine
@onready var movement: Movement = $Movement
@onready var anim: AnimationPlayer = $AnimationPlayer

@onready var weapon_parent: Node3D = get_node_or_null("Loadout/Weapon")
@onready var spells_parent: Node3D = get_node_or_null("Loadout/Spells")

# Current amount of hit points
@onready var hit_points: int = max_hit_points

# Height - used for things like enemy aiming, water physics, health bar placing, etc
@export var height: float = 1.5

#contains a EnemyGUI node
@onready var enemy_gui_scene: PackedScene = preload("res://Assets/Scenes/BattleUI/enemy_gui.tscn")

# Point that projectiles from spells are shot from
var shoot_marker: Marker3D

# Amount of seconds this character will show damage_flash_mat for on all meshes
var flash_timer: float = 0

# Amount of seconds of hit stun remaining.
# Entity is hit stunned if this is above 0.
# Will not be able to control movement during hit stun, input attacks, etc
var hit_stun_timer: float = 0

# All status effects currently affecting this entity.
# Each physics frame the duration will tick down, unless its duration is already 0 or lower.
# When a status reached 0 duration it is cleared.
var status_effects: Dictionary

# All meshes on this character, saved to this array on ready, for use with damage flashes.
var flash_meshes: Array[MeshInstance3D]
var flash_mesh_restore_overrides: Array[Material]

# GUI currently spawned and assigned to this enemy
var enemy_gui: EnemyGUI

signal damaged(damage: int)

func _ready():
	if entity_type == EntityType.PLAYER:
		# If there's already a player, delete this player.
		# mmainly putting this is so that I can put a player within a level scene and have it delete itself when the main game is run.
		if Entity.player:
			queue_free()
			return
		
		Entity.player = self
	
	if damage_flash_mat:
		for mesh: MeshInstance3D in $Armature.find_children("*", "MeshInstance3D", true):
			flash_meshes.append(mesh)
			flash_mesh_restore_overrides.append(mesh.material_override)
			
	# Check if entity already has a weapon in the weapon node - it will equip this without need for extra code
	if not weapon:
		if weapon_parent and weapon_parent.get_child_count() > 0:
			weapon = weapon_parent.get_child(0) as EquippedWeapon
	if weapon:
		weapon.equip(self)
		
	# Check if entity already has spells - it will equip these
	if spells_parent:
		for i in spells_parent.get_child_count():
			var spell: EquippedSpell = spells_parent.get_child(i)
			if not spell:
				continue
			if spell not in spells:
				print(name, ": added spell ", spell.name, " from loadout")
				if len(spells) <= i:
					spells.append(spell)
				else:
					spells[i] = spell
	
	for spell in spells:
		if spell:
			spell.equip(self)
		
	shoot_marker = get_node_or_null("ShootMarker")
	
	# create UI if this is an enemy
	if entity_type == EntityType.ENEMY:
		call_deferred("create_gui")

func create_gui():
	enemy_gui = enemy_gui_scene.instantiate() as EnemyGUI
	BattleHud.instance.enemy_guis.add_child(enemy_gui)
	enemy_gui.connect_to_entity(self)

func _process(delta: float):
	if flash_timer > 0:
		damage_flash_tick(delta)

func _physics_process(delta: float):
	hit_stun_timer = move_toward(hit_stun_timer, 0, delta)
	
	for status_type: String in status_effects.keys():
		var status: StatusEffect = status_effects[status_type]
		if status.duration > 0.0:
			status.duration -= delta
			if status.duration <= 0.0:
				status_effects.erase(status)

func equip(spell_number: int, spell_data: SpellData):
	if spell_number <= 0:
		printerr("invalid spell number ", spell_number, ". Spell number must be 1 or greater")
		return
		
	if spell_number > len(spells):
		printerr("trying to equip ", spell_data.display_name, " into spell slot ", spell_number, " but there are only ", len(spells), " spell slots!")
		return
		
	if spells[spell_number-1]:
		printerr("There is already a spell equipped in slot ", spell_number, " - unequipping it first")
		unequip(spell_number)
		
	var equipped_spell: EquippedSpell = spell_data.instantiate_equipped_spell()
	equipped_spell.data = spell_data
	spells[spell_number-1] = equipped_spell
	spells_parent.add_child(equipped_spell)
	equipped_spell.equip(self)
	print("equipped ", spell_data.display_name, " in slot ", spell_number)

func unequip(spell_number: int):
	if spells[spell_number-1]:
		print("unequipped ", spells[spell_number-1].data.display_name, " from slot ", spell_number)
		spells[spell_number-1].queue_free()
	else:
		print("noting unequipped from slot ", spell_number)
	spells[spell_number-1] = null

func equip_weapon(weapon_data: WeaponData):
	if weapon:
		printerr("There is already a weapon equipped - unequipping it first")
		unequip_weapon()
		
	var equipped_weapon: EquippedWeapon = weapon_data.instantiate_equipped_spell() as EquippedWeapon
	equipped_weapon.data = weapon_data
	weapon = equipped_weapon
	weapon_parent.add_child(equipped_weapon)
	equipped_weapon.equip(self)
	print("equipped ", weapon_data.display_name)

func unequip_weapon():
	weapon.queue_free()
	weapon = null

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

func take_damage(damage: float):
	hit_points -= roundi(damage)
	
	if hit_points <= 0:
		death()
	else:
		damage_flash()
		if state_machine:
			state_machine.switch_to_state_name("Hurt")
		damaged.emit(damage)
		print(name+" took "+str(damage)+" damage - HP: "+str(hit_points))

func death():
	print(display_name, " was defeated")
	queue_free()
	
	if entity_type == EntityType.PLAYER:
		await get_tree().create_timer(0.5).timeout
			
		# Get the current scene path
		var current_scene_path = get_tree().current_scene.resource_path

		# Change the scene to itself to reload it
		get_tree().change_scene_to_file(current_scene_path)

func damage_flash():
	flash_timer = 0.125
	for i in len(flash_meshes):
		flash_meshes[i].material_override = damage_flash_mat
		
func damage_flash_tick(delta: float):
	flash_timer -= delta
	if flash_timer <= 0:
		for i in len(flash_meshes):
			flash_meshes[i].material_override = flash_mesh_restore_overrides[i]

func take_hit_stun(duration: float):
	hit_stun_timer = maxf(hit_stun_timer, duration)
	print(name+" stunned for "+str(duration)+"s")

func take_knockback(force: Vector3):
	print(name+" taking knockback with force "+str(force))
	velocity = force;

func is_hit_stunned():
	return hit_stun_timer > 0

func is_shoot_obstructed() -> bool:
	if not shoot_marker:
		return false
	
	var space_state = get_world_3d().direct_space_state
	var origin = Vector3(global_position.x, shoot_marker.global_position.y, global_position.z)
	var end = shoot_marker.global_position
	var query = PhysicsRayQueryParameters3D.create(origin, end)
	query.collide_with_bodies = true
	var result = space_state.intersect_ray(query)
	return not result.is_empty()

func add_status_effect(status: StatusEffect):
	status_effects[status.status_type] = status
	
func remove_status_effect_type(status_type: String):
	status_effects[status_type] = null
	
func remove_status_effect(status: StatusEffect):
	var status_of_type: StatusEffect = status_effects[status.status_type]
	if status_of_type == status:
		status_effects.erase(status.status_type)
