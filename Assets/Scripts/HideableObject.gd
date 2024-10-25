class_name HideableObject
extends Area3D

@export var meshes_to_animate_hide: Array[GeometryInstance3D]
@export var nodes_to_hide_completely: Array[Node3D]

var hidden: bool = false
var hide_amount: float = 0.0
var hiding_materials: Array[ShaderMaterial]

const fade_speed: float = 5.0

func _process(delta: float) -> void:
	if hidden:
		if hide_amount < 0.9:
			hide_amount = move_toward(hide_amount, 0.9, delta*fade_speed);
			for mat in hiding_materials:
				mat.set_shader_parameter("hide_amount", hide_amount)
	elif hide_amount > 0.0:
		hide_amount = move_toward(hide_amount, 0.0, delta*fade_speed);
		for mat in hiding_materials:
			mat.set_shader_parameter("hide_amount", hide_amount)
		

func hide_object():
	hidden = true
	hiding_materials.clear()
	for mesh in meshes_to_animate_hide:
		if not mesh:
			continue
			
		var mat = mesh.material_override
		if mat is ShaderMaterial:
			hiding_materials.append(mat);
	for node in nodes_to_hide_completely:
		node.hide()
	
func show_object():
	hidden = false
	for node in nodes_to_hide_completely:
		node.show()
		
