class_name GameplayBaseNode
extends Node3D

@export var level: Node3D
@export var first_level_scene: PackedScene

func _ready() -> void:
	if not level:
		if not first_level_scene:
			printerr("no first level defined!")
			return
			
		# this may be quite an expensive call in the future, so may want to add a loading screen and load in the background
		level = first_level_scene.instantiate()
		
		add_child(level)
		move_child(level, 2) # after subviewport and after player
