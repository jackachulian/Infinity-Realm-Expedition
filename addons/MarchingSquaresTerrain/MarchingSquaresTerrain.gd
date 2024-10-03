@tool
class_name MarchingSquaresTerrain
# needs to be kept as a Node3D so that the 3d gizmo works. no 3d functionality is otherwise used, it is delegated to the chunks
extends Node3D

# Total amount of height values in X and Z direction, and total height range
@export var dimensions: Vector3i = Vector3i(33, 32, 33)
# XZ Unit size of each cell
@export var cell_size: Vector2 = Vector2(2, 2)

# Material assigned to the ground and walls.
@export var terrain_material: Material

# The max height distance between points before a wall is created between them
@export var merge_threshold: float = 0.6

# If above 0, round height values to this nearest interval.
@export var height_banding: float = 0.25

# used to generate smooth initial heights for more natrual looking terrain. if null, initial terrain will be flat
@export var noise: Noise

var chunks: Dictionary = {}

func _enter_tree() -> void:
	for chunk in get_children():
		if chunk is MarchingSquaresTerrainChunk:
			chunks[chunk.chunk_coords] = chunk

func _ready() -> void:
	if not Engine.is_editor_hint():
		return
		
	chunks.clear()
	for chunk in get_children():
		if chunk is MarchingSquaresTerrainChunk:
			chunks[chunk.chunk_coords] = chunk
			chunk.initialize_terrain()

func has_chunk(x: int, z: int) -> bool:
	return chunks.has(Vector2i(x, z))
	
func add_new_chunk(x: int, z: int):
	var chunk_coords := Vector2i(x, z)
	var new_chunk := MarchingSquaresTerrainChunk.new()
	new_chunk.name = "Chunk "+str(chunk_coords)
	add_chunk(chunk_coords, new_chunk)
	

func remove_chunk(x: int, z: int):
	var chunk_coords := Vector2i(x, z)
	var chunk: MarchingSquaresTerrainChunk = chunks[chunk_coords]
	chunks.erase(chunk)
	chunk.free()
	
func add_chunk(coords: Vector2i, chunk: MarchingSquaresTerrainChunk):
	chunks[coords] = chunk
	chunk.terrain_system = self
	chunk.chunk_coords = coords
	chunk.global_position = Vector3(
		coords.x * ((dimensions.x - 1) * cell_size.x),
		0,
		coords.y * ((dimensions.z - 1) * cell_size.y)
	)
	
	add_child(chunk)
	chunk.owner = EditorInterface.get_edited_scene_root()
	chunk.initialize_terrain()
	print("added new chunk to terrain system at ", chunk)
