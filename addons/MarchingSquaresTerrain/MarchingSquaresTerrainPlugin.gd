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
	if not selected:
		return EditorPlugin.AFTER_GUI_INPUT_PASS
	
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

		var origin := camera.project_ray_origin(mouse_pos)
		var direction := camera.project_ray_normal(mouse_pos)

		# Perform the raycast to check for intersection with a physics body
		var space_state = camera.get_world_3d().direct_space_state
		var ray_length := 10000.0  # Adjust ray length as needed
		var end := origin + direction * ray_length
		var query := PhysicsRayQueryParameters3D.create(origin, end)
		var result = space_state.intersect_ray(query)

		if result:
			var intersection_pos = result.position
			var body: PhysicsBody3D = result.collider;
			print("Intersected with ", body.name, " at:", intersection_pos)
			return EditorPlugin.AFTER_GUI_INPUT_STOP
		else:
			print("No intersection detected.")
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
