# res://addons/your_plugin_name/curve_viewer.gd
@tool
extends Control

@export var curve: Curve:
	set(value):
		if curve:
			curve.disconnect("changed", _on_curve_changed)
		curve = value
		if curve:
			curve.connect("changed", _on_curve_changed)
		queue_redraw()

func _ready():
	# If the curve is set in the inspector before this script runs, connect to its changes.
	if curve:
		curve.connect("changed", _on_curve_changed)

func _on_curve_changed():
	queue_redraw()


func _draw() -> void:
	if curve == null:
		return

	var point_count = 5
	var width = size.x
	var height = size.y
	
	var points := PackedVector2Array()
	
	for i in range(point_count):
		var t = float(i) / float(point_count - 1)
		var value = curve.sample(t)
		var point = Vector2(t * width, height * (1.0 - value))
		points.push_back(point)
		#print(i, ": ", point)
		
	draw_polyline(points, Color.WHITE)
