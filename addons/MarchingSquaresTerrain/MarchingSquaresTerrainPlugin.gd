@tool
class_name MarchingSquaresTerrainPlugin
extends EditorPlugin

static var instance: MarchingSquaresTerrainPlugin

var gizmo_plugin = MarchingSquaresTerrainGizmoPlugin.new()

var terrain_brush_dock: Control
var terrain_brush_dock_active: bool

# This function gets called when the plugin is activated.
func _enter_tree():
	instance = self
	add_custom_type("MarchingSquaresTerrain", "Node3D", preload("MarchingSquaresTerrain.gd"), preload("res://icon.svg"))
	add_custom_type("MarchingSquaresTerrainChunk", "MeshInstance3D", preload("MarchingSquaresTerrainChunk.gd"), preload("res://icon.svg"))
	add_node_3d_gizmo_plugin(gizmo_plugin)

# This function gets called when the plugin is deactivated.
func _exit_tree():
	deactivate_terrain_brush_dock()
	terrain_brush_dock.free()
	remove_custom_type("MarchingSquaresTerrain")
	remove_node_3d_gizmo_plugin(gizmo_plugin)
	
func activate_terrain_brush_dock():
	if not terrain_brush_dock_active:
		terrain_brush_dock = preload("terrain-brush-dock.tscn").instantiate()
		add_control_to_container(CONTAINER_SPATIAL_EDITOR_MENU, terrain_brush_dock)
		terrain_brush_dock_active = true
		
func deactivate_terrain_brush_dock():
	if terrain_brush_dock_active:
		remove_control_from_container(CONTAINER_SPATIAL_EDITOR_MENU, terrain_brush_dock)
		terrain_brush_dock_active = false

func _edit(object: Object) -> void:
	if object is MarchingSquaresTerrain:
		activate_terrain_brush_dock()
	else:
		deactivate_terrain_brush_dock()

func _handles(object: Object) -> bool:
	return object is MarchingSquaresTerrain

#This function handles the mouse click in the 3D viewport
func _forward_3d_gui_input(camera: Camera3D, event: InputEvent) -> int:
	var selected = EditorInterface.get_selection().get_selected_nodes()
	# only proceed if exactly 1 terrain system is selected
	if not selected or len(selected) > 1:
		return EditorPlugin.AFTER_GUI_INPUT_PASS
	var terrain: MarchingSquaresTerrain = selected[0]
	
	if event is InputEventMouseButton and event.pressed and event.button_index == MouseButton.MOUSE_BUTTON_LEFT:
		# Check that the 3d tab is active
		if get_main_screen() != "3D":
			return EditorPlugin.AFTER_GUI_INPUT_PASS
		
		var editor_viewport = EditorInterface.get_editor_viewport_3d()
		
		# Get the mouse position in the viewport
		var mouse_pos = editor_viewport.get_mouse_position()
		
		var viewport_rect = editor_viewport.get_visible_rect()
		if not viewport_rect.has_point(mouse_pos):
			return EditorPlugin.AFTER_GUI_INPUT_PASS

		var ray_origin := camera.project_ray_origin(mouse_pos)
		var ray_dir := camera.project_ray_normal(mouse_pos)

		# Perform the raycast to check for intersection with a physics body
		var space_state = camera.get_world_3d().direct_space_state
		var ray_length := 10000.0  # Adjust ray length as needed
		var end := ray_origin + ray_dir * ray_length
		var query := PhysicsRayQueryParameters3D.create(ray_origin, end)
		var result = space_state.intersect_ray(query)

		if result:
			var intersection_pos = result.position
			var body: PhysicsBody3D = result.collider;
			print("Intersected with ", body.name, " at:", intersection_pos)
			return EditorPlugin.AFTER_GUI_INPUT_STOP
		else:
			# Check for hovering over/ckicking new chunk
			var chunk_plane = Plane(Vector3.UP, Vector3.ZERO)
			var intersection = chunk_plane.intersects_ray(ray_origin, ray_dir)
			if intersection:
				print("chunk plane intersection: ", intersection)
				var chunk_x: int = floor(intersection.x / (terrain.dimensions.x * terrain.cell_size.x))
				var chunk_z: int = floor(intersection.z / (terrain.dimensions.z * terrain.cell_size.y))
				var chunk_coords = Vector2i(chunk_x, chunk_z)
				var chunk = terrain.chunks.get(chunk_coords)
				if chunk:
					# there is a chunk here, but click raycast didn't hit any terrain, so just ignore it but still consume the input
					print("clicked existing chunk ", chunk_coords)
					return EditorPlugin.AFTER_GUI_INPUT_STOP
				else:
					print("no chunk at ", chunk_coords)
					
					# Can add a new chunk here if there is a neighbouring non-empty chunk
					var can_add_empty: bool = terrain.has_chunk(chunk_x-1, chunk_z) or terrain.has_chunk(chunk_x+1, chunk_z) or terrain.has_chunk(chunk_x, chunk_z-1) or terrain.has_chunk(chunk_x, chunk_z+1)
					if can_add_empty:
						print("adding new empty chunk")
						terrain.add_new_chunk(chunk_x, chunk_z)
						return EditorPlugin.AFTER_GUI_INPUT_STOP
					
			else:
				print("No intersection")
			
	return EditorPlugin.AFTER_GUI_INPUT_PASS
	
func get_main_screen()->String:
	var screen="null"
	var base:Panel = get_editor_interface().get_base_control()
	var editor_head:BoxContainer = base.get_child(0).get_child(0)
	if editor_head.get_child_count()<3:
		return screen
		
	var main_screen_buttons:Array = editor_head.get_child(2).get_children()
	for button in main_screen_buttons:
		if button.button_pressed:
			screen = button.text
			break
	return screen
