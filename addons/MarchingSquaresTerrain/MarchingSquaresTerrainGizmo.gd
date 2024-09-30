# my_custom_gizmo_plugin.gd
class_name MarchingSquaresTerrainGizmo
extends EditorNode3DGizmoPlugin


func _get_gizmo_name():
	return "MarchingSquaresTerrainGizmo"
	
func _has_gizmo(node):
	return node is MarchingSquaresTerrain

func _init():
	create_material("main", Color(1,0,1))
	create_handle_material("handles")
	
func _redraw(gizmo):
	gizmo.clear()

	var terrain: MarchingSquaresTerrain = gizmo.get_node_3d()
	
	# Only draw the gizmo if this is the only selected node
	if len(EditorInterface.get_selection().get_selected_nodes()) != 1:
		return
	if EditorInterface.get_selection().get_selected_nodes()[0] != terrain:
		return

	var corners = terrain.verts.slice(0, terrain.dimensions.z * terrain.dimensions.x)	
	gizmo.add_handles(corners, get_material("handles", gizmo), [])

func _get_handle_name(gizmo: EditorNode3DGizmo, handle_id: int, secondary: bool) -> String:
	return str(handle_id);
	
func _get_handle_value(gizmo: EditorNode3DGizmo, handle_id: int, secondary: bool) -> Variant:
	var terrain: MarchingSquaresTerrain = gizmo.get_node_3d()
	return terrain.verts[handle_id];
	
#func _commit_handle(gizmo: EditorNode3DGizmo, handle_id: int, secondary: bool, restore: Variant, cancel: bool) -> void:
	#var terrain: MarchingSquaresTerrain = gizmo.get_node_3d()
	#var undo_redo := UndoRedo.new()
	#var do_value := terrain.verts[handle_id]
	#
	#if cancel:
		#terrain.verts[handle_id] = restore
	#else:
		#undo_redo.create_action("move point")
		#undo_redo.add_do_method(func(): terrain.verts[handle_id] = do_value)
		#
		#undo_redo.create_action("undo: move point")
		#undo_redo.add_do_method(func(): terrain.verts[handle_id] = restore)
		#
		#undo_redo.commit_action()

func _set_handle(gizmo: EditorNode3DGizmo, handle_id: int, secondary: bool, camera: Camera3D, screen_pos: Vector2) -> void:
	var terrain: MarchingSquaresTerrain = gizmo.get_node_3d()
	# Get handle position
	var handle_position = terrain.verts[handle_id]
	
	# Convert mouse movement to 3D world coordinates using raycasting
	var ray_origin = camera.project_ray_origin(screen_pos)
	var ray_dir = camera.project_ray_normal(screen_pos)
	
	# We want the movement restricted to the Y-axis.
	# Create a plane that is parallel to the XZ plane (normal pointing along Y-axis)
	var plane = Plane(Vector3(0, 1, 0), handle_position)
	var intersection = plane.intersects_ray(ray_origin, ray_dir)
	
	if intersection != null:		
		# Update the handle's Y position
		terrain.verts[handle_id] = intersection.y
		print("new y: "+intersection.y)
