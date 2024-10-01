# my_custom_gizmo_plugin.gd
class_name MarchingSquaresTerrainChunkGizmo
extends EditorNode3DGizmo

func _redraw():
	clear()

	var terrain: MarchingSquaresTerrainChunk = get_node_3d()
	var dx = (terrain.dimensions.x - 1) * terrain.cell_size.x
	var dz = (terrain.dimensions.z - 1) * terrain.cell_size.y
	
	# Only draw the gizmo if this is the only selected node
	if len(EditorInterface.get_selection().get_selected_nodes()) != 1:
		return
	if EditorInterface.get_selection().get_selected_nodes()[0] != terrain:
		return

	# Handles for raising/lowering terrain (will probably be removed later in favor of brush)
	var corners = PackedVector3Array()
	var ids = PackedInt32Array()
	for z in range(terrain.dimensions.z):
		for x in range(terrain.dimensions.x):
			var y = terrain.height_map[z][x]
			corners.append(Vector3(x * terrain.cell_size.x, y, z * terrain.cell_size.y))
			ids.append(z*terrain.dimensions.x + x)
	add_handles(corners, get_plugin().get_material("handles", self), ids)

func _get_handle_name(handle_id: int, secondary: bool) -> String:
	return str(handle_id);
	
func _get_handle_value(handle_id: int, secondary: bool) -> Variant:
	var terrain: MarchingSquaresTerrainChunk = get_node_3d()
	var z = handle_id / terrain.dimensions.z
	var x = handle_id % terrain.dimensions.z
	return terrain.height_map[z][x];
	
func _commit_handle(handle_id: int, secondary: bool, restore: Variant, cancel: bool) -> void:
	var terrain: MarchingSquaresTerrainChunk = get_node_3d()
	var z = handle_id / terrain.dimensions.z
	var x = handle_id % terrain.dimensions.z
	
	if cancel:
		terrain.height_map[z][x] = restore
		print("cancelled move point")
	else:
		var undo_redo := MarchingSquaresTerrainPlugin.instance.get_undo_redo()
		
		var do_value = terrain.height_map[z][x]
	
		undo_redo.create_action("move terrain point")
		undo_redo.add_do_method(self, "move_terrain_point", terrain, handle_id, do_value)
		undo_redo.add_undo_method(self, "move_terrain_point", terrain, handle_id, restore)
		undo_redo.commit_action()
		
func move_terrain_point(terrain: MarchingSquaresTerrainChunk, handle_id: int, height: float):
	var z = handle_id / terrain.dimensions.z
	var x = handle_id % terrain.dimensions.z
	terrain.height_map[z][x] = height
	
	#notify_needs_update(terrain, z, x)
	#notify_needs_update(terrain, z, x-1)
	#notify_needs_update(terrain, z-1, x)
	#notify_needs_update(terrain, z-1, x-1)
	
	terrain.regenerate_mesh()
	
#func notify_needs_update(terrain: MarchingSquaresTerrain, z: int, x: int):
	#if z < 0 or z >= terrain.dimensions.z or x < 0 or x > terrain.dimensions.x:
		#return
		#
	#terrain.needs_update[z][x] = true

func _set_handle(handle_id: int, secondary: bool, camera: Camera3D, screen_pos: Vector2) -> void:
	var terrain: MarchingSquaresTerrainChunk = get_node_3d()
	var z = handle_id / terrain.dimensions.z
	var x = handle_id % terrain.dimensions.z
	var y = terrain.height_map[z][x]
	# Get handle position
	var handle_position = terrain.to_global(Vector3(x * terrain.cell_size.x, y, z * terrain.cell_size.y))
	
	# Convert mouse movement to 3D world coordinates using raycasting
	var ray_origin = camera.project_ray_origin(screen_pos)
	var ray_dir = camera.project_ray_normal(screen_pos)
	
	# We want the movement restricted to the Y-axis.
	# Create a plane that is parallel to the XZ plane (normal pointing along Y-axis)
	var plane = Plane(ray_dir, handle_position)
	var intersection = plane.intersects_ray(ray_origin, ray_dir)
	#
	#print("handle_position ", handle_position, "ray_origin ", ray_origin, "ray_dir ", ray_dir, "plane ", plane)
	#
	if intersection:
		intersection = terrain.to_local(intersection)
		terrain.height_map[z][x] = intersection.y
