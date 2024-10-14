@tool
extends VBoxContainer

# Variable to control the amount of horizontal offset.
@export var offset_multiplier: float = 0.125:
	set(value):
		offset_multiplier = value
		apply_offsets()

func _enter_tree() -> void:
	apply_offsets()
	
func _ready() -> void:
	apply_offsets()
	
func _notification(what):
	if what == NOTIFICATION_TRANSLATION_CHANGED or what == NOTIFICATION_READY or what == NOTIFICATION_SORT_CHILDREN:
		apply_offsets()

func apply_offsets():
	# Loop through each child of the VBoxContainer.
	for child in get_children():
		if child is Control:
			child.position.x = child.position.y * offset_multiplier
