@tool
extends MeshInstance3D

# Dimensions of the terrain.
# x = x length
# y = max height.
# z = z length
var dimensions: Vector3i = Vector3i(10, 1, 10):
	set(new_dimensions):
		dimensions = new_dimensions
		generate_height_map()
		generate_mesh()
		

var height_map = []

var rng = RandomNumberGenerator.new()

var st: SurfaceTool

func _ready() -> void:
	generate_height_map()
	generate_mesh()

	
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
					
				# If all corners are equal or higher, put a full floor here, as no corners are lower so floor covers full tile.
				# Part of the floor may be under walls but this is okay as they will be fully underground and not visible.
				# It is already guaranteed the floor will be at least partially visible, because at least one of its corners are at the current height,
				# as the code block will not reach this point if all four corners are higher.
				if (tl or tlh) and (tr or tlh) and (bl or blh) and (br or blh):
					add_full_floor(x, y, z)
					continue
					
				# If a corner is equal but the adjacent corners are not, add a corner floor there.
				# This means two corners might be added on a single tile. this is fine, they shouldn't overlap, they are in their own corners
				if tl and not (tr or bl):
					add_outer_corner_floor(x, y, z, 0, 0)
				if tr and not (tl or br):
					add_outer_corner_floor(x, y, z, 1, 0)
				if bl and not (tl or br):
					add_outer_corner_floor(x, y, z, 0, 1)
				if br and not (tr or bl):
					add_outer_corner_floor(x, y, z, 1, 1)
					
				# If one side is equal and other side is not, add a half floor along that edge.
				if (tl and tr) and not (bl and br):
					add_rectangle_floor(x, y, z, 0, 0, 1, 0.5)
				if (tl and bl) and not (tr and br):
					add_rectangle_floor(x, y, z, 0, 0, 0.5, 1)
				if (bl and br) and not (tl and tr):
					add_rectangle_floor(x, y, z, 0, 0.5, 1, 1)
				if (tr and br) and not (tl and bl):
					add_rectangle_floor(x, y, z, 0.5, 0, 1, 1)

	# Commit to a mesh.
	mesh = st.commit()
	
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
	
# Adds an outer corner, covering only 1 of 4 corners of the tile.
# if connect_x is 0, will connect to left (negative x direction), right if connect_x is 1.
# if connect_z is 0 will connect to back (negative z dirrection), forward if connect_z is 1.
func add_outer_corner_floor(x: int, y: int, z: int, connect_x: int, connect_z: int):
	# add corner tile
	st.set_uv(Vector2(connect_x, connect_z))
	st.add_vertex(Vector3(x+connect_x, y, z+connect_z))
	
	# add x edge
	st.set_uv(Vector2(connect_x, 0.5))
	st.add_vertex(Vector3(x+connect_x, y, z+0.5))
	
	# add z edge
	st.set_uv(Vector2(0.5, connect_z))
	st.add_vertex(Vector3(x+0.5, y, z+connect_z))
	
# Add a rectangle floor within the passed tile.
# x, y, z is the coordinates of the top-left corner.
# start_x, start_z, end_x and end_z define coordinates relative to the top-left corner.
# start_x should be lower than end_x and start_z should be lower than end_z; otherwise, UVs might get messed up
func add_rectangle_floor(x: int, y: int, z: int, start_x: int, start_z: int, end_x: int, end_z: int):
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
	
	
func generate_height_map():
	height_map = []
	height_map.resize(dimensions.z)
	
	for z in range(dimensions.z):
		height_map[z] = []
		height_map[z].resize(dimensions.x)
		for x in range(dimensions.x):
			height_map[z][x] = rng.randi_range(0, dimensions.y);
