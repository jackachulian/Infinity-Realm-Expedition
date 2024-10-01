@tool
class_name MarchingSquaresTerrain
extends Node3D

var chunks: Dictionary = {}

@export var dimensions: Vector3i = Vector3i(32, 32, 32)

@export var cell_size: Vector2 = Vector2(2, 2)

func _enter_tree() -> void:
	for chunk in get_children():
		print(chunk.name)
		if chunk is MarchingSquaresTerrainChunk:
			print("is chunk")
			chunks[chunk.chunk_coords] = chunk
