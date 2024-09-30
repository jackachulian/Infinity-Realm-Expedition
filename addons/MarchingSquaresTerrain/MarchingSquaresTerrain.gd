@tool
class_name MarchingSquaresTerrain
extends MeshInstance3D

@export var terrain_material: Material

# Size of the 2 dimensional cell array (xz value) and y scale (y value)
@export var dimensions: Vector3i = Vector3i(32, 1, 32)

# Unit XZ size of a single cell
@export var cell_size: Vector2 = Vector2(2, 2)

@export var height_map_image: Texture2D

# possible change: have  aflat lciffs variable. if false, cliffs points will be from the heightmap.
# would probably need some kind of system to note the amount of adjacent points for each lower point. idk how i would even implement that

# The max height distance between points before a wall is created between them
@export var merge_threshold: float = 0.06

# If above 0, round height values to this nearest interval.
@export var height_banding: float = 0.1

# ArrayMesh arrays
var surface_array: Array
var verts: PackedVector3Array = PackedVector3Array()
var uvs: PackedVector2Array = PackedVector2Array()
var normals: PackedVector3Array = PackedVector3Array()
var indices: PackedInt32Array = PackedInt32Array()
	
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

# Stores the heights from the heightmap (from red channel of image)
var height_map: Array[Array]

# Stores which cells need their geometry updated after a change in terrain height
var needs_update: Array[Array]

# Stores the start position of vertexes designated for each cell.
# Two dimension array of [col / z position][row / x position].
# Contains dimensions.z - 1 rows
# Length of each row is dimensions.x - 1
var index_lengths: Array[Array]

# Current last indexed point
var index: int


		
func _enter_tree():
	if Engine.is_editor_hint():
		load_height_map()
		initialize_arrays()
		regenerate_mesh()
		
func initialize_arrays():
	surface_array = []
	surface_array.resize(Mesh.ARRAY_MAX)
	
	var corners_size: int = dimensions.x * dimensions.z;
	
	verts.resize(corners_size);
	uvs.resize(corners_size);
	normals.resize(corners_size);
	indices.clear()
	
	# For each point
	for z in range(dimensions.z):
		for x in range(dimensions.x):
			# The first (X * Z) points are on the corners that directly line up with the heightmap.
			# These points are used at least once by all 4 cells sharing that corner and will never be unused.
			# For that reason, these verts will always be at the start of the list.
			# Use height from heightmap to create these vertices at the correct height.
			index = z*dimensions.x + x
			
			var y = height_map[z][x];
			
			var vert = Vector3(x * cell_size.x, y, z * cell_size.y)
			verts[index] = vert
			
			# corner verts will always not be on an edge or corner that divides the cells
			uvs[index] = Vector2(0, 0) 
			
			# for now, floors will always face straight up
			normals[index] = Vector3.UP
#
	needs_update = []
	needs_update.resize(dimensions.z - 1)
	
	index_lengths = []
	index_lengths.resize(dimensions.z - 1)
	
	 #For each cell
	for z in range(dimensions.z - 1):
		needs_update[z] = []
		needs_update[z].resize(dimensions.x - 1)

		index_lengths[z] = []
		index_lengths[z].resize(dimensions.x - 1)
		for x in range(dimensions.x - 1):
			pass
			# Each cell will initially need to be updated
			needs_update[z][x] = true
			# all cells will initially have an index length of 0
			# once actual geometry is added, these numbers will go up
			index_lengths[z][x] = 0
			

func regenerate_mesh():
	print("regenerating terrain...")
	var start_time: int = Time.get_ticks_msec()
	
	# Generate cells - will update the verts and UV arrays
	generate_terrain_cells()
	
	# Commit the mesh
	surface_array[Mesh.ARRAY_VERTEX] = verts
	surface_array[Mesh.ARRAY_TEX_UV] = uvs
	surface_array[Mesh.ARRAY_NORMAL] = normals
	surface_array[Mesh.ARRAY_INDEX] = indices
	
	mesh = ArrayMesh.new()
	mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, surface_array)
	mesh.surface_set_material(0, terrain_material)
	
	if get_node_or_null("Terrain_col"):
		$Terrain_col.free()
	create_trimesh_collision()
	
	var elapsed_time: int = Time.get_ticks_msec() - start_time
	print("generated terrain in "+str(elapsed_time)+"ms")
	
	#var vert_total = len(mesh.surface_get_arrays(0)[Mesh.ARRAY_VERTEX])
	#print("total verts: "+str(vert_total))
	#var index_total = len(mesh.surface_get_arrays(0)[Mesh.ARRAY_INDEX])
	#print("total indices: "+str(index_total))
	#
	#ResourceSaver.save(mesh, "res://terrain/"+name+".tres", ResourceSaver.FLAG_COMPRESS)

func generate_terrain_cells():
	# Start at first non-corner index
	index = dimensions.z * dimensions.x;
	
	# Iterate over all cells
	for z in range(dimensions.z - 1):
		cell_z = z
		
		for x in range(dimensions.x - 1):
			var index_length = index_lengths[z][x]
			print("index length of ", x, ", ", z, ": ", index_length)
			
			# If cell does not need an update, skip this cell
			if not needs_update[z][x]:
				index += index_length
				continue
				
			# Cell is now being updated, set its needs_update state to false
			needs_update[z][x] = false
			cell_x = x
			r = 0
			
			if index_length > 0:
				
				for j in range(index_length):
					indices.remove_at(index)
			
			# Get heights of 4 surrounding corners
			ay = height_map[z][x] # top-left
			by = height_map[z][x+1] # top-right
			cy = height_map[z+1][x] # bottom-left
			dy = height_map[z+1][x+1] # bottom-right
			
			# If all four corners are 0, omit this cell entirely and don't put anything here
			#if ay == 0 and by == 0 and dy == 0 and cy == 0:
				#continue
			
			# Track which edges shold be connected and not have a wall bewteen them.
			ab = abs(ay-by) < merge_threshold # top edge
			ac = abs(ay-cy) < merge_threshold # bottom edge
			bd = abs(by-dy) < merge_threshold # right edge
			cd = abs(cy-dy) < merge_threshold # bottom edge
			
			var case_found := false
			
			break
			
			# Case 0
			# If all edges are connected, put a full floor here. (Will not use cell_verts, cell_uvs, etc)
			if ab and bd and cd and ac:
				add_full_floor()
				case_found = true
			else:
				# edges going clockwise around the cell
				cell_edges = [ab, bd, cd, ac]
				# point heights going clockwise around the cell
				point_heights = [ay, by, dy, cy]

			for i in range(4):
				# stop searching of a case was found during the last iteration (or if full floor was already added before first iter)
				if case_found:
					break
				
				# Use the rotation of the corner - the amount of counter-clockwise rotations for it to become the top-left corner, which is just its index in the point lists.
				r = i

				ab = cell_edges[r]
				bd = cell_edges[(r+1)%4]
				cd = cell_edges[(r+2)%4]
				ac = cell_edges[(r+3)%4]
				
				ay = point_heights[r]
				by = point_heights[(r+1)%4]
				dy = point_heights[(r+2)%4]
				cy = point_heights[(r+3)%4]
			
				# iterates through all cases for all rotations and adds the first one found
				case_found = check_cases()
				
			#if not case_found:
				##invalid / unknown cell type. put a full floor here and hope it looks fine
				##add_full_floor()
				#pass

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

enum Corner{A=0,B=1,C=2,D=3}

# Add the indexed point that is right on a corner. a=0, b=1, c=2, d=3.
func add_corner_point(corner: int):
	corner = (corner+r)%4;
	
	var x: int = cell_x
	if (corner == Corner.B or corner == Corner.D): x += 1
	var z: int = cell_z
	if (corner == Corner.C or corner == Corner.D): z += 1
	
	var corner_index = z*dimensions.x + x
	
	indices.insert(index, corner_index)
	index += 1

# Adds an arbirary point. Coordinates are relative to the top-left corner (not mesh origin relative).
# UV.x is closeness to the bottom of an edge. and UV.Y is closeness to the edge of a cliff.
func add_point(x: float, y: float, z: float, uv_x: float = 0, uv_y: float = 0, uv2_x: float = 0, uv2_y: float = 0):
	for j in range(r):
		var temp = x
		x = 1 - z
		z = temp	
		
	var vert = Vector3((cell_x+x) * cell_size.x, y, (cell_z+z) * cell_size.y)
	verts.append(vert)
	
	if floor_mode:
		uvs.append(Vector2(uv_x, uv_y))
		# use this for completely flat looking floors
		#st.set_normal(Vector3(0, 1, 0))
	else:
		# walls will always have UV of 1, 1
		uvs.append(Vector2(1, 1))
	
	# Color = terrain space coordinates. 
	# for XZ, 0,0,0 = top left of heightmap at lowest height, 1,1,1 = bottom right of heightmap at highest height
	#st.set_color(Color((cell_x+x) / dimensions.x, y / dimensions.x, (cell_z+z) / dimensions.z))
	
	# for now, floors face straight up,
	# and walls are flat shaded 
	# will allow normal-based outlines beween wall/floor segments

	indices.insert(index, len(verts)-1)
	index += 1;
	
	# Non-corner floors face straight up
	if floor_mode:
		normals.insert(index, Vector3.UP)
		
	# Walls are flat shaded
	else:
		var cell_ind = len(indices)
		if cell_ind % 3 == 0:
			var edge1 = verts[cell_ind-2] - verts[cell_ind-3]
			var edge2 = verts[cell_ind-1] - verts[cell_ind-3]
			var normal = -edge1.cross(edge2).normalized()
	
			normals.append(normal); normals.append(normal); normals.append(normal); 
	
# if true, currently making floor geometry. if false, currently making wall geometry.
var floor_mode: bool = true
	
func start_floor():
	floor_mode = true

func start_wall():
	floor_mode = false

func add_full_floor():
	start_floor()
	
	add_corner_point(Corner.A)
	add_corner_point(Corner.B)
	add_corner_point(Corner.C)
	
	add_corner_point(Corner.D)
	add_corner_point(Corner.C)
	add_corner_point(Corner.B)
	
	
	# ABC tri
	#add_point(0, ay, 0)
	#add_point(1, by, 0)
	#add_point(0, cy, 1)
	## DCB tri
	#add_point(1, dy, 1)
	#add_point(0, cy, 1)
	#add_point(1, by, 0)

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
	add_point(0, edge_cy, 0.5, 0, 0)
	add_point(0, ay, 0.5, 0, 1)
	add_point(0.5, edge_by, 0, 1, 0)
	
	add_point(0.5, ay, 0, 1, 1)
	add_point(0.5, edge_by, 0, 1, 0)
	add_point(0, ay, 0.5, 0, 1)

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
		add_point(0, edge_ay, 0.5, -1 if b_x < 1 else (1 if a_x > 0 else 0), 1)
		
		add_point(1, edge_by, 0.5, -1 if a_x > 0  else (1 if b_x < 1 else 0), 1)
		add_point(0, edge_ay, 0.5, -1 if b_x < 1 else (1 if a_x > 0 else 0), 1)
		add_point(b_x, edge_by, 0, 1 if b_x < 1 else 0, 0)
	
	# Wall from left to right edge
	start_wall()
	add_point(0, edge_cy, 0.5, 0, 0)
	add_point(0, edge_ay, 0.5, 0, 1)
	add_point(1, edge_dy, 0.5, 1, 0)
	
	add_point(1, edge_by, 0.5, 1, 1)
	add_point(1, edge_dy, 0.5, 1, 0)
	add_point(0, edge_ay, 0.5, 0, 1)
	
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
	add_point(0, ay, 0.5, 1, 0)
	add_point(0.5, ay, 0, 0, 0)
	add_point(0, corner_cy, 0.5, 1, 1)
	
	add_point(0.5, corner_by, 0, 0, 1)
	add_point(0, corner_cy, 0.5, 1, 1)
	add_point(0.5, ay, 0, 0, 0)

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
		add_point(1, by, 0, 0, 0)
		add_point(0, by, 0.5, 1, 1)
		add_point(0.5, by, 0, 0, 1)
		
		add_point(1, by, 0, 0, 0)
		add_point(1, by, 0.5, 1, -1)
		add_point(0, by, 0.5, 1, 1)
		
	# if B and D are both higher than C, and C does not connect the corners, there's an edge above, place floors that will connect to the BD edge
	if bd_floor: 
		# use height of C corner
		#add_point(0.5, cy, 1, 1, -1)
		#add_point(0, cy, 0.5, -1, 1)
		#add_point(0, cy, 0.5, -1, 1)
		
		add_point(0, cy, 0.5, 0, 1)
		add_point(0.5, cy, 0, 1, 1)
		add_point(0, cy, 1, 0, 0)
		
		add_point(0.5, cy, 1, 1, -1)
		add_point(0, cy, 1, 0, 0)
		add_point(0.5, cy, 0, 1, 1)
		
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

# Checks all cases (other than the full floor case). 
# Checks only for the current rotation, so this is run one for each rotation, per cell.
# Adds the corresponding geometry to cell_verts, cell_uvs, cell_normals and cell_indices.
# Returns false if no case is found, though, I'm pretty sure that isn't possible.
func check_cases() -> bool:
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
	# Outer corner around A, and on top of that an inner corner around D
	elif is_lower(ay, by) and is_lower(ay, cy) and is_higher(dy, by) and is_higher(dy, cy) and is_merged(by, cy):
		add_inner_corner(true, false)
		add_diagonal_floor(by, cy, true, false)
		rotate_cell(2)
		add_outer_corner(false, true)
		
	# Case 8: Inner corner surrounding A, with an outer corner sitting atop C.
	elif is_lower(ay, by) and is_lower(ay, cy) and is_lower(dy, cy) and bd:
		add_inner_corner(true, false, true)
		start_floor()
		
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
		
		add_point(1, edge_by, 0.5, 0, 1) #D
		add_point(0, ay, 0.5, 0, 1) #C
		add_point(0, ay, 0) #A
		
		# Wall from left to right edge
		start_wall()
		add_point(0, cy, 0.5, 0, 0)
		add_point(0, ay, 0.5, 0, 1)
		add_point(1, edge_dy, 0.5, 1, 0)
		
		# Lower floor - use C and D edge
		start_floor()
		add_point(0, cy, 0.5, 1, 0)
		add_point(1, edge_dy, 0.5, 1, 0)
		add_point(0, cy, 1)
		
		add_point(1, dy, 1)
		add_point(0, cy, 1)
		add_point(1, edge_dy, 0.5)


	# Case 17: All edges are connected, except BD, and B is higher than D.
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
		add_point(0, edge_ay, 0.5, 0, 1)
		add_point(1, by, 0)
		
		# Wall from left to right edge
		start_wall()
		add_point(1, by, 0.5, 1, 1)
		add_point(1, dy, 0.5, 1, 0)
		add_point(0, edge_ay, 0.5, 0, 0)
		
		# Lower floor - use C and D edge
		start_floor()
		add_point(0, edge_cy, 0.5, 1, 0)
		add_point(1, dy, 0.5, 1, 0)
		add_point(1, dy, 1)
		
		add_point(0, cy, 1)
		add_point(0, edge_cy, 0.5)
		add_point(1, dy, 1)
	
	else:
		return false
		
	return true

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
	if not image:
		return
	
	for z in range(min(dimensions.z, image.get_height())):
		for x in range(min(dimensions.x, image.get_width())):
			var height = image.get_pixel(x, z).r * dimensions.y
			
			if height_banding > 0:
				height = round(height / height_banding) * height_banding
			
			height_map[z][x] = height
			
func simple_grass():
	var grass_mesh = SurfaceTool.new();
