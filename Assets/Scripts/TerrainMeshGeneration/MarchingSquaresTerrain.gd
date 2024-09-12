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

# possible change: have  aflat lciffs variable. if false, cliffs points will be from the heightmap.
# would probably need some kind of system to note the amount of adjacent points for each lower point. idk how i would even implement that

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
# Whether or not edges are connected
var ab: bool
var bd: bool
var cd: bool
var ac: bool
# amount of times to rotate placed vertices clockwise in order to translate to the current rotation case
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
			ab = abs(by-ay) < merge_threshold # top edge
			bd = abs(dy-by) < merge_threshold # left edge
			cd = abs(cy-dy) < merge_threshold # right edge
			ac = abs(ay-cy) < merge_threshold # bottom edge
			
			# If all four edges are connected, full floor here
			if ab and bd and cd and ac:
				add_full_floor()
				continue

			# edges going clockwise around the cell
			var cell_edges = [ab, bd, cd, ac]
			# point heights going clockwise around the cell
			var point_heights = [ay, by, dy, cy]
			
			# Sort the points by ascending height, storing the point indexes in height here
			var point_heights_relative = [0, 1, 2, 3]
			var sort = func(p1, p2):
				return point_heights[p1] < point_heights[p2]
			point_heights_relative.sort_custom(sort)
			
			# Starting from the lowest corner, build the tile up
			for i in range(4):
				# Use the rotation of the corner - the amount of counter-clockwise rotations for it to become the top-left corner, which is just its index in the point lists.
				r = point_heights_relative[i]
				
				ab = cell_edges[r]
				bd = cell_edges[(r+1)%4]
				cd = cell_edges[(r+2)%4]
				ac = cell_edges[(r+3)%4]
				
				ay = point_heights[r]
				by = point_heights[(r+1)%4]
				dy = point_heights[(r+2)%4]
				cy = point_heights[(r+3)%4]
				
				# If AB and AC are connected and BD and CD are not,
				# and A is higher than D,
				# then D is the edge of a corner.
				# Put a full floor here
				if ab and ac and not bd and not cd and ay > dy:
					# temporarily set dy to the the avg. between BY and CY.
					dy = (by+cy)/2
					add_full_floor()
					continue
					
				# If A is higher than D (opposite corner)
				# add a corner around A.
				# Do not add if A is connected to B or C.
				if ay > dy and ay > by and ay > cy and not (ab or ac):
					# if bd and cd are not connected, use the average of B and C height.
					if not bd and not cd:
						dy = (by+cy)/2
					add_corner(x, z)
					continue
				
				# If opposite corners are within merge distance,
				# this is inside a diagonal, but all corners will already be covered.
				# If they are not within distance, the corner case will instead place a corner between them.
				if abs(dy-ay) < merge_threshold and not (ab or bd or cd or ac):
					# ay and dy corners will be the avg of the other corners
					ay = (by+cy)/2
					dy = ay
					add_full_floor()
					continue

				# If A and B are higher than C and D,
				# add an edge around AB.
				# B may be higher than A. or C may be higher than D. (This means a corner will be on top of the edge).
				# Do not add if AC or BD are connected
				
				if ay > cy and by > dy and not (ac or bd):
					# If the edge's corners are not connected
					# set the height of the higher corner to the lower corner's
					if not ab:
						ay = min(ay, by)
						by = ay
					add_edge(x, z)
					continue
				
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
func add_full_floor():
	# ABC tri
	add_point(0, ay, 0)
	add_point(1, by, 0)
	add_point(0, cy, 1)
	# DCB tri
	add_point(1, dy, 1)
	add_point(0, cy, 1)
	add_point(1, by, 0)
	
# Add a corner where A is higher than B,C,D (upper corner cliff surrounds A).
func add_corner(x: int, z: int):
	# ABC tri - use height of A
	add_point(0, ay, 0)
	add_point(1, ay, 0)
	add_point(0, ay, 1)

	# TODO: only place wall if the opposite corner is not higher (that wall would be invisible)
	#C - Cupper - B tri
	add_point(0, cy, 1)
	add_point(0, ay, 1)
	add_point(1, by, 0)
	
	# Bupper - B - Cupper tri
	add_point(1, ay, 0)
	add_point(1, by, 0)
	add_point(0, ay, 1)

	# DCB
	# Only make the floor for this cell if A (current corner out of the 4) is the highest corner. 
	# This is the easieest way to make sure only one corner places the floor tri for its cell.
	if ay > by and ay > cy and ay > dy:
		# only use the corner's actual height if it is connected to D, otherwise use D's height
		add_point(1, dy, 1)
		add_point(0, cy if cd else dy, 1)
		add_point(1, by if bd else dy, 0)
	
## Add an inner corner where A is lower than B,C,D (corner surrounds D).
#func add_inner_corner(x: int, z: int):
	## Make sure the base of the cliff is always flat, so use the same height as the upper corner.
	## ABC tri. use heightmap heights
	#add_point(0, ay, 0)
	#add_point(1, by, 0)
	#add_point(0, cy, 1)
#
	## C - Cupper - B tri
	#add_point(0, cy, 1)
	#add_point(0, dy, 1)
	#add_point(1, by, 0)
	## BUpper - B - CUpper tri
	#add_point(1, dy, 0)
	#add_point(1, by, 0)
	#add_point(0, dy, 1)
	#
	## DCB - use flat height of D corner
	#add_point(1, dy, 1)
	#add_point(0, dy, 1)
	#add_point(1, dy, 0)
	
# Add an edge, where AB and CD are connected, but AC and BD are disconnected.
# Used in the case where A and B are both higher than C and D.
# Because a corner may be aabove an edge, pass in its own ay and by.
func add_edge(x: int, z: int):
	# AB is higher, use only heights of AB edge for upper floor
	# ABC tri
	add_point(0, ay, 0)
	add_point(1, by, 0)
	add_point(0, ay, 1)
	# DCB tri
	add_point(1, by, 1)
	add_point(0, ay, 1)
	add_point(1, by, 0)
	
	# Walls - the lower points will connect to the floor of the adjacent lower tile
	# C - D - Clower tri
	add_point(0, ay, 1)
	add_point(1, by, 1)
	add_point(0, cy, 1)
	
	# Dlower - Clower - D tri
	add_point(1, dy, 1)
	add_point(0, cy, 1)
	add_point(1, by, 1)
	
	
	
	
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
