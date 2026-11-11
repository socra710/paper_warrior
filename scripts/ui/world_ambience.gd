extends Node2D

var canvas_size := Vector2.ZERO
var elapsed := 0.0


func update_world(dimensions: Vector2, time: float) -> void:
	canvas_size = dimensions
	elapsed = time
	queue_redraw()


func _draw() -> void:
	var unit := minf(canvas_size.x / 480.0, canvas_size.y / 450.0)
	var glints := [Vector2(0.37, 0.57), Vector2(0.43, 0.585), Vector2(0.49, 0.575), Vector2(0.67, 0.585)]
	for index in glints.size():
		var phase := elapsed * 1.4 + index * 1.9
		var point: Vector2 = glints[index] * canvas_size + Vector2(sin(phase) * 3.0, 0) * unit
		var light := Color(1.0, 0.99, 0.81, 0.22 + 0.4 * pow(maxf(0.0, sin(phase)), 3.0))
		draw_line(point - Vector2(3.0, 0) * unit, point + Vector2(3.0, 0) * unit, light, unit, true)
		draw_line(point - Vector2(0, 1.5) * unit, point + Vector2(0, 1.5) * unit, light, unit, true)
	for index in 2:
		var origin := Vector2(0.14, 0.69) if index == 0 else Vector2(0.86, 0.66)
		var phase := elapsed * 0.8 + index * 3.0
		var point := origin * canvas_size + Vector2(sin(phase) * 10, cos(phase * 1.4) * 7) * unit
		var spread := (1.0 + absf(sin(elapsed * 8.0 + index)) * 3.0) * unit
		var wing := Color("#f3d48f") if index == 0 else Color("#c0e8ef")
		for side in [-1, 1]:
			draw_colored_polygon(PackedVector2Array([
				point, point + Vector2(side * spread, -3 * unit),
				point + Vector2(side * spread, 2 * unit), point + Vector2(0, unit),
			]), wing)
		draw_line(point - Vector2(0, unit), point + Vector2(0, 2 * unit), Color("#426369"), unit, true)
