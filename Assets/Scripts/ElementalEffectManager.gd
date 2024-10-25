class_name ElementalEffectManager
extends Node

@export var grass_material: ShaderMaterial

# Contains a list of positions where wind should appear. Coupled with the same index values of wind_vectors and wind_radii.
var wind_points: PackedVector3Array = []

# Contains a list of wind vectors. Surrounding grass is offset by this much, 
# multiplied by some ambient wind noise and added to base ambient wind noise.
var wind_vectors: PackedVector2Array = []

# Contains a list of radii for each wind vector, controlling how far out the wind is spread around the points
var wind_radii: PackedFloat32Array = []

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	call_deferred("add_test_wind_point")
	
func add_test_wind_point():
	wind_points.append(Entity.player.position)
	wind_vectors.append(Vector2.LEFT)
	wind_radii.append(4.0)

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	if not grass_material:
		return
		
	grass_material.set_shader_parameter("wind_points", wind_points)
	grass_material.set_shader_param("wind_vectors", wind_vectors)
	grass_material.set_shader_param("wind_radius", wind_radii)
