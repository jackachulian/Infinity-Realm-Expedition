@tool
class_name MarchingSquaresTerrainPlugin
extends EditorPlugin

static var instance: MarchingSquaresTerrainPlugin

var gizmo_plugin = MarchingSquaresTerrainGizmoPlugin.new()

var terrain_brush_dock: OptionButton
var terrain_brush_dock_active: bool

enum TerrainToolMode {
	BRUSH = 0,
	MANAGE_CHUNKS = 1
}
var mode: TerrainToolMode = TerrainToolMode.BRUSH

var is_chunk_plane_hovered: bool
var current_hovered_chunk: Vector2i

var brush_position: Vector3

# current drawing radius
var brush_radius: float

# A dictionary with keys for each tile that is currently being drawn to with the brush (value is not used)
# would use a Set but there is none in gdscript
var current_draw_pattern: Dictionary

var terrain_hovered: bool

# True if the mouse is currently held down to draw
var is_drawing: bool

const BRUSH_VISUAL: Mesh = preload("brush_visual.tres")

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
		terrain_brush_dock_active = true
		terrain_brush_dock.selected = mode
		terrain_brush_dock.item_selected.connect(on_terrain_tool_changed)
		add_control_to_container(CONTAINER_SPATIAL_EDITOR_MENU, terrain_brush_dock)
		
func deactivate_terrain_brush_dock():
	if terrain_brush_dock_active:
		terrain_brush_dock_active = false
		terrain_brush_dock.item_selected.disconnect(on_terrain_tool_changed)
		remove_control_from_container(CONTAINER_SPATIAL_EDITOR_MENU, terrain_brush_dock)

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
	
	# Handle clicks
	if event is InputEventMouseButton or event is InputEventMouseMotion:
		return handle_mouse(camera, event)
			
	return EditorPlugin.AFTER_GUI_INPUT_PASS
	
func handle_mouse(camera: Camera3D, event: InputEvent) -> int:
	terrain_hovered = false
	var terrain: MarchingSquaresTerrain = EditorInterface.get_selection().get_selected_nodes()[0]
	
	# Get the mouse position in the viewport
	var editor_viewport = EditorInterface.get_editor_viewport_3d()
	var mouse_pos = editor_viewport.get_mouse_position()	

	var ray_origin := camera.project_ray_origin(mouse_pos)
	var ray_dir := camera.project_ray_normal(mouse_pos)
	
	var shift_held = Input.is_key_pressed(KEY_SHIFT)
	
	# If in brush mode, perform terrain raycast
	if mode == TerrainToolMode.BRUSH:
		# Perform the raycast to check for intersection with a physics body
		var space_state = camera.get_world_3d().direct_space_state
		var ray_length := 10000.0  # Adjust ray length as needed
		var end := ray_origin + ray_dir * ray_length
		var query := PhysicsRayQueryParameters3D.create(ray_origin, end)
		var result = space_state.intersect_ray(query)

		# Check for terrain collision
		if result:
			terrain_hovered = true
			var chunk_x: int = floor(result.position.x / (terrain.dimensions.x * terrain.cell_size.x))
			var chunk_z: int = floor(result.position.z / (terrain.dimensions.z * terrain.cell_size.y))
			var chunk_coords = Vector2i(chunk_x, chunk_z)

			is_chunk_plane_hovered = true
			current_hovered_chunk = chunk_coords
			
			var intersection_pos = result.position
			var body: PhysicsBody3D = result.collider;
			
			if event is InputEventMouseButton and event.button_index == MouseButton.MOUSE_BUTTON_LEFT:
				if event.is_pressed():
					print("Clicked ", body.name, " at: ", intersection_pos)
					is_drawing = true
				elif event.is_released():
					is_drawing = false
					pass
				return EditorPlugin.AFTER_GUI_INPUT_STOP
				
			if event is InputEventMouseMotion:
				brush_position = result.position
				
			gizmo_plugin.terrain_gizmo._redraw()
			return EditorPlugin.AFTER_GUI_INPUT_PASS
		
	# Check for hovering over/ckicking new chunk
	var chunk_plane = Plane(Vector3.UP, Vector3.ZERO)
	var intersection = chunk_plane.intersects_ray(ray_origin, ray_dir)
	
	if intersection:
		var chunk_x: int = floor(intersection.x / (terrain.dimensions.x * terrain.cell_size.x))
		var chunk_z: int = floor(intersection.z / (terrain.dimensions.z * terrain.cell_size.y))
		var chunk_coords = Vector2i(chunk_x, chunk_z)
		var chunk = terrain.chunks.get(chunk_coords)
		
		current_hovered_chunk = chunk_coords
		is_chunk_plane_hovered = true
	
		# On click, add chunk if in brush mode, or remove if in remove chunk mode
		if mode == TerrainToolMode.MANAGE_CHUNKS and event is InputEventMouseButton and event.is_pressed() and event.button_index == MouseButton.MOUSE_BUTTON_LEFT:
			# Remove chunk
			if chunk and shift_held:
				var removed_chunk = terrain.chunks[chunk_coords]
				get_undo_redo().create_action("remove chunk")
				get_undo_redo().add_do_method(terrain, "remove_chunk_from_tree", chunk_x, chunk_z)
				get_undo_redo().add_undo_method(terrain, "add_chunk", chunk_coords, removed_chunk)
				get_undo_redo().commit_action()
				return EditorPlugin.AFTER_GUI_INPUT_STOP
				
			# Add new chunk
			elif not chunk and not shift_held:
				# Can add a new chunk here if there is a neighbouring non-empty chunk
				# also add if there are no chunks at all in the current terrain system
				var can_add_empty: bool = terrain.chunks.is_empty() or terrain.has_chunk(chunk_x-1, chunk_z) or terrain.has_chunk(chunk_x+1, chunk_z) or terrain.has_chunk(chunk_x, chunk_z-1) or terrain.has_chunk(chunk_x, chunk_z+1)
				if can_add_empty:				
					get_undo_redo().create_action("add chunk")
					get_undo_redo().add_do_method(terrain, "add_new_chunk", chunk_x, chunk_z)
					get_undo_redo().add_undo_method(terrain, "remove_chunk", chunk_x, chunk_z)
					get_undo_redo().commit_action()
					return EditorPlugin.AFTER_GUI_INPUT_STOP
		
		gizmo_plugin.terrain_gizmo._redraw()
	else:
		is_chunk_plane_hovered = false
		
	# Consume clicks but allow other click / mouse motion types to reach the gui, for camera movement, etc	
	if event is InputEventMouseButton and event.is_pressed() and event.button_index == MouseButton.MOUSE_BUTTON_LEFT:
		return EditorPlugin.AFTER_GUI_INPUT_STOP
		
	return EditorPlugin.AFTER_GUI_INPUT_PASS

func on_terrain_tool_changed(index: int):
	print("set mode to ", index)
	mode = index
