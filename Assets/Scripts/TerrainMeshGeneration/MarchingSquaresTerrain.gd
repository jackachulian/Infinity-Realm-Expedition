@tool
class_name MarchingSquaresTerrain
extends MeshInstance3D

@export var dimensions: Vector3i = Vector3i(10, 1, 10):
	set(new_dimensions):
		dimensions = new_dimensions
		load_height_map()
		generate_mesh()
		
var height_map: Array

@export var height_map_image: Texture2D

# The max height distance between points before a wall is created between them
@export var merge_threshold: float = 0.06

var st: SurfaceTool

func _ready() -> void:
	load_height_map()
	generate_mesh()
	
			
func generate_mesh():
	st = SurfaceTool.new()

	st.begin(Mesh.PRIMITIVE_TRIANGLES)
			
	# Loop over all xz coordinates
	for z in range(dimensions.z - 1):
		for x in range(dimensions.x - 1):
			var a_height = height_map[z][x] # top-left
			var b_height = height_map[z][x+1] # top-right
			var c_height = height_map[z+1][x] # bottom-left
			var d_height = height_map[z+1][x+1]
			
			
	
	mesh = st.commit()
	
func load_height_map():	
	height_map = []
	height_map.resize(dimensions.z)
	
	for z in range(dimensions.z):
		height_map[z] = []
		height_map[z].resize(dimensions.x)
		for x in range(dimensions.x):
			height_map[z][x] = 0.0
		
	if not height_map_image:
		return
	
	var image = height_map_image.get_image()
	
	for z in range(min(dimensions.z, image.get_height()+1) - 1):
		for x in range(min(dimensions.x, image.get_width()+1) - 1):
			var height = round(image.get_pixel(x, z).r * dimensions.y)
			
			height_map[z][x] = height
