class_name SlashEffect
extends Node3D

@export var duration: float = 0.5
@export var mesh: CSGPolygon3D
	
func animate():
	visible = true
	mesh.material.set_shader_parameter("t", 0)
	await get_tree().create_timer(duration * 0.666).timeout
	mesh.material.set_shader_parameter("t", 0.5)
	await get_tree().create_timer(duration * 0.111).timeout
	mesh.material.set_shader_parameter("t", 0.75)
	await get_tree().create_timer(duration * 0.111).timeout
	mesh.material.set_shader_parameter("t", 0.875)
	await get_tree().create_timer(duration * 0.111).timeout
	visible = false
	queue_free()
