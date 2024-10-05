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
	
func add_new_chunk(chunk_x: int, chunk_z: int):
	var chunk_coords := Vector2i(chunk_x, chunk_z)
	var new_chunk := MarchingSquaresTerrainChunk.new()
	new_chunk.name = "Chunk "+str(chunk_coords)
	add_chunk(chunk_coords, new_chunk, false)
	
	var chunk_left: MarchingSquaresTerrainChunk = chunks.get(Vector2i(chunk_x-1, chunk_z))
	if chunk_left:
		print("copying chunk left adjacent points")
		for z in range(0, dimensions.z):
			new_chunk.height_map[z][0] = chunk_left.height_map[z][dimensions.x - 1]
			
	var chunk_right: MarchingSquaresTerrainChunk = chunks.get(Vector2i(chunk_x+1, chunk_z))
	if chunk_right:
		print("copying chunk right adjacent points")
		for z in range(0, dimensions.z):
			chunk_right.height_map[z][dimensions.x - 1] = chunk_right.height_map[z][0]
			
	var chunk_up: MarchingSquaresTerrainChunk = chunks.get(Vector2i(chunk_x, chunk_z-1))
	if chunk_up:
		print("copying chunk up adjacent points")
		for x in range(0, dimensions.x):
			new_chunk.height_map[0][x] = chunk_up.height_map[dimensions.z - 1][x]
			
	var chunk_down: MarchingSquaresTerrainChunk = chunks.get(Vector2i(chunk_x, chunk_z+1))
	if chunk_down:
		print("copying chunk down adjacent points")
		for x in range(0, dimensions.x):
			new_chunk.height_map[dimensions.z - 1][x] = chunk_down.height_map[0][x]
			
	new_chunk.regenerate_mesh()

func remove_chunk(x: int, z: int):
	var chunk_coords := Vector2i(x, z)
	var chunk: MarchingSquaresTerrainChunk = chunks[chunk_coords]
	chunks.erase(chunk)
	chunk.free()
	
# remove a chunk but still keep it in memory (so that undo can restore it)
func remove_chunk_from_tree(x: int, z: int):
	var chunk_coords := Vector2i(x, z)
	var chunk: MarchingSquaresTerrainChunk = chunks[chunk_coords]
	chunks.erase(chunk)
	remove_child(chunk)
	chunk.owner = null
	
func add_chunk(coords: Vector2i, chunk: MarchingSquaresTerrainChunk, regenerate_mesh: bool = true):
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
	chunk.initialize_terrain(regenerate_mesh)
	print("added new chunk to terrain system at ", chunk)
