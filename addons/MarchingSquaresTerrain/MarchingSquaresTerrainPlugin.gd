@tool
class_name MarchingSquaresTerrainPlugin
extends EditorPlugin

static var instance: MarchingSquaresTerrainPlugin

var gizmo_plugin = MarchingSquaresTerrainGizmoPlugin.new()

var terrain_brush_dock_active: bool
var terrain_brush_dock: Control
var tool_options_button: OptionButton
var tool_checkbox: CheckBox
var color_picker: ColorPickerButton

enum TerrainToolMode {
	BRUSH = 0,
	MANAGE_CHUNKS = 1,
	GROUND_TEXTURE = 2
}
var mode: TerrainToolMode = TerrainToolMode.BRUSH

var flatten: bool = true

var is_chunk_plane_hovered: bool
var current_hovered_chunk: Vector2i

var brush_position: Vector3

# current drawing brush size
var brush_size: float = 3.0

# Color currently being drawn to the ground texture
var ground_texture_color: Color

# A dictionary with keys for each tile that is currently being drawn to with the brush. 
# in brush mode, value is the height that preview was drawn to, aka height BEFORE it is set
# in ground texture mode, value is the color of the point BEFORE the draw
var current_draw_pattern: Dictionary

var terrain_hovered: bool

# True if the mouse is currently held down to draw
var is_drawing: bool

# when brush draws, if the gizmo sees draw height is not set, it will set the draw height
var draw_height_set: bool

# Height the current pattern is being drawn at for the brush tool.
var draw_height: float

# Is set to true when player clicks on a tile that is part of the current draw pattern, will enter heightdrag setting mode
var is_setting: bool

# The point where the height drag started.
var base_position: Vector3

const BRUSH_VISUAL: Mesh = preload("brush_visual.tres")
var BRUSH_RADIUS_VISUAL: Mesh

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
		
		BRUSH_RADIUS_VISUAL = preload("brush_radius_visual.tres")
		
		tool_options_button = terrain_brush_dock.get_node("BrushToolOptionsButton")
		tool_options_button.selected = mode
		tool_options_button.item_selected.connect(on_tool_mode_changed)
		
		tool_checkbox = terrain_brush_dock.get_node("FlattenCheckBox")
		tool_checkbox.toggled.connect(on_tool_checkbox_changed)
		
		color_picker = terrain_brush_dock.get_node("ColorPickerButton")
		color_picker.color_changed.connect(on_color_picker_changed)
		
		on_tool_mode_changed(mode)
		
		add_control_to_container(CONTAINER_SPATIAL_EDITOR_MENU, terrain_brush_dock)
		
func deactivate_terrain_brush_dock():
	if terrain_brush_dock_active:
		terrain_brush_dock_active = false
		tool_options_button.item_selected.disconnect(on_tool_mode_changed)
		tool_checkbox.toggled.disconnect(on_tool_checkbox_changed)
		color_picker.color_changed.disconnect(on_color_picker_changed)
		remove_control_from_container(CONTAINER_SPATIAL_EDITOR_MENU, terrain_brush_dock)

func _edit(object: Object) -> void:
	if object is MarchingSquaresTerrain:
		activate_terrain_brush_dock()
	else:
		deactivate_terrain_brush_dock()
		current_draw_pattern.clear()
		is_drawing = false
		draw_height_set = false
		if gizmo_plugin.terrain_gizmo:
			gizmo_plugin.terrain_gizmo.clear()

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
	
	# If in brush mode or ground drawing mode, perform terrain raycast
	if mode == TerrainToolMode.BRUSH or mode == TerrainToolMode.GROUND_TEXTURE:
		var draw_position
		var draw_area_hovered: bool = false
		
		if is_setting and draw_height_set:
			var set_plane = Plane(Vector3(ray_dir.x, 0, ray_dir.z), base_position)
			var set_position = set_plane.intersects_ray(ray_origin, ray_dir)
			if set_position:
				brush_position = set_position
		
		# if there is any pattern and flatten is enabled, draw along that height plane instead of terrain intersection
		elif not current_draw_pattern.is_empty() and flatten:
			var chunk_plane = Plane(Vector3.UP, Vector3(0, draw_height, 0))
			draw_position = chunk_plane.intersects_ray(ray_origin, ray_dir)
			if draw_position:
				draw_area_hovered = true

		else:
			# Perform the raycast to check for intersection with a physics body (terrain)
			var space_state = camera.get_world_3d().direct_space_state
			var ray_length := 10000.0  # Adjust ray length as needed
			var end := ray_origin + ray_dir * ray_length
			var collision_mask = 1 # only terrain
			var query := PhysicsRayQueryParameters3D.create(ray_origin, end, collision_mask)
			var result = space_state.intersect_ray(query)
			if result:
				draw_position = result.position
				draw_area_hovered = true
				
		# ALT to clear the current draw pattern. don't clear while setting
		if Input.is_key_pressed(KEY_ALT) and not is_setting:
			current_draw_pattern.clear()

		# Check for terrain collision
		if draw_area_hovered:
			terrain_hovered = true
			var chunk_x: int = floor(draw_position.x / (terrain.dimensions.x * terrain.cell_size.x))
			var chunk_z: int = floor(draw_position.z / (terrain.dimensions.z * terrain.cell_size.y))
			var chunk_coords = Vector2i(chunk_x, chunk_z)

			is_chunk_plane_hovered = true
			current_hovered_chunk = chunk_coords

		if event is InputEventMouseButton and event.button_index == MouseButton.MOUSE_BUTTON_LEFT:
			if event.is_pressed() and draw_area_hovered:
				draw_height_set = false
				if Input.is_key_pressed(KEY_SHIFT):
					is_drawing = true
					brush_position = draw_position
				else:
					is_setting = true
					if not flatten:
						draw_height = draw_position.y
			elif event.is_released():
				if is_drawing:
					is_drawing = false
					if mode == TerrainToolMode.GROUND_TEXTURE:
						draw_pattern(terrain)
						current_draw_pattern.clear()
				if is_setting:
					is_setting = false
					draw_pattern(terrain)	
					current_draw_pattern.clear()
			gizmo_plugin.terrain_gizmo._redraw()
			return EditorPlugin.AFTER_GUI_INPUT_STOP
			
		# Adjust brush size
		if event is InputEventMouseButton and Input.is_key_pressed(KEY_SHIFT):
			var factor: float = event.factor if event.factor else 1
			if event.button_index == MOUSE_BUTTON_WHEEL_UP:
				brush_size += 0.5 * factor
				if brush_size > 50:
					brush_size = 50
				gizmo_plugin.terrain_gizmo._redraw()
				return EditorPlugin.AFTER_GUI_INPUT_STOP
			elif event.button_index == MOUSE_BUTTON_WHEEL_DOWN:
				brush_size -= 0.5 * factor
				if brush_size < 1:
					brush_size = 1
				gizmo_plugin.terrain_gizmo._redraw()
				return EditorPlugin.AFTER_GUI_INPUT_STOP
				
		if draw_area_hovered and event is InputEventMouseMotion:
			brush_position = draw_position
			
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
			if chunk:
				var removed_chunk = terrain.chunks[chunk_coords]
				get_undo_redo().create_action("remove chunk")
				get_undo_redo().add_do_method(terrain, "remove_chunk_from_tree", chunk_x, chunk_z)
				get_undo_redo().add_undo_method(terrain, "add_chunk", chunk_coords, removed_chunk)
				get_undo_redo().commit_action()
				return EditorPlugin.AFTER_GUI_INPUT_STOP
				
			# Add new chunk
			elif not chunk:
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

func draw_pattern(terrain: MarchingSquaresTerrain):
	var undo_redo := MarchingSquaresTerrainPlugin.instance.get_undo_redo()
	
	var pattern = current_draw_pattern.duplicate(true)
	
	# Ensure points on both sides of chunk borders are updated
	for draw_chunk_coords: Vector2i in current_draw_pattern.keys():
		var draw_chunk_dict = pattern[draw_chunk_coords]
		for draw_cell_coords: Vector2i in draw_chunk_dict:
			if mode == TerrainToolMode.GROUND_TEXTURE:
				draw_chunk_dict[draw_cell_coords] = ground_texture_color
			
			for cx in range(-1, 2):
				for cz in range(-1, 2):
					if (cx == 0 and cz == 0):
						continue
					
					var adjacent_chunk_coords = Vector2i(draw_chunk_coords.x + cx, draw_chunk_coords.y + cz)
					if not terrain.chunks.has(adjacent_chunk_coords):
						continue
						
					var x: int = draw_cell_coords.x
					var z: int = draw_cell_coords.y
					
					if cx == -1:
						if x == 0: x = terrain.dimensions.x-1
						else: continue
					elif cx == 1:
						if x == terrain.dimensions.x-1: x = 0
						else: continue
							
					if cz == -1:
						if z == 0: z = terrain.dimensions.z-1
						else: continue
					elif cz == 1:
						if z == terrain.dimensions.z-1: z = 0
						else: continue
						
					var adjacent_cell_coords := Vector2i(x, z)
						
					if not pattern.has(adjacent_chunk_coords):
						pattern[adjacent_chunk_coords] = {}
						
					pattern[adjacent_chunk_coords][adjacent_cell_coords] = draw_chunk_dict[draw_cell_coords]

	# In brush mode this stores the height BEFORE set
	# in grund texture mode this is the color BEFORE the draw
	var restore_pattern = {}
	for draw_chunk_coords: Vector2i in pattern.keys():
		var chunk: MarchingSquaresTerrainChunk = terrain.chunks[draw_chunk_coords]
		restore_pattern[draw_chunk_coords] = {}
		for draw_cell_coords: Vector2i in pattern[draw_chunk_coords]:
			if mode == TerrainToolMode.BRUSH:
				restore_pattern[draw_chunk_coords][draw_cell_coords] = chunk.get_height(draw_cell_coords)
			elif mode == TerrainToolMode.GROUND_TEXTURE:
				restore_pattern[draw_chunk_coords][draw_cell_coords] = chunk.get_color(draw_cell_coords)

	if mode == TerrainToolMode.GROUND_TEXTURE:
		undo_redo.create_action("terrain color draw")
		undo_redo.add_do_method(self, "draw_color_pattern_action", terrain, pattern)
		undo_redo.add_undo_method(self, "draw_color_pattern_action", terrain, restore_pattern)
		undo_redo.commit_action()
		
	elif flatten:
		undo_redo.create_action("terrain height draw flat")
		undo_redo.add_do_method(self, "draw_pattern_action", terrain, restore_pattern, DrawMode.SET_FLAT, brush_position.y)
		undo_redo.add_undo_method(self, "draw_pattern_action", terrain, restore_pattern, DrawMode.SET_FROM_PATTERN)
		undo_redo.commit_action()
	else:
		var y_delta = brush_position.y - draw_height
		undo_redo.create_action("terrain height draw")
		undo_redo.add_do_method(self, "draw_pattern_action", terrain, restore_pattern, DrawMode.RAISE_LOWER, y_delta)
		undo_redo.add_undo_method(self, "draw_pattern_action", terrain, restore_pattern, DrawMode.SET_FROM_PATTERN)
		undo_redo.commit_action()
	
# For each cell in pattern, raise/lower by y delta.
func draw_pattern_action(terrain: MarchingSquaresTerrain, pattern: Dictionary, draw_mode: DrawMode, y: float = 0):
	for draw_chunk_coords: Vector2i in pattern:
		var draw_chunk_dict = pattern[draw_chunk_coords]
		var chunk: MarchingSquaresTerrainChunk = terrain.chunks[draw_chunk_coords]
		for draw_cell_coords: Vector2i in draw_chunk_dict:
			if draw_mode == DrawMode.RAISE_LOWER:
				var cell_y = chunk.get_height(draw_cell_coords)
				chunk.draw_height(draw_cell_coords.x, draw_cell_coords.y, cell_y + y)
			elif draw_mode == DrawMode.SET_FLAT:
				chunk.draw_height(draw_cell_coords.x, draw_cell_coords.y, y)
			elif draw_mode == DrawMode.SET_FROM_PATTERN:
				y = draw_chunk_dict[draw_cell_coords]
				chunk.draw_height(draw_cell_coords.x, draw_cell_coords.y, y)	
		chunk.regenerate_mesh()
		
func draw_color_pattern_action(terrain: MarchingSquaresTerrain, pattern: Dictionary):
	for draw_chunk_coords: Vector2i in pattern:
		var draw_chunk_dict = pattern[draw_chunk_coords]
		var chunk: MarchingSquaresTerrainChunk = terrain.chunks[draw_chunk_coords]
		for draw_cell_coords: Vector2i in draw_chunk_dict:
			var color: Color = draw_chunk_dict[draw_cell_coords]
			chunk.draw_color(draw_cell_coords.x, draw_cell_coords.y, color)
		chunk.regenerate_mesh()

enum DrawMode {
	RAISE_LOWER = 0,
	SET_FLAT = 1,
	SET_FROM_PATTERN = 2
}

func on_tool_mode_changed(index: int):
	print("set mode to ", index)
	mode = index
	
	current_draw_pattern.clear()
	
	if mode == TerrainToolMode.BRUSH:
		tool_checkbox.visible = true
		tool_checkbox.set_pressed_no_signal(flatten)
	else:
		tool_checkbox.visible = false
		
	if mode == TerrainToolMode.GROUND_TEXTURE:
		color_picker.visible = true
	else:
		color_picker.visible = false

func on_tool_checkbox_changed(state: bool):
	if mode == TerrainToolMode.BRUSH:
		flatten = state
		
func on_color_picker_changed(color: Color):
	ground_texture_color = color
