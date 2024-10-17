@tool
class_name GrassPlanter
extends MultiMeshInstance3D

var chunk: MarchingSquaresTerrainChunk

func setup(chunk: MarchingSquaresTerrainChunk):
	self.chunk = chunk
	if !multimesh:
		multimesh = MultiMesh.new()
	multimesh.instance_count = 0
	multimesh.mesh = simple_grass_mesh(chunk.terrain_system.grass_size)
	multimesh.transform_format = MultiMesh.TRANSFORM_3D
	multimesh.use_custom_data = false
	multimesh.use_colors = false
	multimesh.instance_count = (chunk.dimensions.x-1) * (chunk.dimensions.z-1) * chunk.terrain_system.grass_subdivisions * chunk.terrain_system.grass_subdivisions
	#multimesh.custom_aabb = AABB(Vector3.ZERO, Vector3(
		#chunk.dimensions.x-1 * chunk.terrain_system.cell_size.x, 
		#chunk.dimensions.y, 
		#chunk.dimensions.z-1 * chunk.terrain_system.cell_size.y))
	
	material_override = chunk.terrain_system.grass_material
	cast_shadow = SHADOW_CASTING_SETTING_OFF
	
func regenerate_all_cells():
	if not chunk.cell_geometry:
		chunk.regenerate_mesh()
	
	for z in range(chunk.terrain_system.dimensions.z-1):
		for x in range(chunk.terrain_system.dimensions.x-1):
			generate_grass_on_cell(Vector2i(x, z))

func generate_grass_on_cell(cell_coords: Vector2i):
	var terrain := chunk.terrain_system
	var cell_geometry = chunk.cell_geometry[cell_coords]
	
	var points: PackedVector2Array = []
	var count = terrain.grass_subdivisions * terrain.grass_subdivisions
	
	for z in range(terrain.grass_subdivisions):
		for x in range(terrain.grass_subdivisions):
			points.append(Vector2(
				(cell_coords.x + (x + randf_range(0, 1)) / terrain.grass_subdivisions) * terrain.cell_size.x,
				(cell_coords.y + (z + randf_range(0, 1)) / terrain.grass_subdivisions) * terrain.cell_size.y
			))
	
	var index: int = (cell_coords.y * (chunk.dimensions.x-1) + cell_coords.x) * count
	var end_index: int = index + count
	#print("generating grass on ", cell_coords, " index: ", index)
	var verts: PackedVector3Array = cell_geometry["verts"]
	var uvs: PackedVector2Array = cell_geometry["uvs"]
	var colors: PackedColorArray = cell_geometry["colors"]
	var is_floor: Array = cell_geometry["is_floor"]
	for i in range(0, len(verts), 3):
		# only place grass on floors
		if not is_floor[i]:
			continue
		
		var a := verts[i]
		var b := verts[i+1]
		var c := verts[i+2]
		
		var v0 := Vector2(c.x - a.x, c.z - a.z)
		var v1 := Vector2(b.x - a.x, b.z - a.z)
		
		var dot00 := v0.dot(v0)
		var dot01 := v0.dot(v1)
		var dot11 := v1.dot(v1)
		var invDenom := 1.0/(dot00 * dot11 - dot01 * dot01)
		
		var point_index := 0
		while (point_index < len(points)):
			var v2 = Vector2(points[point_index].x - a.x, points[point_index].y - a.z)
			var dot02 := v0.dot(v2)
			var dot12 := v1.dot(v2)
			
			var u := (dot11 * dot02 - dot01 * dot12) * invDenom
			if u < 0:
				point_index += 1
				continue
			
			var v := (dot00 * dot12 - dot01 * dot02) * invDenom
			if v < 0:
				point_index += 1
				continue
				
			if u + v <= 1:
				# Point is inside triangle, won't be inside any other floor triangle
				points.remove_at(point_index)
				var p = a*u + b*v + c*(1-u-v)
				
				# Don't place grass on ledges
				var uv = uvs[i]*u + uvs[i+1]*v + uvs[i+2]*(1-u-v)
				var on_ledge: bool = uv.x > 1-chunk.terrain_system.ledge_bottom_thickness or uv.y > 1-chunk.terrain_system.ledge_top_thickness
				
				# Don't place grass on anything except grass color (0,0,0,0)
				var color = colors[i]*u + colors[i+1]*v + colors[i+2]*(1-u-v)
				var on_path: bool = color.r > 0.25 or color.g > 0.5 or color.b > 0.5 or color.a > 0.5
				
				if not on_ledge and not on_path:
					#print("placing grass at ", p)a
					
					var scale = randf_range(1, 1.5)
					
					# 50% chance to flip horizontally
					var basis := Basis(
						#(Vector3.LEFT if randf() < 0.5 else Vector3.RIGHT) * scale, 
						Vector3.RIGHT * scale, 
						Vector3.UP * scale, 
						Vector3.BACK * scale
					)
					multimesh.set_instance_transform(index, Transform3D(basis, p))
				else:
					multimesh.set_instance_transform(index, Transform3D(Basis.from_scale(Vector3.ZERO), Vector3.ZERO))
				index += 1
			else:
				point_index += 1
				
	# Fill remaining points with zero-sacaled transforms (invisible)
	while index < end_index:
		if index >= multimesh.instance_count:
			return
		multimesh.set_instance_transform(index, Transform3D(Basis.from_scale(Vector3.ZERO), Vector3.ZERO))
		index += 1
		
		

static func simple_grass_mesh(size: Vector2) -> Mesh:
	var verts = PackedVector3Array();
	var uvs = PackedVector2Array();
	
	verts.push_back(Vector3(0.5 * size.x, 0, 0))
	uvs.push_back(Vector2(1, 1))
	
	verts.push_back(Vector3(-0.5 * size.x, 0, 0))
	uvs.push_back(Vector2(0, 1))
	
	
	verts.push_back(Vector3(0, 1 * size.y, 0))
	uvs.push_back(Vector2(0.5, 0))
	
	var arrays = []
	arrays.resize(Mesh.ARRAY_MAX)
	
	arrays[Mesh.ARRAY_VERTEX] = verts
	arrays[Mesh.ARRAY_TEX_UV] = uvs
	
	var mesh = ArrayMesh.new()
	mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arrays)
	#mesh.custom_aabb = AABB(Vector3(-0.5 * size.x, 0.0, -0.5 * size.x), Vector3(1.0 * size.x, 1.0 * size.y, 1.0 * size.x))
	return mesh
