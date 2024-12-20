class_name Camera3DTexelSnapped
extends Camera3D

@export var snap := true
@export var snap_objects := true

static var instance: Camera3DTexelSnapped

var texel_error := Vector2.ZERO

@onready var _prev_rotation := global_rotation
@onready var _snap_space := global_transform
var _texel_size: float = 0.0

var _snap_nodes: Array[Node]
var _pre_snapped_positions: Array[Vector3]

func _enter_tree() -> void:
	if process_mode != ProcessMode.PROCESS_MODE_DISABLED:
		instance = self

func _ready() -> void:
	RenderingServer.frame_post_draw.connect(_snap_objects_revert)


func _process(_delta: float) -> void:
	# rotation changes the snap space
	if global_rotation != _prev_rotation:
		_prev_rotation = global_rotation
		_snap_space = global_transform
	var viewport = get_viewport()
	_texel_size = size / float(viewport.size.y if keep_aspect == KEEP_HEIGHT else viewport.size.x)
	# camera position in snap space
	var snap_space_position := global_position * _snap_space
	# snap!
	var snapped_snap_space_position := snap_space_position.snapped(Vector3.ONE * _texel_size)
	# how much we snapped (in snap space)
	var snap_error := snapped_snap_space_position - snap_space_position
	if snap:
		# apply camera offset as to not affect the actual transform
		h_offset = snap_error.x
		v_offset = snap_error.y
		# error in screen texels (will be used later)
		texel_error = Vector2(snap_error.x, -snap_error.y) / _texel_size
		if snap_objects:
			_snap_objects.call_deferred()
	else:
		texel_error = Vector2.ZERO
		
	if Input.is_action_just_pressed("PerspectiveToggle"):
		projection = ProjectionType.PROJECTION_ORTHOGONAL if projection == ProjectionType.PROJECTION_PERSPECTIVE else ProjectionType.PROJECTION_PERSPECTIVE


func _snap_objects() -> void:
	_snap_nodes = get_tree().get_nodes_in_group("screen_snap")
	_pre_snapped_positions.resize(_snap_nodes.size())
	for i in _snap_nodes.size():
		var node := _snap_nodes[i] as Node3D
		var pos := node.global_position
		_pre_snapped_positions[i] = pos
		var snap_space_pos := pos * _snap_space
		var snapped_snap_space_pos := snap_space_pos.snapped(Vector3(_texel_size, _texel_size, _texel_size))
		node.global_position = _snap_space * snapped_snap_space_pos


func _snap_objects_revert() -> void:
	for i in _snap_nodes.size():
		_snap_nodes[i].global_position = _pre_snapped_positions[i]
	_snap_nodes.clear()
