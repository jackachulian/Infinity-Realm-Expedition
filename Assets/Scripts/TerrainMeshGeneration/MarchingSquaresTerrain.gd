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

@export var random_noise: float = 0.1

@export var seed: int = 1

var rng := RandomNumberGenerator.new()

var st: SurfaceTool

func _ready() -> void:
	load_height_map()
	generate_mesh()
	
# cell coordinates currently being evaluated
var cell_x: int
var cell_z: int
	
# current amount of counter-clockwise rotations performed on original heightmap to reach current state
var r: int
	
# heights of the 4 corners ini current rotation
var ay: float
var by: float
var cy: float
var dy: float
# Edge connected state	
var ab: bool
var ac: bool
var bd: bool
var cd: bool
# Corner connected state
var ad: bool
var bc: bool
		
func generate_mesh():
	st = SurfaceTool.new()

	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	
	# will produce sharp normals
	st.set_smooth_group(-1)
			
	for z in range(dimensions.z - 1):
		cell_z = z
		for x in range(dimensions.x - 1):
			cell_x = x
			r = 0
			
			# Get heights of 4 surrounding corners
			ay = height_map[z][x] # top-left
			by = height_map[z][x+1] # top-right
			cy = height_map[z+1][x] # bottom-left
			dy = height_map[z+1][x+1] # bottom-right
			
			# Track which edges shold be connected and not have a wall bewteen them.
			ab = abs(ay-by) < merge_threshold # top edge
			ac = abs(ay-cy) < merge_threshold # bottom edge
			bd = abs(by-dy) < merge_threshold # right edge
			cd = abs(cy-dy) < merge_threshold # bottom edge
			
			# If all edges are connected, put a full floor here.
			if ab and bd and cd and ac:
				st.set_color(Color(0.5, 0.5, 0.5))
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
			
			# Keeps track of which points on the midpoint od edges
			# already have walls against them.
			# [ ab, bd, cd, ac ]
			var edge_walls = [ false, false, false, false ]
			
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
				
				# Shortcuts to see if opposite corners are connected through either edge loop
				ad = abs(ay-dy) < merge_threshold
				bc = abs(by-cy) < merge_threshold
				
				var inner_corner = (ay < by and not ab) and (ay < cy and not ac)

				var inner_corner_base_bd_edge = not (ab or ac) and false
				
				var inner_corner_base_cd_edge = not (ab or ac) and false
				
				var inner_corner_base = inner_corner_base_bd_edge or inner_corner_base_cd_edge

				if inner_corner_base:
					add_inner_corner_base()
					continue
			
				if inner_corner:
					st.set_color(Color(0.1, 0.1, 0.8))
					add_inner_corner()
				
				# Outer corner
				if (ay > by and not ab) and (ay > cy and not ac):
					st.set_color(Color(0.8, 0.1, 0.1))
					add_outer_corner()
				
				# Edge
				if ay > cy and ay > dy and by > cy and by > dy and not (ac or bd or ad or bc):
					st.set_color(Color(0.1, 0.8, 0.1))
					add_edge()
					
				# Edge base
				if ab and bd and cd and not ac:
					st.set_color(Color(0.1, 0.75, 0.75))
					add_edge_base()
					break
				
	st.generate_normals()
	
	mesh = st.commit()
	print("generated mesh")

# Adds a point. Coordinates are relative to the top-left corner (not mesh origin relative).
func add_point(x: float, y: float, z: float):
	for i in range(r):
		var temp = x
		x = 1 - z
		z = temp
	
	st.set_uv(Vector2(x, z))
	st.add_vertex(Vector3(cell_x+x, y, cell_z+z))

func add_full_floor():
	# ABC tri
	add_point(0, ay, 0)
	add_point(1, by, 0)
	add_point(0, cy, 1)
	# DCB tri
	add_point(1, dy, 1)
	add_point(0, cy, 1)
	add_point(1, by, 0)

# Add an outer corner, where A is the raised corner.
func add_outer_corner():
	# Upper floor - use a for all heights
	add_point(0, ay, 0)
	add_point(0.5, ay, 0)
	add_point(0, ay, 0.5)
	
	# Walls - bases will use B and C height, while cliff top will use A height.
	add_point(0, cy, 0.5)
	add_point(0, ay, 0.5)
	add_point(0.5, by, 0)
	
	add_point(0.5, ay, 0)
	add_point(0.5, by, 0)
	add_point(0, ay, 0.5)
	
	# Only place a flat floor below if BD and CD are connected
	if bd and cd:
		add_point(1, dy, 1)
		add_point(0, cy, 1)
		add_point(0, cy, 0.5)
		
		add_point(1, dy, 1)
		add_point(0, cy, 0.5)
		add_point(0.5, by, 0)
		
		add_point(1, dy, 1)
		add_point(0.5, by, 0)
		add_point(1, by, 0)	
	
# Add an edge, where AB is the raised edge.
func add_edge():
	# if A and B are not connected, use the lower of the two heights
	var edge_ay = ay if ab else min(ay,by)
	var edge_by = by if ab else min(ay,by)
	
	# Upper floor - use A and B for heights
	add_point(0, edge_ay, 0)
	add_point(1, edge_by, 0)
	add_point(0, edge_ay, 0.5)
	
	add_point(1, edge_by, 0.5)
	add_point(0, edge_ay, 0.5)
	add_point(1, edge_by, 0)
	
	# Wall from left to right edge
	add_point(0, cy, 0.5)
	add_point(0, edge_ay, 0.5)
	add_point(1, dy, 0.5)
	
	add_point(1, edge_by, 0.5)
	add_point(1, dy, 0.5)
	add_point(0, edge_ay, 0.5)
	
	# Lower floor - use C and D for height
	# Only place a flar floor below if CD is connected
	if cd:
		add_point(0, cy, 0.5)
		add_point(1, dy, 0.5)
		add_point(0, cy, 1)
		
		add_point(1, dy, 1)
		add_point(0, cy, 1)
		add_point(1, dy, 0.5)
		
# Creates the base of edge. In this case, only AC or BD is disconnected and all other corners are connected.
func add_edge_base():
	
	# Only merge the ay/cy edge if AC edge is connected
	var edge_ay = (ay+cy)/2 if ac else ay
	var edge_cy = (ay+cy)/2 if ac else cy
	# Same with BD
	var edge_by = (by+dy)/2 if bd else by
	var edge_dy = (by+dy)/2 if bd else dy
	
	# Upper floor - use A and B edge for heights
	add_point(0, ay, 0)
	add_point(1, by, 0)
	add_point(0, edge_ay, 0.5)
	
	add_point(1, edge_by, 0.5)
	add_point(0, edge_ay, 0.5)
	add_point(1, by, 0)
	
	# Wall from left to right edge
	if (edge_ay != edge_cy):
		add_point(0, edge_cy, 0.5)
		add_point(0, edge_ay, 0.5)
		add_point(1, edge_dy, 0.5)
	
	if (edge_by != edge_dy):
		add_point(1, edge_by, 0.5)
		add_point(1, edge_dy, 0.5)
		add_point(0, edge_ay, 0.5)
	
	# Lower floor - use C and D edge
	add_point(0, edge_cy, 0.5)
	add_point(1, edge_dy, 0.5)
	add_point(1, dy, 1)
	
	add_point(0, cy, 1)
	add_point(0, edge_cy, 0.5)
	add_point(1, dy, 1)
	
# Add an inner corner, where A is the lowered corner.
func add_inner_corner():
	# Lower floor with height of point A
	add_point(0, ay, 0)
	add_point(0.5, ay, 0)
	add_point(0, ay, 0.5)

	var inner_by = by
	var inner_cy = cy
	
	# If fully flat on top, add full floor for rest of tile 
	if bd and cd:
		add_point(1, dy, 1)
		add_point(0, cy, 1)
		add_point(0, cy, 0.5)
		
		add_point(1, dy, 1)
		add_point(0, cy, 0.5)
		add_point(0.5, by, 0)
		
		add_point(1, dy, 1)
		add_point(0.5, by, 0)
		add_point(1, by, 0)
		
	# if C and D are both higher than B, and B does not connect the corners, there's an edge above, place floors that will connect to the CD edge
	elif cy > by and dy > by and not bc and not bd:
		# use height of B corner
		add_point(1, by, 0.5)
		add_point(0, by, 0.5)
		add_point(0.5, by, 0)
		
		add_point(1, by, 0.5)
		add_point(0.5, by, 0)
		add_point(1, by, 0)
		
		inner_by = by
		inner_cy = by
		
	# if B and D are both higher than C, and C does not connect the corners, there's an edge above, place floors that will connect to the BD edge
	elif by > cy and dy > cy and not bc and not cd: 
		# use height of C corner
		add_point(0.5, cy, 1)
		add_point(0, cy, 1)
		add_point(0, cy, 0.5)
		
		add_point(0.5, cy, 1)
		add_point(0, cy, 0.5)
		add_point(0.5, cy, 0)
		
		inner_by = cy
		inner_cy = cy
		
	# otherwise, if all corners are disconnected, add a diagonal floor
	# in the future, may want to place some kind of cliff between them if distance is too high. not sure yet
	elif not (ab or ac or bd or cd):
		# if B and C are not close enough,
		# put a cliff here.
		add_point(1, by, 0)
		add_point(1, by, 0.5)
		add_point(0.5, by, 0)
		
		add_point(0.5, by, 0)
		add_point(1, by, 0.5)
		add_point(0.5, cy, 1)
		
		add_point(0.5, cy, 1)
		add_point(0, cy, 0.5)
		add_point(0.5, by, 0)
		
		add_point(0, cy, 1)
		add_point(0, cy, 0.5)
		add_point(0.5, cy, 1)
		
	# if not, there is also an inner corner base here - handled in another branch from the main generate loop
	elif (cd or bd):
		pass
		
	# Now, add a wall with the appropriate height
	add_point(0, ay, 0.5)
	add_point(0.5, ay, 0)
	add_point(0, inner_cy, 0.5)
	
	add_point(0.5, inner_by, 0)
	add_point(0, inner_cy, 0.5)
	add_point(0.5, ay, 0)

func add_inner_corner_base():
	# Lower floor with height of point A
	add_point(0, ay, 0)
	add_point(0.5, ay, 0)
	add_point(0, ay, 0.5)
	
	# wall on inner corner side
	add_point(0, ay, 0.5)
	add_point(0.5, ay, 0)
	add_point(0, cy, 0.5)
	
	add_point(0.5, by, 0)
	add_point(0, cy, 0.5)
	add_point(0.5, ay, 0)
	
	# fill in the corner at D, then the open corner at the bottom of the base corner, and then the wall that leads up to it, then a wall covering the open side
	if cd:
		st.set_color(Color(0.75, 0.1, 0.75))
		var cdy = (cy+dy)/2
		# corner floors
		add_point(1, dy, 1)
		add_point(0.5, cdy, 1)
		add_point(1, dy, 0.5)
	
		add_point(0, cy, 1)
		add_point(0, cy, 0.5)
		add_point(0.5, cdy, 1)
		
		add_point(1, by, 0)
		add_point(1, by, 0.5)
		add_point(0.5, by, 0)
		
		## corner base floors
		#add_point(0, cy, 0.5)
		#add_point(0.5, by, 0)
		#add_point(0.5, cdy, 1)
		#
		#add_point(1, by, 0.5)
		#add_point(0.5, cdy, 1)
		#add_point(0.5, by, 0)
		#
		## wall
		#add_point(0.5, cdy, 1)
		#add_point(1, by, 0.5)
		#add_point(1, dy, 0.5)
	elif bd:
		st.set_color(Color(0.75, 0.75, 0.1))
		var bdy = (by+dy)/2
		# corner floors
		add_point(1, dy, 1)
		add_point(0.5, dy, 1)
		add_point(1, bdy, 0.5)
	
		add_point(0, cy, 1)
		add_point(0, cy, 0.5)
		add_point(0.5, cy, 1)
		
		add_point(1, by, 0)
		add_point(1, bdy, 0.5)
		add_point(0.5, by, 0)

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
	
	rng.seed = seed
	rng.state = 0
	
	for z in range(min(dimensions.z, image.get_height()+1) - 1):
		for x in range(min(dimensions.x, image.get_width()+1) - 1):
			var height = image.get_pixel(x, z).r * dimensions.y
			height += rng.randf_range(-random_noise, random_noise)
			height = max(0, height)
			
			height_map[z][x] = height
