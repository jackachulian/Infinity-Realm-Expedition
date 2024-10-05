extends Object
class_name GrassGeneration

static func simple_grass_mesh(size: Vector2) -> Mesh:
	var verts = PackedVector3Array();
	var uvs = PackedVector2Array();
	
	verts.push_back(Vector3(0.5 * size.x, 0, 0))
	uvs.push_back(Vector2(1, 0))
	
	verts.push_back(Vector3(-0.5 * size.x, 0, 0))
	uvs.push_back(Vector2(0, 0))
	
	
	verts.push_back(Vector3(0, 1 * size.y, 0))
	uvs.push_back(Vector2(0.5, 1))
	
	var arrays = []
	arrays.resize(Mesh.ARRAY_MAX)
	
	arrays[Mesh.ARRAY_VERTEX] = verts
	arrays[Mesh.ARRAY_TEX_UV] = uvs
	
	var mesh = ArrayMesh.new()
	mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arrays)
	mesh.custom_aabb = AABB(Vector3(-0.5 * size.x, 0.0, -0.5 * size.x), Vector3(1.0 * size.x, 1.0 * size.y, 1.0 * size.x))
	return mesh
