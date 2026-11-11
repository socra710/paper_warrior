extends Node2D


func _draw() -> void:
	draw_set_transform(Vector2.ZERO, 0.0, Vector2(1.0, 0.24))
	for ring in range(12, 0, -1):
		draw_circle(Vector2.ZERO, 8.0 + ring * 1.4, Color(0.12, 0.19, 0.24, 0.018), true, -1.0, true)
