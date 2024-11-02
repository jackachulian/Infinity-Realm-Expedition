extends Area3D

# Multipliers for when an entity is fully submerged in this medium of water.
# If partially submerged then value is interpolated between 1 and this value
@export var accel_multiplier: float = 0.125
@export var speed_multiplier: float = 0.675

# Key is entity. Value is the submerged status generated for them.
var submerged_status_effects: Dictionary

func _physics_process(delta: float) -> void:
	for entity: Entity in submerged_status_effects:
		var status: StatusEffect = submerged_status_effects[entity]
		update_submerged_status(status, entity)

func _on_body_entered(body: Node3D) -> void:
	var entity: Entity = body as Entity
	if entity:
		var status := StatusEffect.new("submerged", -1.0)
		submerged_status_effects[entity] = status
		entity.add_status_effect(status)
		
		# TEMP
		update_submerged_status(status, entity)

func _on_body_exited(body: Node3D) -> void:
	var entity: Entity = body as Entity
	if entity and submerged_status_effects.has(entity):
		var status: StatusEffect = submerged_status_effects[entity]
		submerged_status_effects.erase(entity)
		entity.remove_status_effect(status)
		

func update_submerged_status(status: StatusEffect, entity: Entity):
	var water_surface_offset = entity.global_position.y - global_position.y
	
	# Always treat entity like they are at least a little bit submerged. if their feet are touching the water they should be moving a little less
	var percentage_add := 0.25
	var submerge_percentage = clamp(water_surface_offset / -entity.height + percentage_add, 0, 1)
	
	status.speed_multiplier = lerp(1.0, speed_multiplier, submerge_percentage)
	status.accel_multiplier = lerp(1.0, accel_multiplier, submerge_percentage)
