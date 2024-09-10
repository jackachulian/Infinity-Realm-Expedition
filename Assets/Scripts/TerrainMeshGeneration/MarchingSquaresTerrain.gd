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
@export var max_slope: float = 0.1

var rng = RandomNumberGenerator.new()

var st: SurfaceTool

func _ready() -> void:
	load_height_map()
	generate_mesh()
	
			
func generate_mesh():
	st = SurfaceTool.new()

	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	
	var rules: Array[MarchingSquareRule] = []
	for rule in get_children():
		if rule is MarchingSquareRule:
			rules.append(rule)
	
	# Loop over all xz coordinates
	for z in range(dimensions.z - 1):
		for x in range(dimensions.x - 1):
			# Move upward and add any rule tiles that apply
			for y in range(dimensions.y + 1):
				for rule in rules:
					for rotation in range(4):
						if rule.check_valid()
	
	mesh = st.commit()
	
	
func load_height_map():	
	height_map = []
	height_map.resize(dimensions.z)
	
	for z in range(dimensions.z):
		height_map[z] = []
		height_map[z].resize(dimensions.x)
		for x in range(dimensions.x):
			height_map[z][x] = 0
		
	if not height_map_image:
		return
	
	var image = height_map_image.get_image()
	
	for z in range(min(dimensions.z, image.get_height()+1) - 1):
		for x in range(min(dimensions.x, image.get_width()+1) - 1):
			var height = round(image.get_pixel(x, z).r * dimensions.y)
			
			height_map[z][x] = height
