class_name MainTextureRect
extends TextureRect

static var instance: MainTextureRect

# Called when the node enters the scene tree for the first time.
func _enter_tree() -> void:
	instance = self
