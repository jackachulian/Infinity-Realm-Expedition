class_name EnemyGUI
extends Control

@onready var name_label: Label = $NameLabel
@onready var health_bar: ProgressBar = $HealthBar

var entity: Entity

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	# if entity no longer exists, it was probably defeated, free this gui as well
	if not is_instance_valid(entity):
		queue_free()
		return
	
	var camera := Camera3DTexelSnapped.instance
	var above_head_position = entity.global_transform.origin + Vector3.UP*2
	visible = not camera.is_position_behind(above_head_position)
	position = camera.unproject_position(above_head_position) + Vector2(-size.x/2, -size.y)

func connect_to_entity(entity: Entity):
	self.entity = entity
	name = entity.name+"GUI"
	name_label.text = entity.display_name
	health_bar.max_value = entity.max_hit_points
	entity.damaged.connect(on_entity_damaged)

func on_entity_damaged(damage: int):
	health_bar.value = entity.hit_points
