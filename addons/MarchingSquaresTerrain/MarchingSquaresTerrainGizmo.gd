# my_custom_gizmo_plugin.gd
class_name MarchingSquaresTerrainGizmo
extends EditorNode3DGizmo

var lines: PackedVector3Array = PackedVector3Array()
var chunks_and_empty: Dictionary

func _redraw():
	clear()

	var terrain_system: MarchingSquaresTerrain = get_node_3d()
	
	# Only draw the gizmo if this is the only selected node
	if len(EditorInterface.get_selection().get_selected_nodes()) != 1:
		return
	if EditorInterface.get_selection().get_selected_nodes()[0] != terrain_system:
		return
		
	# Lines for adding more chunks
	lines.clear()
	
	# Dictionary holding all chunks and neighbouring empty chunk slots (null)
	chunks_and_empty = terrain_system.chunks.duplicate()
	for chunk_coords: Vector2i in chunks_and_empty.keys():
		try_add_empty_chunk(Vector2i(chunk_coords.x-1, chunk_coords.y))
		try_add_empty_chunk(Vector2i(chunk_coords.x+1, chunk_coords.y))
		try_add_empty_chunk(Vector2i(chunk_coords.x, chunk_coords.y-1))
		try_add_empty_chunk(Vector2i(chunk_coords.x, chunk_coords.y+1))
		
	for chunk_coords: Vector2i in chunks_and_empty.keys():
		if chunks_and_empty[chunk_coords] == null:
			chunk_lines(terrain_system, chunk_coords, true)
	
	add_lines(lines, get_plugin().get_material("thischunk", self), false)
	
	

func try_add_empty_chunk(coords: Vector2i):
	if not chunks_and_empty.has(coords):
		chunks_and_empty[coords] = null

# Draw chunk lines around a chunk
func chunk_lines(terrain_system: MarchingSquaresTerrain, coords: Vector2i, newchunk: bool):
	var dx = (terrain_system.dimensions.x - 1) * terrain_system.cell_size.x
	var dz = (terrain_system.dimensions.z - 1) * terrain_system.cell_size.y
	var x = coords.x * dx
	var z = coords.y * dz
	dx += x
	dz += z
	
	lines.append(Vector3(x,0,z))
	lines.append(Vector3(dx,0,z))
	lines.append(Vector3(dx,0,z))
	lines.append(Vector3(dx,0,dz))
	lines.append(Vector3(dx,0,dz))
	lines.append(Vector3(x,0,dz))
	lines.append(Vector3(x,0,dz))
	lines.append(Vector3(x,0,z))
	
	add_lines(lines, get_plugin().get_material("newchunk" if newchunk else "filledchunk", self), false)
	
	add_mesh()
