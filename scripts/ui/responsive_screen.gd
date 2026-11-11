extends Control


func _ready() -> void:
	get_window().size_changed.connect(_resize_canvas)
	resized.connect(_apply_layout)
	_resize_canvas()
	call_deferred("_apply_layout")


func _resize_canvas() -> void:
	if not is_inside_tree():
		return
	var window := get_window()
	var target := Vector2i(800, 450) if window.size.x > window.size.y else Vector2i(480, 640)
	if window.content_scale_size != target:
		window.content_scale_size = target


func _apply_layout() -> void:
	if is_inside_tree():
		_update_layout()


func _update_layout() -> void:
	pass
