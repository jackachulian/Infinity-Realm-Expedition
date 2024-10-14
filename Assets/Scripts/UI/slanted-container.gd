class_name SlantedContainer
extends Container

enum AlignMode {
	START,
	CENTER,
	END
}
@export var align_mode: AlignMode

var offset: Vector2 = Vector2(32, 64);

func _notification(what):
	if what == NOTIFICATION_SORT_CHILDREN:
		sort()
		

func sort():
	var total_span := offset * (get_child_count() - 1)
	var center = size/2
	
	var current_position
	if align_mode == AlignMode.START:
		pass
	elif align_mode == AlignMode.CENTER:
		pass
	elif align_mode == AlignMode.END:
		pass
	
	for i in get_child_count():
		var child = get_child(i)
		child.p
		

func set_some_setting():
	# Some setting changed, ask for children re-sort.
	queue_sort()
