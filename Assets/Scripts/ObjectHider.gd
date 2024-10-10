extends RayCast3D

var collided: Node

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	var just_collided: Node = get_collider()
	if is_colliding():
		if collided == null and just_collided.has_method("hide_object"):
			print("hiding ", just_collided)
			just_collided.hide_object()
	elif just_collided == null and collided and collided.has_method("show_object"):
		print("showing ", collided)
		collided.show_object()

	collided = just_collided
