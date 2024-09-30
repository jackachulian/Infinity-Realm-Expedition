# my_custom_gizmo_plugin.gd
class_name MarchingSquaresTerrainGizmoPlugin
extends EditorNode3DGizmoPlugin
	
func _init():
	create_material("main", Color(1,0,1))
	create_handle_material("handles")
	
func _create_gizmo(node):
	if node is MarchingSquaresTerrain:
		return MarchingSquaresTerrainGizmo.new()
	else:
		return null
