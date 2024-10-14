@tool
extends Polygon2D

@export var outline_color: Color = Color.WHITE:
	set(value):
		outline_color = value
		queue_redraw()
		
@export var outline_width: int = 1:
	set(value):
		outline_width = value
		queue_redraw()

func _draw() -> void:
	draw_polyline(polygon, outline_color, outline_width, false)
	draw_line(polygon[-1], polygon[0], outline_color, outline_width, false)
	
