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

	var node3d = gizmo.get_node_3d()
	
	print("drawing gizmo for ", node3d)

	var lines = PackedVector3Array()

	lines.push_back(Vector3(0, 1, 0))
	lines.push_back(Vector3(0, 2, 0))

	var handles = PackedVector3Array()

	handles.push_back(Vector3(0, 1, 0))
	handles.push_back(Vector3(0, 2, 0))

	gizmo.add_lines(lines, get_material("main", gizmo), false)
	gizmo.add_handles(handles, get_material("handles", gizmo), [])
