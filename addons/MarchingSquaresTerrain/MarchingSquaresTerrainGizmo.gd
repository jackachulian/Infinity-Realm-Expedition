# my_custom_gizmo_plugin.gd
class_name MarchingSquaresTerrainGizmo
extends EditorNode3DGizmo

var lines: PackedVector3Array = PackedVector3Array()

var addchunk_material: Material
var removechunk_material: Material
var brush_material: Material

var terrain_plugin: MarchingSquaresTerrainPlugin

func _redraw():
	lines.clear()
	clear()
	
	addchunk_material = get_plugin().get_material("addchunk", self)
	removechunk_material = get_plugin().get_material("removechunk", self)
	brush_material = get_plugin().get_material("brush", self)

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
			
	var pos: Vector3 = terrain_plugin.brush_position
	var cursor_chunk_coords: Vector2i
	var cursor_cell_coords: Vector2i
			
	if terrain_plugin.is_setting and not terrain_plugin.draw_height_set:
		terrain_plugin.draw_height_set = true
		
		var chunk_x = floor(pos.x / ((terrain_system.dimensions.x - 1) * terrain_system.cell_size.x))
		var chunk_z = floor(pos.z / ((terrain_system.dimensions.z - 1) * terrain_system.cell_size.y))
		cursor_chunk_coords = Vector2i(chunk_x, chunk_z)
		
		var x = int(floor(((pos.x + terrain_system.cell_size.x/2) / terrain_system.cell_size.x) - chunk_x * (terrain_system.dimensions.x - 1)))
		var z = int(floor(((pos.z + terrain_system.cell_size.y/2) / terrain_system.cell_size.y) - chunk_z * (terrain_system.dimensions.z - 1)))
		cursor_cell_coords = Vector2i(x, z)
		
		# when setting, if the clicked tile is not part of the pattern and alt not held, go to draw mode
		var cursor_in_pattern: bool = terrain_plugin.current_draw_pattern.has(cursor_chunk_coords) and terrain_plugin.current_draw_pattern[cursor_chunk_coords].has(cursor_cell_coords)
		if not cursor_in_pattern and not Input.is_key_pressed(KEY_ALT):
			terrain_plugin.current_draw_pattern.clear()
			terrain_plugin.is_setting = false
			terrain_plugin.is_drawing = true
			terrain_plugin.draw_height = pos.y
		
		# otherwise, drag that pattern's height
		else:
			print("setting")
			# if alt held, ONLY drag the cursor cell
			if Input.is_key_pressed(KEY_ALT):
				terrain_plugin.current_draw_pattern.clear()
				terrain_plugin.current_draw_pattern[cursor_chunk_coords] = {}
				terrain_plugin.current_draw_pattern[cursor_chunk_coords][cursor_cell_coords] = terrain_system.chunks[cursor_chunk_coords].get_height(cursor_cell_coords)
				terrain_plugin.draw_height = pos.y
			terrain_plugin.base_position = pos
			
	if terrain_plugin.is_drawing and not terrain_plugin.draw_height_set:
		print("drawing")
		terrain_plugin.draw_height_set = true
		terrain_plugin.draw_height = terrain_plugin.brush_position.y
			
	var terrain_chunk_hovered: bool = terrain_plugin.terrain_hovered and terrain_system.chunks.has(terrain_plugin.current_hovered_chunk)
	
	if terrain_chunk_hovered:
		var brush_transform = Transform3D(Vector3.RIGHT * terrain_plugin.brush_size, Vector3.UP, Vector3.BACK * terrain_plugin.brush_size, pos)
		add_mesh(terrain_plugin.BRUSH_RADIUS_VISUAL, null, brush_transform)

		pos = terrain_plugin.brush_position
		
		#var chunk_space_coords = Vector2(pos.x / terrain_system.cell_size.x, pos.z / terrain_system.cell_size.y)
		
		var pos_tl := Vector2(pos.x + terrain_system.cell_size.x - terrain_plugin.brush_size/2, pos.z + terrain_system.cell_size.y - terrain_plugin.brush_size/2)
		var pos_br := Vector2(pos.x + terrain_system.cell_size.x + terrain_plugin.brush_size/2, pos.z + terrain_system.cell_size.y + terrain_plugin.brush_size/2)
		
		#var chunk_space_topleft := Vector2(pos_tl.x / terrain_system.cell_size.x, pos_tl.y / terrain_system.cell_size.y)
		#var chunk_space_bottomright := Vector2(pos_br.x / terrain_system.cell_size.x, pos_br.y / terrain_system.cell_size.y)
		
		var chunk_tl_x := floori(pos_tl.x / ((terrain_system.dimensions.x - 1) * terrain_system.cell_size.x))
		var chunk_tl_z := floori(pos_tl.y / ((terrain_system.dimensions.z - 1) * terrain_system.cell_size.y))
		
		var chunk_br_x := floori(pos_br.x / ((terrain_system.dimensions.x - 1) * terrain_system.cell_size.x))
		var chunk_br_z := floori(pos_br.y / ((terrain_system.dimensions.z - 1) * terrain_system.cell_size.y))
		
		#var chunk_x = floor(pos.x / ((terrain_system.dimensions.x - 1) * terrain_system.cell_size.x))
		#var chunk_z = floor(pos.z / ((terrain_system.dimensions.z - 1) * terrain_system.cell_size.y))
		
		var x_tl := floori(pos_tl.x / terrain_system.cell_size.x - chunk_tl_x * (terrain_system.dimensions.x - 1))
		var z_tl := floori(pos_tl.y / terrain_system.cell_size.y - chunk_tl_z * (terrain_system.dimensions.z - 1))
		
		var x_br := floori(pos_br.x / terrain_system.cell_size.x - chunk_br_x * (terrain_system.dimensions.x - 1))
		var z_br := floori(pos_br.y / terrain_system.cell_size.y - chunk_br_z * (terrain_system.dimensions.z - 1))
		
		#print(Vector2i(x_tl, z_tl), " ", Vector2i(x_br, z_br))
		
		#var world_x = floor((pos.x + terrain_system.cell_size.x/2) / terrain_system.cell_size.x) * terrain_system.cell_size.x
		#var world_z = floor((pos.z + terrain_system.cell_size.y/2) / terrain_system.cell_size.y) * terrain_system.cell_size.y
		
		var max_distance = (terrain_plugin.brush_size/2)
		var max_distance_squared = max_distance*max_distance
		
		for chunk_z in range(chunk_tl_z, chunk_br_z+1):
			for chunk_x in range(chunk_tl_x, chunk_br_x+1):
				cursor_chunk_coords = Vector2i(chunk_x, chunk_z)
				if not terrain_system.chunks.has(cursor_chunk_coords):
					continue
				var chunk: MarchingSquaresTerrainChunk = terrain_system.chunks[cursor_chunk_coords]
				
				var x_min := x_tl if chunk_x == chunk_tl_x else 0
				var x_max := x_br if chunk_x == chunk_br_x else terrain_system.dimensions.x
				
				var z_min := z_tl if chunk_z == chunk_tl_z else 0
				var z_max := z_br if chunk_z == chunk_br_z else terrain_system.dimensions.z
				
				#print(cursor_chunk_coords, ": ", Vector2i(x_min, x_max), " ", Vector2i(z_min, z_max))
				
				for z in range(z_min, z_max):
					for x in range(x_min, x_max):
						cursor_cell_coords = Vector2i(x, z)
						var world_x: float = (chunk_x * (terrain_system.dimensions.x-1) + x) * terrain_system.cell_size.x
						var world_z: float = (chunk_z * (terrain_system.dimensions.z-1) + z) * terrain_system.cell_size.y
						
						var distance_squared: float = Vector2(pos.x, pos.z).distance_squared_to(Vector2(world_x, world_z))
						if distance_squared > max_distance_squared:
							continue
							
						var sample
						if terrain_plugin.falloff:
							var t = (max_distance_squared - distance_squared)/max_distance_squared
							sample = terrain_plugin.falloff_curve.sample(t)
						else:
							sample = 1.0
						
						var y: float
						if not terrain_plugin.current_draw_pattern.is_empty() and terrain_plugin.flatten:
							y = terrain_plugin.draw_height
						else:
							y = chunk.height_map[z][x]
						
						var draw_position = Vector3(world_x, y, world_z)
						var draw_transform = Transform3D(Vector3.RIGHT*sample, Vector3.UP*sample, Vector3.BACK*sample, draw_position)
						add_mesh(terrain_plugin.BRUSH_VISUAL, brush_material, draw_transform)
						
						# Draw to current pattern
						if terrain_plugin.is_drawing:
							if not terrain_plugin.current_draw_pattern.has(cursor_chunk_coords):
								terrain_plugin.current_draw_pattern[cursor_chunk_coords] = {}
							if terrain_plugin.current_draw_pattern[cursor_chunk_coords].has(cursor_cell_coords):
								var prev_sample = terrain_plugin.current_draw_pattern[cursor_chunk_coords][cursor_cell_coords]
								if sample > prev_sample:
									terrain_plugin.current_draw_pattern[cursor_chunk_coords][cursor_cell_coords] = sample
							else:
								terrain_plugin.current_draw_pattern[cursor_chunk_coords][cursor_cell_coords] = sample
								
			
	var height_diff: float
	if terrain_plugin.is_setting and terrain_plugin.draw_height_set:
		height_diff = terrain_plugin.brush_position.y - terrain_plugin.draw_height
			
	if not terrain_plugin.current_draw_pattern.is_empty():
		for draw_chunk_coords: Vector2i in terrain_plugin.current_draw_pattern:
			var chunk = terrain_system.chunks[draw_chunk_coords]
			var draw_chunk_dict: Dictionary = terrain_plugin.current_draw_pattern[draw_chunk_coords]
			for draw_coords: Vector2i in draw_chunk_dict:
				var draw_x = (draw_chunk_coords.x * (terrain_system.dimensions.x - 1) + draw_coords.x) * terrain_system.cell_size.x
				var draw_z = (draw_chunk_coords.y * (terrain_system.dimensions.z - 1) + draw_coords.y) * terrain_system.cell_size.y
				var draw_y = terrain_plugin.draw_height if terrain_plugin.flatten else chunk.height_map[draw_coords.y][draw_coords.x]
				
				var sample: float = draw_chunk_dict[draw_coords]
				
				# If setting, also show a square at the height to set to
				if terrain_plugin.is_setting and terrain_plugin.draw_height_set:
					var draw_position = Vector3(draw_x, draw_y + height_diff * sample, draw_z)
					var draw_transform = Transform3D(Vector3.RIGHT*sample, Vector3.UP*sample, Vector3.BACK*sample, draw_position)
					add_mesh(terrain_plugin.BRUSH_VISUAL, null, draw_transform)
				else:
					var draw_position = Vector3(draw_x, draw_y, draw_z)
					var draw_transform = Transform3D(Vector3.RIGHT*sample, Vector3.UP*sample, Vector3.BACK*sample, draw_position)
					add_mesh(terrain_plugin.BRUSH_VISUAL, null, draw_transform)
		
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
	
