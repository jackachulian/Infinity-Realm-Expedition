extends GenericInput
class_name BasicAIInput

var target: Node3D

@onready var entity: Entity = $".."

func _ready():
	target = $"../../infinity"
	
	if not target:
		print(name+": could not find player to track")

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	# move towards target
	if target:
		direction = (target.global_position - global_position)
		direction.y = 0
		direction = direction.normalized()
