extends SceneTree


const MASTER_PATH := "res://assets/backgrounds/paper_forest_diorama/source/paper_forest_parts.svg"
const OUTPUT_DIR := "res://assets/backgrounds/paper_forest_diorama/"
const CUTOUT_PATH := OUTPUT_DIR + "source/cutouts_master.png"
const GRID_PARTS := [
	"cloud", "mountain", "pine", "round_tree",
	"castle", "windmill", "bush", "flower",
	"rock", "fence", "river", "bridge",
]
# The atlas rows overlap slightly: tree bases dip below the nominal one-third line.
const ROW_BOUNDS := [
	Vector2(0.0, 398.0 / 1086.0),
	Vector2(390.0 / 1086.0, 748.0 / 1086.0),
	Vector2(750.0 / 1086.0, 1.0),
]
const PARTS := {
	"sky": Vector2i(480, 640),
	"cloud": Vector2i(168, 78),
	"mountain": Vector2i(240, 176),
	"castle": Vector2i(184, 218),
	"windmill": Vector2i(150, 196),
	"pine": Vector2i(100, 146),
	"round_tree": Vector2i(112, 126),
	"river": Vector2i(220, 92),
	"bridge": Vector2i(184, 92),
	"flower": Vector2i(54, 62),
	"rock": Vector2i(92, 54),
	"bush": Vector2i(116, 72),
	"fence": Vector2i(164, 82),
}


func _initialize() -> void:
	var master := FileAccess.get_file_as_string(MASTER_PATH)
	var definitions_start := master.find("<defs>")
	var definitions_end := master.find("</defs>")
	if definitions_start < 0 or definitions_end < 0:
		push_error("종이 숲 SVG 마스터에 공통 부품 정의가 없습니다.")
		quit(1)
		return
	var definitions := master.substr(definitions_start, definitions_end + 7 - definitions_start)
	var atlas := Image.new()
	if atlas.load(CUTOUT_PATH) != OK:
		push_error("종이 숲 원본 컷아웃 시트를 읽지 못했습니다.")
		quit(1)
		return
	atlas.convert(Image.FORMAT_RGBA8)
	var alpha_counts := Vector3i.ZERO
	for y in atlas.get_height():
		for x in atlas.get_width():
			var alpha := atlas.get_pixel(x, y).a
			if alpha == 0.0:
				alpha_counts.x += 1
			elif alpha < 16.0 / 255.0:
				alpha_counts.y += 1
			else:
				alpha_counts.z += 1
	print("Atlas %s; alpha zero / low (1..15) / other: %s" % [
		atlas.get_size(), alpha_counts
	])
	var failures := 0
	for part_name: String in PARTS:
		var dimensions: Vector2i = PARTS[part_name]
		var image := Image.new()
		var error := OK
		if part_name == "sky":
			error = image.load_svg_from_string(_make_svg(definitions, part_name, dimensions))
		else:
			var index := GRID_PARTS.find(part_name)
			var column := index % 4
			var row := index / 4
			var left := int(column * atlas.get_width() / 4.0)
			var top := roundi(ROW_BOUNDS[row].x * atlas.get_height())
			var right := int((column + 1) * atlas.get_width() / 4.0)
			var bottom := roundi(ROW_BOUNDS[row].y * atlas.get_height())
			var cell := atlas.get_region(Rect2i(left, top, right - left, bottom - top))
			image = _fit_cutout(_clean_cell(cell, part_name), dimensions)
		if error != OK or image.is_empty():
			push_error("종이 숲 부품 '%s'의 SVG 래스터화에 실패했습니다: %s" % [part_name, error])
			failures += 1
			continue
		image.convert(Image.FORMAT_RGBA8)
		if image.get_size() != dimensions:
			push_error("종이 숲 부품 '%s' 크기 불일치: %s (기대 %s)" % [
				part_name, image.get_size(), dimensions
			])
			failures += 1
			continue
		error = image.save_png(OUTPUT_DIR + part_name + ".png")
		if error != OK:
			push_error("종이 숲 부품 '%s' PNG 저장 실패: %s" % [part_name, error])
			failures += 1
			continue
		print("Generated %s.png (%d x %d)" % [part_name, dimensions.x, dimensions.y])
	quit(1 if failures else 0)


func _clean_cell(cell: Image, part_name: String) -> Image:
	var width := cell.get_width()
	var height := cell.get_height()
	var visited := PackedByteArray()
	visited.resize(width * height)
	var largest := PackedInt32Array()
	for y in height:
		for x in width:
			var offset := y * width + x
			if visited[offset] or cell.get_pixel(x, y).a < 0.38:
				continue
			var component := PackedInt32Array([offset])
			visited[offset] = 1
			var cursor := 0
			while cursor < component.size():
				var current := component[cursor]
				cursor += 1
				var current_x := current % width
				var current_y := current / width
				for dy in range(-1, 2):
					for dx in range(-1, 2):
						var nx := current_x + dx
						var ny := current_y + dy
						if nx < 0 or ny < 0 or nx >= width or ny >= height:
							continue
						var neighbor := ny * width + nx
						if not visited[neighbor] and cell.get_pixel(nx, ny).a >= 0.38:
							visited[neighbor] = 1
							component.append(neighbor)
			if component.size() > largest.size():
				largest = component
	var retained := PackedByteArray()
	retained.resize(width * height)
	# Keep the connected silhouette and its antialiased edge, not detached matte speckles.
	for offset: int in largest:
		var x := offset % width
		var y := offset / width
		for dy in range(-2, 3):
			for dx in range(-2, 3):
				var nx := x + dx
				var ny := y + dy
				if nx >= 0 and ny >= 0 and nx < width and ny < height:
					retained[ny * width + nx] = 1
	var removed := 0
	for y in height:
		for x in width:
			var color := cell.get_pixel(x, y)
			if not retained[y * width + x] or color.a < 16.0 / 255.0:
				if color.a > 0.0:
					removed += 1
				cell.set_pixel(x, y, Color(0, 0, 0, 0))
			else:
				color.a = minf(color.a * 255.0 / 252.0, 1.0)
				cell.set_pixel(x, y, color)
	var bounds := cell.get_used_rect()
	print("Trim %s: %s; removed %d detached/low-alpha pixels" % [
		part_name, bounds, removed
	])
	return cell.get_region(bounds)


func _fit_cutout(cutout: Image, dimensions: Vector2i) -> Image:
	var scale_factor := minf(
		float(dimensions.x - 4) / cutout.get_width(),
		float(dimensions.y - 4) / cutout.get_height()
	)
	var fitted_size := Vector2i(
		maxi(1, roundi(cutout.get_width() * scale_factor)),
		maxi(1, roundi(cutout.get_height() * scale_factor))
	)
	cutout.premultiply_alpha()
	cutout.resize(fitted_size.x, fitted_size.y, Image.INTERPOLATE_LANCZOS)
	for y in cutout.get_height():
		for x in cutout.get_width():
			var color := cutout.get_pixel(x, y)
			if color.a < 2.0 / 255.0:
				color = Color(0, 0, 0, 0)
			else:
				color.r = clampf(color.r / color.a, 0.0, 1.0)
				color.g = clampf(color.g / color.a, 0.0, 1.0)
				color.b = clampf(color.b / color.a, 0.0, 1.0)
			cutout.set_pixel(x, y, color)
	var canvas := Image.create_empty(dimensions.x, dimensions.y, false, Image.FORMAT_RGBA8)
	var destination := Vector2i((dimensions.x - fitted_size.x) / 2, (dimensions.y - fitted_size.y) / 2)
	canvas.blit_rect(cutout, Rect2i(Vector2i.ZERO, fitted_size), destination)
	return canvas


func _make_svg(definitions: String, part_name: String, dimensions: Vector2i) -> String:
	var size := "%d" % dimensions.x
	var height := "%d" % dimensions.y
	return (
		'<svg xmlns="http://www.w3.org/2000/svg" width="%spx" height="%spx" viewBox="0 0 %s %s">'
		% [size, height, size, height]
		+ definitions
		+ '<use href="#%s" x="0" y="0" width="%s" height="%s"/>'
		% [part_name, size, height]
		+ "</svg>"
	)
