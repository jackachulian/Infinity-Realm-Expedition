# my_custom_gizmo_plugin.gd
class_name MarchingSquaresTerrainGizmo
extends EditorNode3DGizmo

var lines: PackedVector3Array = PackedVector3Array()

var addchunk_material: Material
var removechunk_material: Material

func _redraw():
	clear()
	
	addchunk_material = get_plugin().get_material("addchunk", self)
	removechunk_material = get_plugin().get_material("removechunk", self)

	var terrain_system: MarchingSquaresTerrain = get_node_3d()
	
	# Only draw the gizmo if this is the only selected node
	if len(EditorInterface.get_selection().get_selected_nodes()) != 1:
		return
	if EditorInterface.get_selection().get_selected_nodes()[0] != terrain_system:
		return

	for chunk_coords: Vector2i in terrain_system.chunks:
		if MarchingSquaresTerrainPlugin.instance.mode == MarchingSquaresTerrainPlugin.TerrainToolMode.BRUSH:
			try_add_chunk(terrain_system, Vector2i(chunk_coords.x-1, chunk_coords.y))
			try_add_chunk(terrain_system, Vector2i(chunk_coords.x+1, chunk_coords.y))
			try_add_chunk(terrain_system, Vector2i(chunk_coords.x, chunk_coords.y-1))
			try_add_chunk(terrain_system, Vector2i(chunk_coords.x, chunk_coords.y+1))
		try_add_chunk(terrain_system, chunk_coords)
		
func try_add_chunk(terrain_system: MarchingSquaresTerrain, coords: Vector2i):
	var terrain_plugin = MarchingSquaresTerrainPlugin.instance
	
	# Add chunk
	if not terrain_system.chunks.has(coords) and terrain_plugin.mode == terrain_plugin.TerrainToolMode.BRUSH and terrain_plugin.is_chunk_plane_hovered and terrain_plugin.current_hovered_chunk == coords:
		add_chunk_lines(terrain_system, coords, addchunk_material)
		
	# Remove chunk
	elif terrain_plugin.mode == terrain_plugin.TerrainToolMode.REMOVE_CHUNK and terrain_plugin.is_chunk_plane_hovered and terrain_plugin.current_hovered_chunk == coords:
		add_chunk_lines(terrain_system, coords, removechunk_material) 

# Draw chunk lines around a chunk
func add_chunk_lines(terrain_system: MarchingSquaresTerrain, coords: Vector2i, material: Material):
	var dx = (terrain_system.dimensions.x - 1) * terrain_system.cell_size.x
	var dz = (terrain_system.dimensions.z - 1) * terrain_system.cell_size.y
	var x = coords.x * dx
	var z = coords.y * dz
	dx += x
	dz += z
	
	lines.clear()
	if not terrain_system.chunks.has(Vector2i(coords.x, coords.y-1)):
		lines.append(Vector3(x,0,z))
		lines.append(Vector3(dx,0,z))
	if not terrain_system.chunks.has(Vector2i(coords.x+1, coords.y)):
		lines.append(Vector3(dx,0,z))
		lines.append(Vector3(dx,0,dz))
	if not terrain_system.chunks.has(Vector2i(coords.x, coords.y+1)):
		lines.append(Vector3(dx,0,dz))
		lines.append(Vector3(x,0,dz))
	if not terrain_system.chunks.has(Vector2i(coords.x-1, coords.y)):
		lines.append(Vector3(x,0,dz))
		lines.append(Vector3(x,0,z))
	
	if material == removechunk_material:
		lines.append(Vector3(x,0,z))
		lines.append(Vector3(dx,0,dz))
		lines.append(Vector3(dx,0,z))
		lines.append(Vector3(x,0,dz))
		
	if material == addchunk_material:
		lines.append(Vector3(lerp(x, dx, 0.25), 0, lerp(z, dz, 0.5)))
		lines.append(Vector3(lerp(x, dx, 0.75), 0, lerp(z, dz, 0.5)))
		lines.append(Vector3(lerp(x, dx, 0.5), 0, lerp(z, dz, 0.25)))
		lines.append(Vector3(lerp(x, dx, 0.5), 0, lerp(z, dz, 0.75)))
		
	
	add_lines(lines, material, false)
	
