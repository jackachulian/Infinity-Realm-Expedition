# my_custom_gizmo_plugin.gd
class_name MarchingSquaresTerrainGizmoPlugin
extends EditorNode3DGizmoPlugin
	
func _init():
	create_material("filledchunk", Color(0,1,1))
	create_material("newchunk", Color(1,0,1))
	create_material("newchunkhover", Color(0,1,0))
	create_material("brush", Color(1,1,1))
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
