# my_custom_gizmo_plugin.gd
class_name MarchingSquaresTerrainGizmo
extends EditorNode3DGizmo

var lines: PackedVector3Array = PackedVector3Array()

var addchunk_material: Material
var removechunk_material: Material
var brush_material: Material
var brush_pattern_material: Material

var terrain_plugin: MarchingSquaresTerrainPlugin

func _redraw():
	lines.clear()
	clear()
	
	addchunk_material = get_plugin().get_material("addchunk", self)
	removechunk_material = get_plugin().get_material("removechunk", self)
	brush_material = get_plugin().get_material("brush", self)
	brush_pattern_material = get_plugin().get_material("brush_pattern", self)

	var terrain_system: MarchingSquaresTerrain = get_node_3d()
	terrain_plugin = MarchingSquaresTerrainPlugin.instance
	
	# Only draw the gizmo if this is the only selected node
	if len(EditorInterface.get_selection().get_selected_nodes()) != 1:
		return
	if EditorInterface.get_selection().get_selected_nodes()[0] != terrain_system:
		return

	# Chunk management gizmo lines
	if terrain_system.chunks.is_empty():
		if MarchingSquaresTerrainPlugin.instance.is_chunk_plane_hovered:
			add_chunk_lines(terrain_system, MarchingSquaresTerrainPlugin.instance.current_hovered_chunk, addchunk_material)
	else:
		for chunk_coords: Vector2i in terrain_system.chunks:
			try_add_chunk(terrain_system, Vector2i(chunk_coords.x-1, chunk_coords.y))
			try_add_chunk(terrain_system, Vector2i(chunk_coords.x+1, chunk_coords.y))
			try_add_chunk(terrain_system, Vector2i(chunk_coords.x, chunk_coords.y-1))
			try_add_chunk(terrain_system, Vector2i(chunk_coords.x, chunk_coords.y+1))
			try_add_chunk(terrain_system, chunk_coords)
			
	if terrain_plugin.terrain_hovered and terrain_system.chunks.has(terrain_plugin.current_hovered_chunk):
		#print("adding ", terrain_plugin.BRUSH_VISUAL, " at ", terrain_plugin.brush_position, " with material ", brush_material)
		var pos = terrain_plugin.brush_position
		
		# this should line up the actual draw position over the cursor most closely
		#pos.x += terrain_system.cell_size.x/2
		#pos.z += terrain_system.cell_size.y/2
		
		
		#var x = round(pos.x / terrain_system.cell_size.x - chunk_x * terrain_system.dimensions.x * terrain_system.cell_size.x)
		#var z = round(pos.z / terrain_system.cell_size.y - chunk_z * terrain_system.dimensions.z * terrain_system.cell_size.y)
		#var terrain_height = chunk.height_map[z][x]
		#var draw_position = Vector3(rounded_coords.x, terrain_height, rounded_coords.y)
		
		var chunk_space_coords = Vector2(pos.x / terrain_system.cell_size.x, pos.z / terrain_system.cell_size.y)
		
		var chunk_x = floor(pos.x / ((terrain_system.dimensions.x - 1) * terrain_system.cell_size.x))
		var chunk_z = floor(pos.z / ((terrain_system.dimensions.z - 1) * terrain_system.cell_size.y))
		var chunk_coords := Vector2i(chunk_x, chunk_z)
		if not terrain_system.chunks.has(chunk_coords):
			return
		var chunk: MarchingSquaresTerrainChunk = terrain_system.chunks[chunk_coords]
		
		var x = int(floor(((pos.x + terrain_system.cell_size.x/2) / terrain_system.cell_size.x) - chunk_x * (terrain_system.dimensions.x - 1)))
		var z = int(floor(((pos.z + terrain_system.cell_size.y/2) / terrain_system.cell_size.y) - chunk_z * (terrain_system.dimensions.z - 1)))
		var y = chunk.height_map[z][x]
		
		var cell_coords = Vector2i(x, z)
		print(pos, Vector2(chunk_x, chunk_z), )
		
		var world_x = floor((pos.x + terrain_system.cell_size.x/2) / terrain_system.cell_size.x) * terrain_system.cell_size.x
		var world_z = floor((pos.z + terrain_system.cell_size.y/2) / terrain_system.cell_size.y) * terrain_system.cell_size.y
		
		var draw_position = Vector3(world_x, y, world_z)
		var draw_transform = Transform3D(Vector3.RIGHT, Vector3.UP, Vector3.BACK, draw_position)
		add_mesh(terrain_plugin.BRUSH_VISUAL, brush_material, draw_transform)
		
		if terrain_plugin.is_drawing:
			if not terrain_plugin.current_draw_pattern.has(chunk_coords):
				terrain_plugin.current_draw_pattern[chunk_coords] = {}
			terrain_plugin.current_draw_pattern[chunk_coords][cell_coords] = true
			
			for draw_chunk_coords: Vector2i in terrain_plugin.current_draw_pattern:
				chunk = terrain_system.chunks[draw_chunk_coords]
				var draw_chunk_dict: Dictionary = terrain_plugin.current_draw_pattern[draw_chunk_coords]
				for draw_coords: Vector2i in draw_chunk_dict:
					if draw_chunk_coords == chunk_coords and draw_coords == cell_coords:
						continue
					
					var draw_x = (draw_chunk_coords.x * (terrain_system.dimensions.x - 1) + draw_coords.x) * terrain_system.cell_size.x
					var draw_z = (draw_chunk_coords.y * (terrain_system.dimensions.z - 1) + draw_coords.y) * terrain_system.cell_size.y
					var draw_y = chunk.height_map[draw_coords.y][draw_coords.x]
					
					draw_position = Vector3(draw_x, draw_y, draw_z)
					draw_transform = Transform3D(Vector3.RIGHT, Vector3.UP, Vector3.BACK, draw_position)
					add_mesh(terrain_plugin.BRUSH_VISUAL, brush_pattern_material, draw_transform)
		
func try_add_chunk(terrain_system: MarchingSquaresTerrain, coords: Vector2i):
	var terrain_plugin = MarchingSquaresTerrainPlugin.instance
	
	# Add chunk
	if (terrain_plugin.mode == terrain_plugin.TerrainToolMode.MANAGE_CHUNKS or Input.is_key_pressed(KEY_SHIFT)) and not terrain_system.chunks.has(coords) and terrain_plugin.is_chunk_plane_hovered and terrain_plugin.current_hovered_chunk == coords:
		add_chunk_lines(terrain_system, coords, addchunk_material)
		
	# Remove chunk (Manage Chunk tool only)
	elif terrain_plugin.mode == terrain_plugin.TerrainToolMode.MANAGE_CHUNKS and terrain_plugin.is_chunk_plane_hovered and terrain_plugin.current_hovered_chunk == coords:
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
	#if not terrain_system.chunks.has(Vector2i(coords.x, coords.y-1)):
	lines.append(Vector3(x,0,z))
	lines.append(Vector3(dx,0,z))
	#if not terrain_system.chunks.has(Vector2i(coords.x+1, coords.y)):
	lines.append(Vector3(dx,0,z))
	lines.append(Vector3(dx,0,dz))
	#if not terrain_system.chunks.has(Vector2i(coords.x, coords.y+1)):
	lines.append(Vector3(dx,0,dz))
	lines.append(Vector3(x,0,dz))
	#if not terrain_system.chunks.has(Vector2i(coords.x-1, coords.y)):
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
	
