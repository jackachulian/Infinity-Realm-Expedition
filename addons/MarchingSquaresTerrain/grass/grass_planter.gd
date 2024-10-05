@tool
extends MultiMeshInstance3D

@export var span := 5.0
@export var count := 100
@export var size := Vector2(0.5, 0.5)

func _enter_tree() -> void:
	rebuild()

func rebuild():
	if !multimesh:
		multimesh = MultiMesh.new()
	multimesh.instance_count = 0
	multimesh.mesh = GrassGeneration.simple_grass_mesh(size)
	multimesh.transform_format = MultiMesh.TRANSFORM_3D
	multimesh.use_custom_data = false
	multimesh.use_colors = false # temp probably
	multimesh.instance_count = count
	
	for index in multimesh.instance_count:
		var pos = Vector3(randf_range(-span, span), 0.0, randf_range(-span, span))
		multimesh.set_instance_transform(index, Transform3D(Basis.IDENTITY, pos))
