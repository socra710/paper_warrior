extends SceneTree


func _initialize() -> void:
	var image := Image.new()
	var error := image.load_svg_from_string(FileAccess.get_file_as_string("res://assets/ui/paper_fold.svg"))
	if error != OK:
		push_error("종이접기 마스터를 읽지 못했습니다: %s" % error)
		quit(1)
		return
	image.convert(Image.FORMAT_RGBA8)
	for y in image.get_height():
		for x in image.get_width():
			var color := image.get_pixel(x, y)
			image.set_pixel(x, y, Color.TRANSPARENT if color.a < 0.5 else Color(color.r, color.g, color.b, 1))
	error = image.save_png("res://assets/ui/paper_fold.png")
	if error != OK:
		push_error("종이접기 PNG를 저장하지 못했습니다: %s" % error)
	quit(0 if error == OK else 1)
