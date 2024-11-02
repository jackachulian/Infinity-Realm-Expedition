extends Area3D

# Multipliers for when an entity is fully submerged in this medium of water.
# If partially submerged then value is interpolated between 1 and this value
@export var accel_multiplier: float = 0.25
@export var speed_multiplier: float = 0.5

# Key is entity. Value is the submerged status generated for them.
var submerged_status_effects: Dictionary

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass

func _on_body_entered(body: Node3D) -> void:
	var entity: Entity = body as Entity
	if entity:
		var status := StatusEffect.new("submerged", -1.0)
		submerged_status_effects[entity] = status
		entity.add_status_effect(status)
		
		# TEMP
		status.speed_multiplier = speed_multiplier
		status.accel_multiplier = accel_multiplier
		

func _on_body_exited(body: Node3D) -> void:
	var entity: Entity = body as Entity
	if entity and submerged_status_effects.has(entity):
		var status: StatusEffect = submerged_status_effects[entity]
		submerged_status_effects.erase(entity)
		entity.remove_status_effect(status)
		

func update_submerged_status(status: StatusEffect, entity: Entity):
	var water_surface_offset = entity.global_position.y - global_position.y
	
	var submerge_percentage = clamp(water_surface_offset / -entity.height, 0, 1)
	
	status.speed_multiplier = speed_multiplier * submerge_percentage
	status.accel_multiplier = accel_multiplier * submerge_percentage
