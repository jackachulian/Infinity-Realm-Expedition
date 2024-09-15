extends Node3D

@export var follow: Node3D

func _ready():
	if not follow:
		set_process(false)

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	global_position = follow.global_position
