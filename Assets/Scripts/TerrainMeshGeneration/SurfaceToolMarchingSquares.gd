@tool
class_name MarchingSquaresTerrain
extends MeshInstance3D


# Dimensions of the terrain.
# x = x length
# y = max height.
# z = z length
@export var dimensions: Vector3i = Vector3i(10, 1, 10):
	set(new_dimensions):
		dimensions = new_dimensions
		load_height_map()
		generate_mesh()

var height_map: Array

@export var height_map_image: Texture2D

var rng = RandomNumberGenerator.new()

var st: SurfaceTool

func _ready() -> void:
	load_height_map()
	generate_mesh()

func load_height_map():	
	height_map = []
	height_map.resize(dimensions.z)
	
	for z in range(dimensions.z):
		height_map[z] = []
		height_map[z].resize(dimensions.x)
		for x in range(dimensions.x):
			height_map[z][x] = 0
		
	if not height_map_image:
		generate_random_height_map()
		return
	
	var image = height_map_image.get_image()
	
	for z in range(min(dimensions.z, image.get_height()+1) - 1):
		for x in range(min(dimensions.x, image.get_width()+1) - 1):
			var height = round(image.get_pixel(x, z).r * dimensions.y)
			
			height_map[z][x] = height
			
			# raise all 4 corners to the mighest out of any height assigned to it yet.
			#height_map[z][x] = max(height_map[z][x], height)
			#height_map[z][x+1] = max(height_map[z][x+1], height)
			#height_map[z+1][x] = max(height_map[z+1][x], height)
			#height_map[z+1][x+1] = max(height_map[z+1][x+1], height)
	
func generate_mesh():
	st = SurfaceTool.new()

	st.begin(Mesh.PRIMITIVE_TRIANGLES)

	# Prepare attributes for add_vertex.
	st.set_normal(Vector3(0, 1, 0))
	
	# For each z,x,y pair, generate all floors and walls that need to occupy
	# the cube of size (x,y,z), with its lower top-left corner at the coordinates (x,y,z).
	# Generates the floor, and the walls that sit on the floor/walls below it.
	for z in range(dimensions.z - 1):
		for x in range(dimensions.x - 1):
			# Run for each height layer
			for y in range(dimensions.y + 1):
				# Defines which corner's heights are higher than the current height layer
				var tlh: bool = height_map[z][x] > y
				var trh: bool = height_map[z][x+1] > y
				var blh: bool = height_map[z+1][x] > y
				var brh: bool = height_map[z+1][x+1] > y
				
				# If all four corners higher than the current height, tile at this height is fully underground, no floor needed
				if tlh and trh and blh and brh:
					continue
					
				# Defines which corners' heights are equal to the current height layer
				var tl: bool = height_map[z][x] == y
				var tr: bool = height_map[z][x+1] == y
				var bl: bool = height_map[z+1][x] == y
				var br: bool = height_map[z+1][x+1] == y
				
				# If all four corners are lower than the current height, no floor can be here
				if not (tl or tlh) and not (tr or trh) and not (bl or blh) and not (br or brh):
					continue
					
				# === WALLS ===
				# If a corner is higher than current height and adjacent corners are lower or equal,
				# an outer corner wall is needed in that corner.
				if tlh and not (trh or blh):
					add_corner_wall(x, y, z, 0, 0, false)
				if trh and not (tlh or brh):
					add_corner_wall(x, y, z, 1, 0, false)
				if blh and not (tlh or brh):
					add_corner_wall(x, y, z, 0, 1, false)
				if brh and not (trh or blh):
					add_corner_wall(x, y, z, 1, 1, false)
					
				# If one corner is lower or equal to current height and adjacent are higher,
				# an inner corner is needed.
				if not tlh and trh and blh:
					add_corner_wall(x, y, z, 0, 0, true)
				if not trh and tlh and brh:
					add_corner_wall(x, y, z, 1, 0, true)
				if not blh and tlh and brh:
					add_corner_wall(x, y, z, 0, 1, true)
				if not brh and trh and blh:
					add_corner_wall(x, y, z, 1, 1, true)
					
				# If both corners on an edge are higher and the opposite corners are lower or equal,
				# an edge wall is needed
				if (tlh and trh) and not (blh or brh):
					add_edge_wall(x, y, z, 0, 0.5, 1, 0.5)
				if (tlh and blh) and not (trh or brh):
					add_edge_wall(x, y, z, 0.5, 1, 0.5, 0)
				if (blh and brh) and not (tlh or trh):
					add_edge_wall(x, y, z, 1, 0.5, 0, 0.5)
				if (trh and brh) and not (tlh or blh):
					add_edge_wall(x, y, z, 0.5, 0, 0.5, 1)
					
				# === FLOORS ===
				# If all corners are equal to current height, put a full floor here covering all corners.
				if tl and tr and bl and br:
					add_full_floor(x, y, z)
					continue
					
				# If all corners are equal except one that is higher, put an inner corner floor there.
				if tlh and tr and bl and br:
					add_inner_corner_floor(x, y, z, 0, 0)
				if tl and trh and bl and br:
					add_inner_corner_floor(x, y, z, 1, 0)
				if tl and tr and blh and br:
					add_inner_corner_floor(x, y, z, 0, 1)
				if tl and tr and bl and brh:
					add_inner_corner_floor(x, y, z, 1, 1)
				
				# If a corner is equal but adjacent are higher, put an outer corner floor there.
				if tl and trh and blh:
					add_outer_corner_floor(x, y, z, 0, 0)
				if tr and tlh and brh:
					add_outer_corner_floor(x, y, z, 1, 0)
				if bl and tlh and brh:
					add_outer_corner_floor(x, y, z, 0, 1)
				if br and trh and blh:
					add_outer_corner_floor(x, y, z, 1, 1)
					
				# If one edge is equal and opposite edge is higher, add an edge floor.
				if tl and tr and blh and brh:
					add_rectangle_floor(x, y, z, 0, 0, 1, 0.5)
				if tl and bl and trh and brh:
					add_rectangle_floor(x, y, z, 0, 0, 0.5, 1)
				if bl and br and tlh and trh:
					add_rectangle_floor(x, y, z, 0, 0.5, 1, 1)
				if tr and br and tlh and blh:
					add_rectangle_floor(x, y, z, 0.5, 0, 1, 1)
					
				# If in between a gap where opposite corners are equal/higher (at least 1 equal) 
				# and the other corners are higher or lower and both adjacent are not higher,
				# place an inner floor covering all but corners,
				# and then create floors for the only visible corners.
				if (tl or br) and (tl or tlh) and (br or brh) and not (trh or blh) and not tr and not bl:
					add_outer_corner_floor(x, y, z, 0, 0)
					add_outer_corner_floor(x, y, z, 1, 1)
					add_inner_floor(x, y, z)
				if (tr or bl) and (tr or trh) and (bl or blh) and not (tlh or brh) and not tl and not br:
					add_outer_corner_floor(x, y, z, 0, 1)
					add_outer_corner_floor(x, y, z, 1, 0)
					add_inner_floor(x, y, z)
					
				# If thers is a corner where the adjacent corners are both lower, add a corner floor there.
				# This means two corners might be added on a single tile. this is fine, they shouldn't overlap, they are in their own corners
				# optional visual change though: bridge the two corners instead of making two separate corner pieces
				if tl and not (tr or trh) and not (bl or blh):
					add_outer_corner_floor(x, y, z, 0, 0)
				if tr and not (tl or tlh) and not (br or brh):
					add_outer_corner_floor(x, y, z, 1, 0)
				if bl and not (tl or tlh) and not (br or brh):
					add_outer_corner_floor(x, y, z, 0, 1)
				if br and not (tr or trh) and not (bl or blh):
					add_outer_corner_floor(x, y, z, 1, 1)
					
				# If there is one edge where both corners are equal or higher with at least one of them equal, 
				# and the opposite edge is lower, add a half floor along that edge.
				if (tl or tlh) and (tr or trh) and (tl or tr) and not (bl or blh) and not (br or brh):
					add_rectangle_floor(x, y, z, 0, 0, 1, 0.5)
				if (tl or tlh) and (bl or blh) and (tl or bl) and not (tr or trh) and not (br or brh):
					add_rectangle_floor(x, y, z, 0, 0, 0.5, 1)
				if (bl or blh) and (br or brh) and (bl or br) and not (tl or tlh) and not (tr or trh):
					add_rectangle_floor(x, y, z, 0, 0.5, 1, 1)
				if (tr or trh) and (br or brh) and (tr or br) and not (tl or blh) and not (bl or blh):
					add_rectangle_floor(x, y, z, 0.5, 0, 1, 1)
					
				# Check for inner corner floors.
				# Corner must be lower, all others corners must be at current height or higher, at least one must be at current height.
				# NOTE: if this is to work with CSG in the cuture, then all points other than corner must be at same height,
				# and handling corners where one is lower, one is same and two others are higher must be added.
				# too complex for me r and i will probably rewrite the system to be less brute forcey before that anyways.
				if not (tl or tlh) and (tr or bl or br) and (tr or trh) and (bl or blh) and (br or brh):
					add_inner_corner_floor(x, y, z, 0, 0)
				if not (tr or trh) and (tl or bl or br) and (tl or tlh) and (bl or blh) and (br or brh):
					add_inner_corner_floor(x, y, z, 1, 0)
				if not (bl or blh) and (tl or tr or br) and (tl or tlh) and (tr or trh) and (br or brh):
					add_inner_corner_floor(x, y, z, 0, 1)
				if not (br or brh) and (tl or tr or bl) and (tl or tlh) and (tr or trh) and (bl or blh):
					add_inner_corner_floor(x, y, z, 1, 1)

	# Commit to a mesh.
	mesh = st.commit()
	
# Adds an outer/inner corner stretching from connect_x (0=left 1=right) to connect_z (0=back 1=forward).
# if connect_x is 0, will connect to left (negative x direction), right if connect_x is 1.
# if connect_z is 0 will connect to back (negative z dirrection), forward if connect_z is 1.
func add_corner_wall(x: int, y: int, z: int, connect_x: int, connect_z: int, is_inner: bool):
	var flip = connect_x == connect_z
	if is_inner:
		flip = not flip

	var add_lower_x = func():
		st.set_uv(Vector2(0 if flip else 1, 0))
		st.add_vertex(Vector3(x+connect_x, y, z+0.5))
	
	var add_lower_z = func():
		st.set_uv(Vector2(1 if flip else 0, 0))
		st.add_vertex(Vector3(x+0.5, y, z+connect_z))
		
	var add_upper_x = func():
		st.set_uv(Vector2(0 if flip else 1, 1))
		st.add_vertex(Vector3(x+connect_x, y+1, z+0.5))
	
	var add_upper_z = func():
		st.set_uv(Vector2(1 if flip else 0, 1))
		st.add_vertex(Vector3(x+0.5, y+1, z+connect_z))
	
	if flip:
		add_lower_x.call()
		add_upper_x.call()
		add_lower_z.call()
		
		add_upper_z.call()
		add_lower_z.call()
		add_upper_x.call()
	else:
		add_lower_x.call()
		add_lower_z.call()
		add_upper_x.call()
		
		add_upper_z.call()
		add_upper_x.call()
		add_lower_z.call()
		
func add_edge_wall(x: int, y: int, z: int, left_x: float, left_z: float, right_x: float, right_z: float):
	st.set_uv(Vector2(0, 0))
	st.add_vertex(Vector3(x+left_x, y, z+left_z))
	
	st.set_uv(Vector2(0, 1))
	st.add_vertex(Vector3(x+left_x, y+1, z+left_z))

	st.set_uv(Vector2(1, 0))
	st.add_vertex(Vector3(x+right_x, y, z+right_z))
	
	
	st.set_uv(Vector2(1, 1))
	st.add_vertex(Vector3(x+right_x, y+1, z+right_z))

	st.set_uv(Vector2(1, 0))
	st.add_vertex(Vector3(x+right_x, y, z+right_z))

	st.set_uv(Vector2(0, 1))
	st.add_vertex(Vector3(x+left_x, y+1, z+left_z))
	
func add_full_floor(x: int, y: int, z: int):
	# Top-Left tri - right angle in top left / 0,0
	st.set_uv(Vector2(0, 0))
	st.add_vertex(Vector3(x, y, z))
	
	st.set_uv(Vector2(1, 0))
	st.add_vertex(Vector3(x+1, y, z))

	st.set_uv(Vector2(0, 1))
	st.add_vertex(Vector3(x, y, z+1))
	
	
	# Bottom-Right tri - right angle in bottom-right / 1,1
	st.set_uv(Vector2(1, 1))
	st.add_vertex(Vector3(x+1, y, z+1))
	
	st.set_uv(Vector2(0, 1))
	st.add_vertex(Vector3(x, y, z+1))
	
	st.set_uv(Vector2(1, 0))
	st.add_vertex(Vector3(x+1, y, z))
	
# Add a floor covering all but the outer corners.
func add_inner_floor(x: int, y: int, z: int):
	st.set_uv(Vector2(0.5, 0))
	st.add_vertex(Vector3(x+0.5, y, z))
	
	st.set_uv(Vector2(1, 0.5))
	st.add_vertex(Vector3(x+1, y, z+0.5))

	st.set_uv(Vector2(0, 0.5))
	st.add_vertex(Vector3(x, y, z+0.5))
	
	
	st.set_uv(Vector2(0.5, 1))
	st.add_vertex(Vector3(x+0.5, y, z+1))

	st.set_uv(Vector2(0, 0.5))
	st.add_vertex(Vector3(x, y, z+0.5))
	
	st.set_uv(Vector2(1, 0.5))
	st.add_vertex(Vector3(x+1, y, z+0.5))
	
# Adds an outer corner, covering only 1 of 4 corners of the tile.
# if connect_x is 0, will connect to left (negative x direction), right if connect_x is 1.
# if connect_z is 0 will connect to back (negative z dirrection), forward if connect_z is 1.
func add_outer_corner_floor(x: int, y: int, z: int, connect_x: int, connect_z: int):
	# add corner tile
	st.set_uv(Vector2(connect_x, connect_z))
	st.add_vertex(Vector3(x+connect_x, y, z+connect_z))
	
	# Add the x edgevertex after z if doing so will make clockwise face up, which is tr and bl (found out heuristically idk the math)
	if (connect_x != connect_z):
		# add x edge
		st.set_uv(Vector2(connect_x, 0.5))
		st.add_vertex(Vector3(x+connect_x, y, z+0.5))
	
	# add z edge
	st.set_uv(Vector2(0.5, connect_z))
	st.add_vertex(Vector3(x+0.5, y, z+connect_z))
	
	if (connect_x == connect_z):
		# add x edge
		st.set_uv(Vector2(connect_x, 0.5))
		st.add_vertex(Vector3(x+connect_x, y, z+0.5))
	
# Adds an inner corner, covering 3 of 4 corners of the tile and leaving 1 corner uncovered.
# if connect_x is 0, will connect to left (negative x direction), right if connect_x is 1.
# if connect_z is 0 will connect to back (negative z dirrection), forward if connect_z is 1.
func add_inner_corner_floor(x: int, y: int, z: int, connect_x: int, connect_z: int):
	# add corner tile
	
	# add corner opposite of connection corner
	var add_opposite_corner = func():
		st.set_uv(Vector2(1-connect_x, 1-connect_z)) # this vertex is used in all 3 tris, is the one opposite the empty corner
		st.add_vertex(Vector3(x+1-connect_x, y, z+1-connect_z))
	
	# add corner that shares x with connection corner
	var add_x_corner = func():
		st.set_uv(Vector2(connect_x, 1-connect_z))
		st.add_vertex(Vector3(x+connect_x, y, z+1-connect_z))
		
	# add corner that shares z with connection corner
	var add_z_corner = func():
		st.set_uv(Vector2(1-connect_x, connect_z))
		st.add_vertex(Vector3(x+1-connect_x, y, z+connect_z))
	
	# add the x connection point
	var add_x_connector = func():
		st.set_uv(Vector2(connect_x, 0.5))
		st.add_vertex(Vector3(x+connect_x, y, z+0.5))
	
	# add the z connection point
	var add_z_connector = func():
		st.set_uv(Vector2(0.5, connect_z))
		st.add_vertex(Vector3(x+0.5, y, z+connect_z))
		
	# use different orientation based on the corner orientations
	if (connect_x == connect_z):
		add_opposite_corner.call()
		add_x_connector.call()
		add_z_connector.call()
		
		add_opposite_corner.call()
		add_x_corner.call()
		add_x_connector.call()
		
		add_opposite_corner.call()
		add_z_connector.call()
		add_z_corner.call()
	else:
		add_opposite_corner.call()
		add_z_connector.call()
		add_x_connector.call()
		
		add_opposite_corner.call()
		add_x_connector.call()
		add_x_corner.call()
		
		add_opposite_corner.call()
		add_z_corner.call()
		add_z_connector.call()
	
# Add a rectangle floor within the passed tile.
# x, y, z is the coordinates of the top-left corner.
# start_x, start_z, end_x and end_z define coordinates relative to the top-left corner.
# start_x should be lower than end_x and start_z should be lower than end_z; otherwise, UVs might get messed up
func add_rectangle_floor(x: int, y: int, z: int, start_x: float, start_z: float, end_x: float, end_z: float):
	# Top-left tri
	st.set_uv(Vector2(start_x, start_z))
	st.add_vertex(Vector3(x+start_x, y, z+start_z))
	
	st.set_uv(Vector2(end_x, start_z))
	st.add_vertex(Vector3(x+end_x, y, z+start_z))

	st.set_uv(Vector2(start_x, end_z))
	st.add_vertex(Vector3(x+start_x, y, z+end_z))
	
	
	# Bottom-Right tri
	st.set_uv(Vector2(end_x, end_z))
	st.add_vertex(Vector3(x+end_x, y, z+end_z))

	st.set_uv(Vector2(start_x, end_z))
	st.add_vertex(Vector3(x+start_x, y, z+end_z))
	
	st.set_uv(Vector2(end_x, start_z))
	st.add_vertex(Vector3(x+end_x, y, z+start_z))
	
	
func generate_random_height_map():
	height_map = []
	height_map.resize(dimensions.z)
	
	for z in range(dimensions.z):
		height_map[z] = []
		height_map[z].resize(dimensions.x)
		for x in range(dimensions.x):
			height_map[z][x] = rng.randi_range(0, dimensions.y);
