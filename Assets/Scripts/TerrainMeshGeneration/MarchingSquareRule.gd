class_name MarchingSquareRule
extends Node

# NOTE: all SMOOTH points below NORMAL points should become NORMAL to prevent floating geometry
enum PointState {
	NONE, # no point here at all
	SMOOTH, # exactly 1 adjacent point.
	NORMAL, # either 0 or 2+ adjacent points.
}

## State of points that must match for this rule to apply.
@export var top_left_state: PointState
@export var top_right_state: PointState
@export var bottom_left_state: PointState
@export var bottom_right_state: PointState

# NOTE: Could make this some kind of enum representing if this can be rotated 1, 2, or 4 times with no extra computation, but want to keep the editor simple, 
# and it's barely any extra computation, since not many rules will only have 180 degree rotational symmetry, majority will have 90.
## If this rule can be rotated. If so, all 4 possible rotations will be checked for validity. should be false for rotationally symmetric rules.
@export var can_be_rotated: bool = true

## Contains the xz coordinates of all floor triangles that will be added.
## Length must be a multiple of 3.
## Make sure points go in counter-clockwise order.
@export var floor_triangles: Array[Vector3]

## XZ points along which vertical walls should be created.
@export var wall_strip: Array[Vector2]

## Returns true if this rule tile can be applied to the passed corner states.
## top_left, top_right, bottom_left and bottom_right are the amount of adjacent points to each points, or -1 if there is not a point in that position.
## If can_rotate is true, the marching squares terrain will test this function 1 for each of the 4 possible rotations.
## If a valid rotation is found (when this returns true), then generate_tris will be called with the passing rotation.
func check_valid(top_left: int, top_right: int, bottom_left: int, bottom_right: int) -> bool:
	if not check_state(top_left, top_left_state): return false
	if not check_state(top_right, top_right_state): return false
	if not check_state(bottom_left, bottom_left_state): return false
	if not check_state(bottom_right, bottom_right_state): return false
	
	return true
	
func check_state(adjacent_points: int, state: PointState) -> bool:
	match state:
		PointState.NONE:
			return adjacent_points == -1
		PointState.NORMAL:
			return adjacent_points == 0 or adjacent_points >= 2
		PointState.SMOOTH:
			return adjacent_points == 1
	
	return false

# things stored here for code non-redunancy reasons
# Surface tool being used to generate the current mesh. 
var st: SurfaceTool
var location: Vector3i # y component unused but makes code less confusing by using z instead of y
var rotation: int

## Generates the mesh in the passed SurfaceTool.
## x and z are the coordinates of the tile.
## tl, tr, bl and br are the heights of the co-planar points (points without a wall bewteen them).
## tla, tra, bla, and bra are the heights of the next point above each of the 4 points, if there is a point above them, otherwise the same height as the point.
## rotation represents the amount of counter-clockwise rotations until it is in the correct orientation based on check_valid
func generate(st: SurfaceTool, x: int, z: int, 
tl: float, tr: float, bl: float, br: float, 
tla: float, tra: float, bla: float, bra: float, 
rotation: int):
	self.st = st
	self.location = Vector3i(x, tl, z)
	self.rotation = rotation
	
	if len(floor_triangles) % 3 != 0:
		print_debug(name+": vertex count on floor_triangles is not a multiple of 3")
	
	for point in floor_triangles:
		# determine the point of the height by lerping on both axes
		# possible visual improvement: 
		var height = get_lerped_height(tl, tr, bl, br, point.x, point.y)
		add_point(point.x, height, point.y)
		
	if len(wall_strip) > 1:
		var left_point = wall_strip[0]
		var left_height = get_lerped_height(tl, tr, bl, br, left_point.x, left_point.y)
		var left_above_height = get_lerped_height(tla, tra, bla, bra, left_point.x, left_point.y)
			
		for i in range(1, len(wall_strip) - 1):
			var right_wall_point = wall_strip[i]
			
			var right_point = wall_strip[i]
			var right_height = get_lerped_height(tl, tr, bl, br, right_point.x, right_point.y)
			var right_above_height = get_lerped_height(tla, tra, bla, bra, right_point.x, right_point.y)
				
			if left_height != left_above_height:
				add_point(left_point.x, left_height, left_point.y)
				add_point(left_point.x, left_above_height, left_point.y)
				add_point(right_point.x, right_height, right_point.y)
			
			if right_height != right_above_height:
				add_point(right_point.x, right_above_height, right_point.y)
				add_point(right_point.x, right_height, right_point.y)
				add_point(left_point.x, left_above_height, left_point.y)
			
			# send right point to left; new right will be assigned at start of next iteration
			left_point = right_point
			left_height = right_height
			left_above_height = right_above_height
			
## tl, tr, bl, br - the heights of the 4 corners of the tile.
## x, z - the coordinate within the tile that this height is for. will be used to blend heights of surrounding points
func get_lerped_height(tl: float, tr: float, bl: float, br: float, x: int, z: int) -> float:
	var top_height = lerpf(tl, tr, x)
	var bottom_height = lerpf(bl, br, x)
	var height = lerpf(top_height, bottom_height, z)
	return height
			
## Adds a point to the mesh.
## X and Z are relative to the tile. (0,0)=top left, (0,1)=top right, (0,1)=bottom left, (1,1)=bottom right
## Y is the total height from the bottom of the terrain.
func add_point(x: float, y: float, z: float):
	# rotate counter_clockwise appropriate amount of times to rotate this point t the correct value
	var temp_x
	for _v in range(rotation):
		temp_x = x
		x = y
		y = 1 - temp_x
	
	st.set_uv(Vector2(x, z))
	st.add_vertex(Vector3(location.x + x, y, location.z + z))
