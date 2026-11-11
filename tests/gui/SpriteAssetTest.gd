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
			assert_that(texture.region.size).is_equal(Vector2(48, 48))


func test_png_has_transparent_background_and_no_antialias_fringe() -> void:
	var png := (load("res://assets/characters/warrior/warrior_idle_walk.png") as Texture2D).get_image()
	var svg := (load("res://assets/characters/warrior/warrior_idle_walk.svg") as Texture2D).get_image()
	assert_that(png.get_size()).is_equal(Vector2i(480, 48))
	var png_alpha := _alpha_counts(png)
	var svg_alpha := _alpha_counts(svg)
	assert_that(png_alpha.x).is_greater(0)
	assert_that(png_alpha.y).is_equal(0)
	print("SPRITE_COMPARISON PNG transparent=%s partial-alpha=%s; SVG transparent=%s partial-alpha=%s" % [
		png_alpha.x, png_alpha.y, svg_alpha.x, svg_alpha.y
	])
	for index in 10:
		var frame := png.get_region(Rect2i(index * 48, 0, 48, 48))
		assert_that(frame.get_used_rect().size.x > 0 and frame.get_used_rect().size.y > 0).is_true()


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
