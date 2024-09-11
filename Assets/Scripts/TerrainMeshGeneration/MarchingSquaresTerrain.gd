@tool
class_name MarchingSquaresTerrain
extends MeshInstance3D

@export var dimensions: Vector3i = Vector3i(10, 1, 10):
	set(new_dimensions):
		dimensions = new_dimensions
		load_height_map()
		generate_mesh()
		
var height_map: Array

@export var height_map_image: Texture2D

# The max height distance between points before a wall is created between them
@export var merge_threshold: float = 0.06

var st: SurfaceTool

func _ready() -> void:
	load_height_map()
	generate_mesh()
	
# Class-local variables used in tri generating methods without having to pass stuff everywhere
# XZ coordinate of square cell currently being built
var cell_x: int
var cell_z: int
# heights of the 4 corners
var ay: float
var by: float
var cy: float
var dy: float
# amount of times to rotate placed vertices counter-clockwise
var r: int = 0
			
func generate_mesh():
	st = SurfaceTool.new()

	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	
	# will produce sharp normals
	st.set_smooth_group(-1)
			
	# Loop over all xz coordinates
	for z in range(dimensions.z - 1):
		cell_z = z
		for x in range(dimensions.x - 1):
			cell_x = x
			
			# Get heights of 4 surrounding corners
			ay = height_map[z][x] # top-left
			by = height_map[z][x+1] # top-right
			cy = height_map[z+1][x] # bottom-left
			dy = height_map[z+1][x+1] # bottom-right
			
			# Track which edges shold be connected and not have a wall bewteen them.
			var ab = abs(by-ay) < merge_threshold # top edge
			var bd = abs(dy-by) < merge_threshold # left edge
			var dc = abs(cy-dy) < merge_threshold # right edge
			var ca = abs(ay-cy) < merge_threshold # bottom edge
			
			# Marching square case should be used if the corner is part of either connecting wall edge
			var a = ab or ca
			var b = bd or ab
			var c = ca or dc
			var d = dc or bd
			
			# If all four edges are connected, add a full floor here
			if ab and bd and dc and ca:
				add_full_floor()
				
			# edges going clockwise around the cell
			var cell_edges = [ab, bd, dc, ca]
			# point heights going clockwise around the cell
			var point_heights = [ay, by, dy, cy]
			# point has-edge states going clockwise around the cell
			var points = [a, b, d, c]
			
			# Sort the points by ascending height, storing the point indexes in height here
			var point_heights_relative = [0, 1, 2, 3]
			var sort = func(p1, p2):
				return point_heights[p1] < point_heights[p2]
			point_heights_relative.sort_custom(sort)
			
			
			
			# Get the height of the corner at the given index. For top-left case it is [A, B, D, C]
			# 0 = top left, 1 = top right, 2 = bottom right, 3 = bottom left
			
			# The edge of the wall below the current height.
			# If null / zero, there is no wall below (current height is the bottom).
			var edge_below: Vector4
			
			# Starting from the lowest corner, build the tile up
			for i in range(4):
				# Use the rotation of the corner - the amount of counter-clockwise rotations for it to become the top-left corner, which is just its index in the point lists.
				r = point_heights_relative[i]
				
				ay = point_heights[r]
				by = point_heights[(r+1)%4]
				dy = point_heights[(r+2)%4]
				cy = point_heights[(r+3)%4]
				
				# If current point shares no edges, add a corner wall here
				if not points[r]:
					if edge_below:
						pass
					else:
						var edge = add_outer_corner_floor(x, z)
					
				
					
				# If current point shares the edge clockwise to the right and not the edge clockwise to the left,
				# add a horizontal wall
				#if cell_edges[r] and not cell_edges[(r+3)%4]:
					#var edges = add_horizontal_edge_floor(x, z)
					#add_wall(edges, ay, cy, by, dy)
					
				#If adjcaent edges exist but not the other two non-adjacent,
				# put down
					
			
	
	st.generate_normals()
	
	mesh = st.commit()
	print("generated mesh")

# Adds a point. Coordinates are relative to the top-left corner (not mesh origin relative).
func add_point(x: float, y: float, z: float):
	var temp
	for i in range(r):
		temp = x
		x = 1 - z
		z = temp
	
	st.set_uv(Vector2(x, z))
	st.add_vertex(Vector3(cell_x+x, y, cell_z+z))

# == FLOORS ==
# All floors should return the left and right x and z coordinates (packed into a vector4 for convenience).
# if there is a rotation parameter, implementation is for corner on A and rotated to fit the other corners
# floor will be rotated [rotation] times.

# full floor (used in case 0, case 15 will not show up because it collapses to case 0)
func add_full_floor() -> Vector4:
	# ABC tri
	add_point(0, ay, 0)
	add_point(1, by, 0)
	add_point(0, cy, 1)
	# DCB tri
	add_point(1, dy, 1)
	add_point(0, cy, 1)
	add_point(1, by, 0)
	# floor has no open edges
	return Vector4.ZERO
	
# outer corner floor
# used for outer corner raised floors (case 1, 2, 4, 8)
# also used below inner corner floors (case 7, 11, 13, 14)
# Case where A does not share an edge with B or C, eigher above or below
# "outer" for these purposes means that the corner surrounds A
func add_outer_corner_floor(x: int, z: int) -> Vector4:
	# all points use A's height
	
	# A-T-L tri
	add_point(0, ay, 0)
	# point T as on middle of top edge, halfway bewteen A and B
	add_point(0.5, ay, 0)
	# point L in middle of left edge
	add_point(0, ay, 0.5)
	
	# return L as left edge, T as right edge
	return Vector4(0, 0.5, 0.5, 0)
	
# edge floor
# used for when one edge is disconnected from the other
# edge splits AB and CD.
func add_horizontal_edge_floor(x: int, z: int):
	# A-B-L tri
	add_point(0, ay, 0)
	add_point(1, by, 0)
	add_point(0, ay, 0.5)
	# R-L-B tri
	add_point(1, by, 0.5)
	add_point(0, ay, 0.5)
	add_point(1, by, 0)
	
	return Vector4(0, 0.5, 1, 0.5)
	
# same as horizontal edge, but instead AC and BD are seperated.
func add_vertical_edge_floor(x: int, z: int):
	add_point(0, ay, 0)
	add_point(0.5, ay, 0)
	add_point(0, cy, 1)
	
	add_point(0.5, cy, 1)
	add_point(0, cy, 1)
	add_point(0.5, ay, 0)
	
	return Vector4(0.5, 1, 0.5, 0)
	
# Wall
# Used to connect a floor to the floor above it using a passed ledt edge + right edge Vector4
func add_wall(edges: Vector4, left_height: float, left_above_height: float, right_height: float, right_above_height: float):
	# Make a wall bewteen the passed edges witht he given heights
	# Left edge tri (covers bottom-left of wall)
	add_point(edges.x, left_height, edges.y)
	add_point(edges.z, right_height, edges.w)
	add_point(edges.x, left_above_height, edges.y)
	# Right edge tri (covers top-right of wall)
	add_point(edges.z, right_above_height, edges.w)
	add_point(edges.x, left_above_height, edges.y)
	add_point(edges.z, right_height, edges.w)
	
func load_height_map():	
	height_map = []
	height_map.resize(dimensions.z)
	
	for z in range(dimensions.z):
		height_map[z] = []
		height_map[z].resize(dimensions.x)
		for x in range(dimensions.x):
			height_map[z][x] = 0.0
		
	if not height_map_image:
		return
	
	var image = height_map_image.get_image()
	
	for z in range(min(dimensions.z, image.get_height()+1) - 1):
		for x in range(min(dimensions.x, image.get_width()+1) - 1):
			var height = round(image.get_pixel(x, z).r * dimensions.y)
			
			height_map[z][x] = height
