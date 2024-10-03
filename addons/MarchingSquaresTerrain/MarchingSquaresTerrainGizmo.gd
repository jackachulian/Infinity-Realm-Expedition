# my_custom_gizmo_plugin.gd
class_name MarchingSquaresTerrainGizmo
extends EditorNode3DGizmo

var lines: PackedVector3Array = PackedVector3Array()
var chunks_and_empty: Dictionary = {}

func _redraw():
	clear()

	var terrain_system: MarchingSquaresTerrain = get_node_3d()
	
	# Only draw the gizmo if this is the only selected node
	if len(EditorInterface.get_selection().get_selected_nodes()) != 1:
		return
	if EditorInterface.get_selection().get_selected_nodes()[0] != terrain_system:
		return

	lines.clear()
	chunks_and_empty.clear()
	for chunk_coords: Vector2i in terrain_system.chunks:
		try_add_chunk(terrain_system, chunk_coords)
		try_add_chunk(terrain_system, Vector2i(chunk_coords.x-1, chunk_coords.y))
		try_add_chunk(terrain_system, Vector2i(chunk_coords.x+1, chunk_coords.y))
		try_add_chunk(terrain_system, Vector2i(chunk_coords.x, chunk_coords.y-1))
		try_add_chunk(terrain_system, Vector2i(chunk_coords.x, chunk_coords.y+1))
		

func try_add_chunk(terrain_system, coords: Vector2i):
	# Empty chunks
	if not chunks_and_empty.has(coords):
		chunks_and_empty[coords] = null
		add_chunk_lines(terrain_system, coords, "newchunk")
		return
		
	# Chunk that is hovered over while in remove chunk move (shows in red)
	var terrain_plugin = MarchingSquaresTerrainPlugin.instance
	if terrain_plugin.mode == terrain_plugin.TerrainToolMode.REMOVE_CHUNK and terrain_plugin.is_chunk_hovered and terrain_plugin.current_hovered_chunk == coords:
		print("DRAW REMOVE CHUBNKL ", coords)
		add_chunk_lines(terrain_system, coords, "removechunk") 

# Draw chunk lines around a chunk
func add_chunk_lines(terrain_system: MarchingSquaresTerrain, coords: Vector2i, material_name: String):
	var dx = (terrain_system.dimensions.x - 1) * terrain_system.cell_size.x
	var dz = (terrain_system.dimensions.z - 1) * terrain_system.cell_size.y
	var x = coords.x * dx
	var z = coords.y * dz
	dx += x
	dz += z
	
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
	
	if material_name == "removechunk":
		lines.append(Vector3(x,0,z))
		lines.append(Vector3(dx,0,dz))
		lines.append(Vector3(dx,0,z))
		lines.append(Vector3(x,0,dz))
	
	add_lines(lines, get_plugin().get_material(material_name, self), false)
