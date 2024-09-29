@tool
class_name MarchingSquaresTerrainPlugin
extends EditorPlugin

var gizmo_plugin = MarchingSquaresTerrainGizmo.new()

# This function gets called when the plugin is activated.
func _enter_tree():
	print("terrain tool entered tree")
	# Add a button to the editor's toolbar
	add_tool_menu_item("Ray Click Tool", _on_ray_click_tool_pressed)
	
	add_custom_type("MarchingSquaresTerrain", "MeshInstance3D", preload("MarchingSquaresTerrain.gd"), preload("res://icon.svg"))
	
	add_node_3d_gizmo_plugin(gizmo_plugin)

# This function gets called when the plugin is deactivated.
func _exit_tree():
	# Remove the button from the editor's toolbar
	remove_tool_menu_item("Ray Click Tool")
	
	remove_custom_type("MarchingSquaresTerrain")
	
	remove_node_3d_gizmo_plugin(gizmo_plugin)

# This function is called when the button is clicked in the toolbar
func _on_ray_click_tool_pressed():
	print("Click anywhere in the 3D viewport to get the intersection point!")

# This function handles the mouse click in the 3D viewport
func _input(event):
	if event is InputEventMouseButton and event.pressed and event.button_index == MouseButton.MOUSE_BUTTON_LEFT:
		if get_main_screen() != "3D":
			return
		
		# Check that the 3d tab is active
		var editor_viewport = EditorInterface.get_editor_viewport_3d()
		
		# Get the mouse position in the viewport
		var mouse_pos = editor_viewport.get_mouse_position()
		
		var viewport_rect = editor_viewport.get_visible_rect()
		if not viewport_rect.has_point(mouse_pos):
			return

		# Get the ray origin and direction from the camera
		var camera = editor_viewport.get_camera_3d()
		if camera:
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
				print("Intersected with ", body.get_parent().name, " at:", intersection_pos)
			else:
				print("No intersection detected.")

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
