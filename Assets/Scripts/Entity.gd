extends CharacterBody3D # as of writing only CharacterBody3D uses but going to write work with any node for now
class_name Entity

# Currently equipped weapon if any.
@export var weapon: Weapon

# Amount of damage this entity can take before it is defeated.
@export var hit_points: int = 50

# Nodes that may be used by states to get various info
# idk how godot works but may want to make these get_node_or_null
@onready var input: GenericInput = $Input
@onready var movement: Movement = $Movement
#@onready var model: Node3D = $Armature
@onready var anim: AnimationPlayer = $AnimationPlayer
@onready var anim_tree: AnimationTree = $AnimationTree

# Amount of seconds of hit stun remaining.
# Entity is hit stunned if this is above 0.
# Will not be able to control movement during hit stun, input attacks, etc
var hit_stun: float = 0

func _physics_process(delta: float):
	hit_stun = move_toward(hit_stun, 0, delta)

func take_damage(damage: int):
	hit_points -= damage
	print(name+" took "+str(damage)+" damage - HP: "+str(hit_points))

func take_hit_stun(duration: float):
	hit_stun = maxf(hit_stun, duration)
	print(name+" stunned for "+str(duration)+"s")

func take_knockback(force: Vector3):
	print(name+" taking knockback with force "+str(force))
	velocity += force;

func is_hit_stunned():
	return hit_stun > 0
