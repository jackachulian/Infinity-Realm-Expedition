@tool
extends EditorPlugin


func _enter_tree() -> void:
	add_custom_type("MarchingSquaresTerrain", "MeshInstance3D", preload("MarchingSquaresTerrainMesh.gd"), preload("res://icon.svg"))


func _exit_tree() -> void:
	# Clean-up of the plugin goes here.
	pass
