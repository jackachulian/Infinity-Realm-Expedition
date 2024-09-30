# my_custom_gizmo_plugin.gd
class_name MarchingSquaresTerrainGizmo
extends EditorNode3DGizmo

func _redraw():
	clear()

	var terrain: MarchingSquaresTerrain = get_node_3d()
	
	# Only draw the gizmo if this is the only selected node
	if len(EditorInterface.get_selection().get_selected_nodes()) != 1:
		return
	if EditorInterface.get_selection().get_selected_nodes()[0] != terrain:
		return

	var corners = terrain.verts.slice(0, terrain.dimensions.z * terrain.dimensions.x)	
	add_handles(corners, get_plugin().get_material("handles", self), [])

func _get_handle_name(handle_id: int, secondary: bool) -> String:
	return str(handle_id);
	
func _get_handle_value(handle_id: int, secondary: bool) -> Variant:
	var terrain: MarchingSquaresTerrain = get_node_3d()
	return terrain.verts[handle_id];
	
func _commit_handle(handle_id: int, secondary: bool, restore: Variant, cancel: bool) -> void:
	var terrain: MarchingSquaresTerrain = get_node_3d()
	
	if cancel:
		terrain.verts[handle_id] = restore
		print("cancelled move point")
	else:
		var undo_redo := MarchingSquaresTerrainPlugin.instance.get_undo_redo()
		var do_value := terrain.verts[handle_id]
	
		undo_redo.create_action("move terrain point")
		undo_redo.add_do_method(self, "move_terrain_point", terrain, handle_id, do_value)
		undo_redo.add_undo_method(self, "move_terrain_point", terrain, handle_id, restore)
		undo_redo.commit_action()
		
func move_terrain_point(terrain: MarchingSquaresTerrain, handle_id: int, value: Vector3):
	terrain.verts[handle_id] = value
	var z = handle_id / terrain.dimensions.z
	var x = handle_id % terrain.dimensions.z
	
	notify_needs_update(terrain, z, x)
	notify_needs_update(terrain, z, x-1)
	notify_needs_update(terrain, z-1, x)
	notify_needs_update(terrain, z-1, x-1)
	
	terrain.regenerate_mesh()
	
func notify_needs_update(terrain: MarchingSquaresTerrain, z: int, x: int):
	if z < 0 or z >= terrain.dimensions.z or x < 0 or x > terrain.dimensions.x:
		return
		
	terrain.needs_update[z][x] = true

func _set_handle(handle_id: int, secondary: bool, camera: Camera3D, screen_pos: Vector2) -> void:
	var terrain: MarchingSquaresTerrain = get_node_3d()
	# Get handle position
	var handle_position = terrain.to_global(terrain.verts[handle_id])
	
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
		terrain.verts[handle_id].y = intersection.y
