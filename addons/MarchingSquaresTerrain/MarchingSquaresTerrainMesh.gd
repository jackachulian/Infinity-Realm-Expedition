@tool
class_name MarchingSquaresTerrain
extends MeshInstance3D

@export var dimensions: Vector3i = Vector3i(10, 1, 10):
	set(new_dimensions):
		if Engine.is_editor_hint():
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

var floor: SurfaceTool

var wall: SurfaceTool
	
# cell coordinates currently being evaluated
var cell_x: int
var cell_z: int
	
# current amount of counter-clockwise rotations performed on original heightmap to reach current state
var r: int

var cell_edges: Array
var point_heights: Array
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
		
func generate_mesh():
	floor = SurfaceTool.new()
	floor.begin(Mesh.PRIMITIVE_TRIANGLES)
	floor.set_smooth_group(0)
	
	wall = SurfaceTool.new()
	wall.begin(Mesh.PRIMITIVE_TRIANGLES)
	wall.set_smooth_group(0)
	
	generate_terrain_cells()
				
	floor.generate_normals()
	wall.generate_normals()
	
	# Create a new mesh out of floor, and add the wall surface to it
	var terrain_mesh = floor.commit()
	wall.commit(terrain_mesh)
	
	ResourceSaver.save(terrain_mesh, "res://terrain/"+name+".tres", ResourceSaver.FLAG_COMPRESS)
	
	mesh = terrain_mesh
	
	print("generated mesh")

func generate_terrain_cells():
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
			
			# If all four corners are 0, omit this cell entirely and don't put anything here
			if ay == 0 and by == 0 and dy == 0 and cy == 0:
				continue
			
			# Case 0
			# If all edges are connected, put a full floor here.
			if ab and bd and cd and ac:
				add_full_floor()
				continue
			
			# edges going clockwise around the cell
			cell_edges = [ab, bd, cd, ac]
			# point heights going clockwise around the cell
			point_heights = [ay, by, dy, cy]
			
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
			var case_found: bool
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
				
				# if none of the branches are hit, this will be set to false at the last else statement.
				# opted for this instead of putting a break in every branch, that would take up space
				case_found = true
				
				# Case 1
				# If A is higher than adjacent and opposite corner is connected to adjacent,
				# add an outer corner here with upper and lower floor covering whole tile.
				if is_higher(ay, by) and is_higher(ay, cy) and bd and cd:
					add_outer_corner(true, true)
					
				# Case 2
				# If A is higher than C and B is higher than D,
				# add an edge here covering whole tile.
				# (May want to prevent this if B and C are not within merge distance)
				elif is_higher(ay, cy) and is_higher(by, dy) and ab and cd:
					add_edge(true, true)
					
				# Case 3: AB edge with A outer corner above
				elif is_higher(ay, by) and is_higher(ay, cy) and is_higher(by, dy) and cd:
					add_edge(true, true, 0.5, 1)
					add_outer_corner(false, true, true, by)
					
				# Case 4: AB edge with B outer corner above
				elif is_higher(by, ay) and is_higher(ay, cy) and is_higher(by, dy) and cd:
					add_edge(true, true, 0, 0.5)
					rotate_cell(1)
					add_outer_corner(false, true, true, cy)
					
				# Case 5: B and C are higher than A and D.
				# Diagonal raised floor between B and C.
				# B and C must be within merge distance.
				elif is_lower(ay, by) and is_lower(ay, cy) and is_lower(dy, by) and is_lower(dy, cy) and is_merged(by, cy):
					add_inner_corner(true, false)
					add_diagonal_floor(by, cy, true, true)
					rotate_cell(2)
					add_inner_corner(true, false)
					
				# Case 5.5: B and C are higher than A and D, and B is higher than C.
				# Place a raised diagonal floor between, and an outer corner around B.
				elif is_lower(ay, by) and is_lower(ay, cy) and is_lower(dy, by) and is_lower(dy, cy) and is_higher(by, cy):
					add_inner_corner(true, false, true)
					add_diagonal_floor(cy, cy, true, true)
					
					# opposite lower floor
					rotate_cell(2)
					add_inner_corner(true, false, true)
					
					# higher corner B
					rotate_cell(-1)
					add_outer_corner(false, true)
					
				# Case 6: inner corner, where A is lower than B and C, and D is connected to B and C.
				elif is_lower(ay, by) and is_lower(ay, cy) and bd and cd:
					add_inner_corner(true, true)
					
				# Case 7: A is lower than B and C, B and C are merged, and D is higher than B and C.
				# Outer corner around A, and on top of htat an inner corner around D
				elif is_lower(ay, by) and is_lower(ay, cy) and is_higher(dy, by) and is_higher(dy, cy) and is_merged(by, cy):
					add_inner_corner(true, false)
					add_diagonal_floor(by, cy, true, false)
					rotate_cell(2)
					add_outer_corner(false, true)
					
				# Case 8: Inner corner surrounding A, with an outer corner sitting atop C.
				elif is_lower(ay, by) and is_lower(ay, cy) and is_lower(dy, cy) and bd:
					add_inner_corner(true, false, true)
					start_floor()
					
					#add_point(1, dy, 1)
					#add_point(0.5, dy, 1, 1, 0)
					#add_point(0, by, 0.5, 1, 1)
					#
					#add_point(1, dy, 1)
					#add_point(0, by, 0.5, 1, 0)
					#add_point(0.25, by, 0.25)
					#
					#add_point(1, dy, 1)
					#add_point(0.25, by, 0.25)
					#add_point(0.5, by, 0)
					
					
					# D corner. B edge is connected, so use halfway point bewteen B and D
					add_point(1, dy, 1)
					add_point(0.5, dy, 1, 1, 0)
					add_point(1, (by+dy)/2, 0.5)
					
					# B corner
					add_point(1, by, 0)
					add_point(1, (by+dy)/2, 0.5)
					add_point(0.5, by, 0, 0, 1)
					
					# Center floors
					add_point(0.5, by, 0, 0, 1)
					add_point(1, (by+dy)/2, 0.5)
					add_point(0, by, 0.5, 1, 1)
					
					add_point(0.5, dy, 1, 1, 0)
					add_point(0, by, 0.5, 1, 1)
					add_point(1, (by+dy)/2, 0.5)
					#
					# Walls to upper corner
					start_wall()
					add_point(0, by, 0.5)
					add_point(0.5, dy, 1)
					add_point(0, cy, 0.5)
					
					add_point(0.5, cy, 1)
					add_point(0, cy, 0.5)
					add_point(0.5, dy, 1)
					
					# C upper floor
					start_floor()
					add_point(0, cy, 1)
					add_point(0, cy, 0.5, 0, 1)
					add_point(0.5, cy, 1, 0, 1)
					#
				# Case 9: Inner corner surrounding A, with an outer corner sitting atop B.
				elif is_lower(ay, by) and is_lower(ay, cy) and is_lower(dy, by) and cd:
					add_inner_corner(true, false, true)
					
					# D corner. C edge is connected, so use halfway point bewteen C and D
					start_floor()
					add_point(1, dy, 1)
					add_point(0.5, (dy+cy)/2, 1)
					add_point(1, dy, 0.5)
					
					# C corner
					add_point(0, cy, 1)
					add_point(0, cy, 0.5)
					add_point(0.5, (dy+cy)/2, 1)
					
					# Center floors
					add_point(0, cy, 0.5)
					add_point(0.5, cy, 0)
					add_point(0.5, (dy+cy)/2, 1)
					
					add_point(1, dy, 0.5)
					add_point(0.5, (dy+cy)/2, 1)
					add_point(0.5, cy, 0)
					
					# Walls to upper corner
					start_wall()
					add_point(0.5, cy, 0)
					add_point(0.5, by, 0)
					add_point(1, dy, 0.5)
					
					add_point(1, by, 0.5)
					add_point(1, dy, 0.5)
					add_point(0.5, by, 0)
					
					# B upper floor
					start_floor()
					add_point(1, by, 0)
					add_point(1, by, 0.5)
					add_point(0.5, by, 0)
					
				# Case 10: Inner corner surrounding A, with an edge sitting atop BD.
				elif is_lower(ay, by) and is_lower(ay, cy) and is_higher(dy, cy) and bd:
					add_inner_corner(true, false, true, true, false)
					
					rotate_cell(1)
					add_edge(false, true)
					
				# Case 11: Inner corner surrounding A, with an edge sitting atop CD.
				elif is_lower(ay, by) and is_lower(ay, cy) and is_higher(dy, by) and cd:
					add_inner_corner(true, false, true, false, true)
					
					rotate_cell(2)
					add_edge(false, true)
					
				# Case 12: Clockwise upwards spiral with A as the highest lowest point and C as the highest. A is lower than B, B is lower than D, D is lower than C, and C is higher than A.
				elif is_lower(ay, by) and is_lower(by, dy) and is_lower(dy, cy) and is_higher(cy, ay):
					add_inner_corner(true, false, true, false, true)
					
					rotate_cell(2)
					add_edge(false, true, 0, 0.5)
					
					rotate_cell(1)
					add_outer_corner(false, true, true, cy)
				
				# Case 13: Clockwise upwards spiral, A lowest and B highest
				elif is_lower(ay, cy) and is_lower(cy, dy) and is_lower(dy, by) and is_higher(by, ay):
					add_inner_corner(true, false, true, true, false)
					
					rotate_cell(1)
					add_edge(false, true, 0.5, 1)
					
					add_outer_corner(false, true, true, by)
					
				# Case 14: A<B, B<C, C<D. outer corner atop edge atop inner corner
				elif is_lower(ay, by) and is_lower(by, cy) and is_lower(cy, dy):
					add_inner_corner(true, false, true, false, true)
					
					rotate_cell(2)
					add_edge(false, true, 0.5, 1)
					
					add_outer_corner(false, true, true, by)
					
				# Case 15: A<C, C<B, B<D
				elif is_lower(ay, cy) and is_lower(cy, by) and is_lower(by, dy):
					add_inner_corner(true, false, true, true, false)
					
					rotate_cell(1)
					add_edge(false, true, 0, 0.5)
					
					rotate_cell(1)
					add_outer_corner(false, true, true, cy)
					
				# Case 16: All edges are connected, except AC, and A is higher than C.
				# Make an edge here, but merge one side of the edge together
				elif ab and bd and cd and is_higher(ay, cy):
					var edge_by = (by+dy)/2
					var edge_dy = (by+dy)/2
					
					# Upper floor - use A and B edge for heights
					start_floor()
					add_point(0, ay, 0) #A
					add_point(1, by, 0) # B
					add_point(1, edge_by, 0.5) #D
					
					add_point(1, edge_by, 0.5) #D
					add_point(0, ay, 0.5, 0, 1) #C
					add_point(0, ay, 0) #A
					
					# Wall from left to right edge
					start_wall()
					add_point(0, cy, 0.5)
					add_point(0, ay, 0.5)
					add_point(1, edge_dy, 0.5)
					
					# Lower floor - use C and D edge
					start_floor()
					add_point(0, cy, 0.5, 1, 0)
					add_point(1, edge_dy, 0.5)
					add_point(0, cy, 1)
					
					add_point(1, dy, 1)
					add_point(0, cy, 1)
					add_point(1, edge_dy, 0.5)


				# Case 17: All edges are connected, except AC, and A is higher than C.
				# Make an edge here, but merge one side of the edge together
				elif ab and ac and cd and is_higher(by, dy):
					# Only merge the ay/cy edge if AC edge is connected
					var edge_ay = (ay+cy)/2
					var edge_cy = (ay+cy)/2
					
					# Upper floor - use A and B edge for heights
					start_floor()
					add_point(0, ay, 0)
					add_point(1, by, 0)
					add_point(0, edge_ay, 0.5)
					
					add_point(1, by, 0.5, 0, 1)
					add_point(0, edge_ay, 0.5)
					add_point(1, by, 0)
					
					# Wall from left to right edge
					start_wall()
					add_point(1, by, 0.5)
					add_point(1, dy, 0.5)
					add_point(0, edge_ay, 0.5)
					
					# Lower floor - use C and D edge
					start_floor()
					add_point(0, edge_cy, 0.5)
					add_point(1, dy, 0.5, 1, 0)
					add_point(1, dy, 1)
					
					add_point(0, cy, 1)
					add_point(0, edge_cy, 0.5)
					add_point(1, dy, 1)
				
					
				else:
					case_found = false
					
				if case_found:
					break
					
			if not case_found:
				#invalid / unknown cell type. put a full floor here and hope it looks fine
				#add_full_floor()
				pass

# True if A is higher than B and outside of merge distance
func is_higher(a: float, b: float):
	return a - b > merge_threshold
	
# True if A is lower than B and outside of merge distance
func is_lower(a: float, b: float):
	return a - b < -merge_threshold
	
func is_merged(a: float, b: float):
	return abs(a - b) < merge_threshold
	
# Rotate r times clockwise. if negative, rotate clockwise -r times.
func rotate_cell(rotations: int):
	r = (r + 4 + rotations) % 4
	
	ab = cell_edges[r]
	bd = cell_edges[(r+1)%4]
	cd = cell_edges[(r+2)%4]
	ac = cell_edges[(r+3)%4]
	
	ay = point_heights[r]
	by = point_heights[(r+1)%4]
	dy = point_heights[(r+2)%4]
	cy = point_heights[(r+3)%4]

# Adds a point. Coordinates are relative to the top-left corner (not mesh origin relative).
# UV.x is closeness to the bottom of an edge. and UV.Y is closeness to the edge of a cliff.
func add_point(x: float, y: float, z: float, uv_x: float = 0, uv_y: float = 0):
	for i in range(r):
		var temp = x
		x = 1 - z
		z = temp
		
	var st = floor if floor_mode else wall
	
	#st.set_uv(Vector2((cell_x+x) / dimensions.x, (cell_z+z) / dimensions.z))
	st.set_uv(Vector2(uv_x, uv_y))
	st.add_vertex(Vector3(cell_x+x, y, cell_z+z))
	
# if true, currently making floor geometry. if false, currently making wall geometry.
var floor_mode: bool = true
	
func start_floor():
	floor_mode = true

func start_wall():
	floor_mode = false

func add_full_floor():
	start_floor()
	# ABC tri
	add_point(0, ay, 0)
	add_point(1, by, 0)
	add_point(0, cy, 1)
	# DCB tri
	add_point(1, dy, 1)
	add_point(0, cy, 1)
	add_point(1, by, 0)

# Add an outer corner, where A is the raised corner.
# if flatten_bottom is true, then bottom_height is used for the lower height of the wall
func add_outer_corner(floor_below: bool = true, floor_above: bool = true, flatten_bottom: bool = false, bottom_height: float = -1):
	var edge_by = bottom_height if flatten_bottom else by
	var edge_cy = bottom_height if flatten_bottom else cy
	
	if floor_above:
		start_floor()
		add_point(0, ay, 0, 0, 0)
		add_point(0.5, ay, 0, 0, 1)
		add_point(0, ay, 0.5, 0, 1)
	
	# Walls - bases will use B and C height, while cliff top will use A height.
	start_wall()
	add_point(0, edge_cy, 0.5)
	add_point(0, ay, 0.5)
	add_point(0.5, edge_by, 0)
	
	add_point(0.5, ay, 0)
	add_point(0.5, edge_by, 0)
	add_point(0, ay, 0.5)

	if floor_below:
		start_floor()
		add_point(1, dy, 1)
		add_point(0, cy, 1)
		add_point(1, by, 0)	
		
		add_point(0, cy, 1)
		add_point(0, cy, 0.5, 1, 0)
		add_point(0.5, by, 0, 1, 0)
		
		add_point(1, by, 0)	
		add_point(0, cy, 1)
		add_point(0.5, by, 0, 1, 0)
	
# Add an edge, where AB is the raised edge.
# a_x is the x coordinate that the top-left of the uper floor connects to
# b_x is the x coordinate that the top-right of the upper floor connects to
func add_edge(floor_below: bool, floor_above: bool, a_x: float = 0, b_x: float = 1):
	# If A and B are out of merge distance, use the lower of the two
	var edge_ay = ay if ab else min(ay,by)
	var edge_by = by if ab else min(ay,by)
	var edge_cy = cy if cd else max(cy, dy)
	var edge_dy = dy if cd else max(cy, dy)
	
	# Upper floor - use A and B for heights
	if floor_above:
		start_floor()
		add_point(a_x, edge_ay, 0, 1 if a_x > 0 else 0, 0)
		add_point(b_x, edge_by, 0, 1 if b_x < 1 else 0, 0)
		add_point(0, edge_ay, 0.5, 0, 1)
		
		add_point(1, edge_by, 0.5, 0, 1)
		add_point(0, edge_ay, 0.5, 0, 1)
		add_point(b_x, edge_by, 0, 1 if b_x < 1 else 0, 0)
	
	# Wall from left to right edge
	start_wall()
	add_point(0, edge_cy, 0.5)
	add_point(0, edge_ay, 0.5)
	add_point(1, edge_dy, 0.5)
	
	add_point(1, edge_by, 0.5)
	add_point(1, edge_dy, 0.5)
	add_point(0, edge_ay, 0.5)
	
	# Lower floor - use C and D for height
	# Only place a flat floor below if CD is connected
	if floor_below:
		start_floor()
		add_point(0, cy, 0.5, 1, 0)
		add_point(1, dy, 0.5, 1, 0)
		add_point(0, cy, 1)
		
		add_point(1, dy, 1)
		add_point(0, cy, 1)
		add_point(1, dy, 0.5, 1, 0)

	
# Add an inner corner, where A is the lowered corner.
func add_inner_corner(lower_floor: bool = true, full_upper_floor: bool = true, flatten: bool = false, bd_floor: bool = false, cd_floor: bool = false):
	var corner_by = min(by,cy) if flatten else by
	var corner_cy = min(by,cy) if flatten else cy
	
	# Lower floor with height of point A
	if lower_floor:
		start_floor()
		add_point(0, ay, 0)
		add_point(0.5, ay, 0, 1, 0)
		add_point(0, ay, 0.5, 1, 0)

	start_wall()
	add_point(0, ay, 0.5)
	add_point(0.5, ay, 0)
	add_point(0, corner_cy, 0.5)
	
	add_point(0.5, corner_by, 0)
	add_point(0, corner_cy, 0.5)
	add_point(0.5, ay, 0)

	start_floor()
	if full_upper_floor:
		add_point(1, dy, 1)
		add_point(0, corner_cy, 1)
		add_point(1, corner_by, 0)
		
		add_point(0, corner_cy, 1)
		add_point(0, corner_cy, 0.5, 0, 1)
		add_point(0.5, corner_by, 0, 0, 1)
		
		add_point(1, corner_by, 0)
		add_point(0, corner_cy, 1)
		add_point(0.5, corner_by, 0, 0, 1)
		
	# if C and D are both higher than B, and B does not connect the corners, there's an edge above, place floors that will connect to the CD edge
	if cd_floor:
		# use height of B corner
		add_point(1, by, 0.5, 1, 0)
		add_point(0.5, by, 0, 0, 1)
		add_point(1, by, 0)
		
		add_point(1, by, 0.5, 1, 0)
		add_point(0, by, 0.5, 0, 1)
		add_point(0.5, by, 0, 0, 1)
		
	# if B and D are both higher than C, and C does not connect the corners, there's an edge above, place floors that will connect to the BD edge
	if bd_floor: 
		# use height of C corner
		add_point(0.5, cy, 1, 1, 0)
		add_point(0, cy, 1)
		add_point(0, cy, 0.5, 0, 1)
		
		add_point(0.5, cy, 1, 1, 0)
		add_point(0, cy, 0.5, 0, 1)
		add_point(0.5, cy, 0, 0, 1)
		
# Add a diagonal floor, using heights of B and C and connecting their points using passed heights.
func add_diagonal_floor(b_y: float, c_y: float, a_cliff: bool, d_cliff: bool):
	start_floor()
	
	add_point(1, b_y, 0)
	add_point(0, c_y, 1)
	add_point(0.5, b_y, 0, 0 if a_cliff else 1, 1 if a_cliff else 0)
	
	add_point(0, c_y, 1)
	add_point(0, c_y, 0.5, 0 if a_cliff else 1, 1 if a_cliff else 0)
	add_point(0.5, b_y, 0, 0 if a_cliff else 1, 1 if a_cliff else 0)
	
	add_point(1, b_y, 0)
	add_point(1, b_y, 0.5, 0 if d_cliff else 1, 1 if d_cliff else 0)
	add_point(0, c_y, 1)
	
	add_point(0, c_y, 1)
	add_point(1, b_y, 0.5, 0 if d_cliff else 1, 1 if d_cliff else 0)
	add_point(0.5, c_y, 1, 0 if d_cliff else 1, 1 if d_cliff else 0)

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
	
	for z in range(min(dimensions.z, image.get_height()+1)):
		for x in range(min(dimensions.x, image.get_width()+1)):
			var height = image.get_pixel(x, z).r * dimensions.y
			if random_noise != 0:
				height += rng.randf_range(-random_noise, random_noise)
			height = max(0, height)
			
			height_map[z][x] = height
