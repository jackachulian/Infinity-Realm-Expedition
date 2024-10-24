extends Node3D


func _enter_tree() -> void:
	call_deferred("free")
