# my_custom_gizmo_plugin.gd
class_name MarchingSquaresTerrainGizmoPlugin
extends EditorNode3DGizmoPlugin
	
func _init():
	#create_material("filledchunk", Color(0,1,1))
	create_material("brush", Color(1, 1, 1), false, true)
	create_material("brush_pattern", Color(0.7, 0.7, 0.7), false, true)
	create_material("removechunk", Color(1,0,0), false, true)
	create_material("addchunk", Color(0,1,0), false, true)
	create_handle_material("handles")
	
var chunk_gizmo: MarchingSquaresTerrainChunkGizmo
var terrain_gizmo: MarchingSquaresTerrainGizmo
	
func _create_gizmo(node):
	if node is MarchingSquaresTerrainChunk:
		chunk_gizmo = MarchingSquaresTerrainChunkGizmo.new()
		return chunk_gizmo
	elif node is MarchingSquaresTerrain:
		terrain_gizmo = MarchingSquaresTerrainGizmo.new()
		return terrain_gizmo
	else:
		return null

func _get_gizmo_name() -> String:
	return "Marching Squares Terrain"
