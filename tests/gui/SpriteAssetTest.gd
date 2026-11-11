extends GdUnitTestSuite


func test_character_uses_independent_png_animations_and_nearest_filter() -> void:
	var runner := scene_runner("res://scenes/characters/warrior_sprite.tscn")
	var sprite := runner.scene() as AnimatedSprite2D
	assert_that(sprite.texture_filter).is_equal(CanvasItem.TEXTURE_FILTER_NEAREST)
	assert_that(sprite.sprite_frames.get_frame_count("idle")).is_equal(4)
	assert_that(sprite.sprite_frames.get_frame_count("walk")).is_equal(6)
	for animation in ["idle", "walk"]:
		for index in sprite.sprite_frames.get_frame_count(animation):
			var texture := sprite.sprite_frames.get_frame_texture(animation, index) as AtlasTexture
			assert_that(texture.atlas.resource_path.ends_with(".png")).is_true()
			assert_that(texture.region.size).is_equal(Vector2(96, 96))
	assert_that(sprite.scale * 96.0).is_equal(Vector2(72, 72))


func test_png_has_transparent_background_and_no_antialias_fringe() -> void:
	var png := (load("res://assets/characters/warrior/warrior_idle_walk.png") as Texture2D).get_image()
	var svg := (load("res://assets/characters/warrior/warrior_idle_walk.svg") as Texture2D).get_image()
	assert_that(png.get_size()).is_equal(Vector2i(960, 96))
	var png_alpha := _alpha_counts(png)
	var svg_alpha := _alpha_counts(svg)
	assert_that(png_alpha.x).is_greater(0)
	assert_that(png_alpha.y).is_equal(0)
	print("SPRITE_COMPARISON PNG transparent=%s partial-alpha=%s; SVG transparent=%s partial-alpha=%s" % [
		png_alpha.x, png_alpha.y, svg_alpha.x, svg_alpha.y
	])
	for index in 10:
		var frame := png.get_region(Rect2i(index * 96, 0, 96, 96))
		var bounds := frame.get_used_rect()
		assert_that(bounds.position.x > 0 and bounds.position.y > 0).is_true()
		assert_that(bounds.end.x < 96).is_true()
		assert_that(bounds.end.y).is_equal(88)


func test_reference_pose_matches_original_anatomy_and_idle_preserves_face() -> void:
	var original := FileAccess.get_file_as_string("res://assets/characters/warrior/warrior_key_art.svg")
	var defs_start := original.find("<defs>")
	var defs := original.substr(defs_start, original.find("</defs>") + 7 - defs_start)
	var anatomy_start := original.find("<g stroke=")
	var anatomy := original.substr(anatomy_start, original.find("</g>", anatomy_start) + 4 - anatomy_start)
	var reference := Image.new()
	# 동일 좌표 변환을 사용해 viewBox와 행렬의 부동소수점 경계 차이를 제외한다.
	assert_that(reference.load_svg_from_string(
		'<svg xmlns="http://www.w3.org/2000/svg" width="96" height="96" viewBox="0 0 96 96">%s<g transform="matrix(0.2857142857142857 0 0 0.2857142857142857 -18.2857142857142857 -14.2857142857142857)">%s</g></svg>' % [defs, anatomy]
	)).is_equal(OK)
	reference.convert(Image.FORMAT_RGBA8)
	for y in 96:
		for x in 96:
			var color := reference.get_pixel(x, y)
			color = Color.TRANSPARENT if color.a < 0.5 else Color(color.r, color.g, color.b, 1)
			reference.set_pixel(x, y, color)
	var png := (load("res://assets/characters/warrior/warrior_idle_walk.png") as Texture2D).get_image()
	var mismatches := 0
	var alpha_mismatches := 0
	var max_rgb_delta := 0
	for y in 96:
		for x in 96:
			var expected := reference.get_pixel(x, y)
			var actual := png.get_pixel(x, y)
			if expected.a != actual.a:
				alpha_mismatches += 1
			if expected.a > 0 and actual.a > 0:
				max_rgb_delta = maxi(max_rgb_delta, maxi(absi(expected.r8 - actual.r8), maxi(absi(expected.g8 - actual.g8), absi(expected.b8 - actual.b8))))
			if expected.a != actual.a or (expected.a > 0 and expected != actual):
				mismatches += 1
				if mismatches <= 32:
					print("REFERENCE_DELTA %s expected=%s actual=%s" % [Vector2i(x, y), expected.to_html(), actual.to_html()])
	print("REFERENCE_COMPARISON visible=%s alpha=%s max_rgb_byte_delta=%s" % [mismatches, alpha_mismatches, max_rgb_delta])
	assert_that(mismatches).is_equal(0)
	var face := reference.get_region(Rect2i(38, 26, 30, 23)).get_data()
	for index in 4:
		var offset_y := -1 if index in [1, 2] else 0
		assert_that(png.get_region(Rect2i(index * 96 + 38, 26 + offset_y, 30, 23)).get_data() == face).is_true()


func _alpha_counts(image: Image) -> Vector2i:
	image.convert(Image.FORMAT_RGBA8)
	var pixels := image.get_data()
	var counts := Vector2i.ZERO
	for index in range(3, pixels.size(), 4):
		if pixels[index] == 0:
			counts.x += 1
		elif pixels[index] != 255:
			counts.y += 1
	return counts
