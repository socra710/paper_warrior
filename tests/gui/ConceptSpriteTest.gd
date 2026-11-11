extends GdUnitTestSuite

const SHEET := "res://assets/characters/warrior/concept_idle_walk_run.png"
const SPEC := "res://data/presentation/concept_warrior_animation.json"


func test_concept_has_independent_idle_walk_run_and_external_shadow() -> void:
	var runner := scene_runner("res://scenes/characters/concept_warrior.tscn")
	var sprite := runner.scene() as AnimatedSprite2D
	assert_that(sprite.name).is_equal(&"WarriorSprite")
	assert_that(sprite.texture_filter).is_equal(CanvasItem.TEXTURE_FILTER_NEAREST)
	assert_that(sprite.scale).is_equal(Vector2(0.75, 0.75))
	assert_that(sprite.autoplay).is_equal("idle")
	var regions: Dictionary = {}
	for animation in ["idle", "walk", "run"]:
		var count := 4 if animation == "idle" else 6
		assert_that(sprite.sprite_frames.get_frame_count(animation)).is_equal(count)
		assert_that(sprite.sprite_frames.get_animation_loop(animation)).is_true()
		for index in count:
			var texture := sprite.sprite_frames.get_frame_texture(animation, index) as AtlasTexture
			assert_that(texture.atlas.resource_path).is_equal(SHEET)
			assert_that(texture.region.size).is_equal(Vector2(96, 96))
			assert_that(regions.has(texture.region.position)).is_false()
			regions[texture.region.position] = true
	assert_that(sprite.sprite_frames.get_animation_speed("run")).is_greater(
		sprite.sprite_frames.get_animation_speed("walk")
	)
	var shadow := sprite.get_node("FootShadow") as Node2D
	assert_that(shadow.position).is_equal(Vector2(0, 40))
	assert_that(shadow.show_behind_parent).is_true()
	assert_that(shadow.get_script().resource_path).is_equal("res://scripts/ui/warrior_shadow.gd")


func test_concept_pixels_are_transparent_palette_limited_and_unclipped() -> void:
	var image := _sheet_image()
	var spec: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(SPEC))
	assert_that(image.get_size()).is_equal(Vector2i(1536, 96))
	assert_that(spec["palette"].size()).is_equal(14)
	var palette: Dictionary = {}
	for value in spec["palette"].values():
		palette[Color(value).to_rgba32()] = true
	var transparent := 0
	var invalid := 0
	for y in image.get_height():
		for x in image.get_width():
			var color := image.get_pixel(x, y)
			if color.a8 == 0:
				transparent += 1
				if color.to_rgba32() != 0:
					invalid += 1
			elif color.a8 != 255 or not palette.has(color.to_rgba32()):
				invalid += 1
	assert_that(transparent).is_greater(0)
	assert_that(invalid).is_equal(0)
	var index := 0
	for animation in spec["animation_order"]:
		for pose in spec["animations"][animation]["frames"]:
			var frame := image.get_region(Rect2i(index * 96, 0, 96, 96))
			var bounds := frame.get_used_rect()
			assert_that(bounds.position.x > 1 and bounds.position.y > 1).is_true()
			assert_that(bounds.end.x < 94 and bounds.end.y <= 88).is_true()
			if not pose["flight"]:
				assert_that(bounds.end.y).is_equal(88)
			else:
				assert_that(animation).is_equal("run")
				assert_that(bounds.end.y).is_less(88)
			index += 1


func test_face_is_rigid_cheerful_and_hips_remain_inside_the_hem() -> void:
	var image := _sheet_image()
	var spec: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(SPEC))
	var face: Dictionary = spec["face_validation"]
	var roi: Array = face["roi"]
	var reference_rect := Rect2i(int(roi[0]), int(roi[1]), int(roi[2]), int(roi[3]))
	var reference := image.get_region(reference_rect).get_data()
	var ink := Color(spec["palette"]["ink"])
	var eyes: Array = face["eyes"]
	assert_that(int(eyes[1][1]) - int(eyes[0][1])).is_equal(1)
	var source := FileAccess.get_file_as_string("res://assets/characters/warrior/concept_parts.svg")
	var start := source.find("<defs>")
	var defs := source.substr(start, source.find("</defs>") + 7 - start)
	var index := 0
	for animation in spec["animation_order"]:
		for pose in spec["animations"][animation]["frames"]:
			var parts: Dictionary = pose["parts"]
			var head: Array = parts["head"]
			assert_that(parts["face"]).is_equal(head)
			var face_origin := reference_rect.position + Vector2i(index * 96 + int(head[0]), int(head[1]))
			assert_that(image.get_region(Rect2i(face_origin, reference_rect.size)).get_data() == reference).is_true()
			for eye in eyes:
				for eye_x in range(int(eye[0]), int(eye[0]) + int(eye[2])):
					for eye_y in range(int(eye[1]), int(eye[1]) + int(eye[3])):
						assert_that(image.get_pixel(index * 96 + eye_x + int(head[0]), eye_y + int(head[1]))).is_equal(ink)
			for sample in face["smile_ink_samples"]:
				assert_that(image.get_pixel(index * 96 + int(sample[0]) + int(head[0]), int(sample[1]) + int(head[1]))).is_equal(ink)
			for sample in face["paper_samples"]:
				var paper := image.get_pixel(index * 96 + int(sample[0]) + int(head[0]), int(sample[1]) + int(head[1]))
				assert_that(paper.a8).is_equal(255)
				assert_that(paper).is_not_equal(ink)
			var hip: Array = pose["hip_offset"]
			for hip_x in [39, 57]:
				var x: int = index * 96 + int(hip_x) + int(hip[0])
				var y := 72 + int(hip[1])
				for seam_y in range(y - 2, y + 7):
					assert_that(image.get_pixel(x, seam_y).a8).is_equal(255)
			assert_that(parts["left_thigh"]).is_equal([hip[0], hip[1], 0.0])
			assert_that(parts["right_thigh"]).is_equal([hip[0], hip[1], 0.0])
			var torso := _part_mask("torso", parts, spec, defs)
			for side in ["left", "right"]:
				var thigh := _part_mask(side + "_thigh", parts, spec, defs)
				var boot := _part_mask(side + "_boot", parts, spec, defs)
				assert_that(_mask_overlap(torso, thigh)).is_greater_equal(16)
				assert_that(_mask_overlap(thigh, boot)).is_greater_equal(12)
				if side == "left":
					var boot_pose: Array = parts["left_boot"]
					assert_that(boot.get_pixel(30 + int(boot_pose[0]), 86 + int(boot_pose[1])).a).is_greater_equal(0.5)
					var fold := boot.get_pixel(33 + int(boot_pose[0]), 85 + int(boot_pose[1]))
					assert_that(fold.a).is_greater_equal(0.5)
					assert_that(fold).is_not_equal(ink)
			assert_that(parts["left_arm"]).is_equal(parts["sword"])
			assert_that(parts["right_arm"]).is_equal(parts["shield"])
			index += 1


func test_walk_and_run_have_distinct_strides_bobs_and_cape_follow_through() -> void:
	var spec: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(SPEC))
	var stats: Dictionary = {}
	for animation in spec["animation_order"]:
		var feet: Dictionary = {}
		var bobs: Dictionary = {}
		var cape: Dictionary = {}
		var max_stride := 0
		var flight := 0
		for pose in spec["animations"][animation]["frames"]:
			var parts: Dictionary = pose["parts"]
			var left: Array = parts["left_boot"]
			var right: Array = parts["right_boot"]
			feet[str([left, right])] = true
			bobs[parts["head"][1]] = true
			cape[str(parts["cape"])] = true
			max_stride = maxi(max_stride, absi(int(left[0]) - int(right[0])))
			if pose["flight"]:
				flight += 1
			if animation == "idle":
				assert_that(left).is_equal([0.0, 0.0, 0.0])
				assert_that(right).is_equal([0.0, 0.0, 0.0])
			if animation == "walk":
				assert_that(mini(int(left[1]), int(right[1]))).is_less_equal(0)
				assert_that(maxi(int(left[1]), int(right[1]))).is_equal(0)
		stats[animation] = {"stride": max_stride, "feet": feet.size(), "bob": bobs.size(), "cape": cape.size(), "flight": flight}
	assert_that(stats["idle"]["bob"]).is_greater(1)
	assert_that(stats["walk"]["feet"]).is_greater(3)
	assert_that(stats["walk"]["stride"]).is_greater(stats["idle"]["stride"])
	assert_that(stats["run"]["stride"]).is_greater(stats["walk"]["stride"])
	assert_that(stats["run"]["bob"]).is_greater(stats["walk"]["bob"])
	assert_that(stats["run"]["cape"]).is_greater(stats["idle"]["cape"])
	assert_that(stats["run"]["flight"]).is_greater(0)


func _part_mask(part: String, parts: Dictionary, spec: Dictionary, defs: String) -> Image:
	var pose: Array = parts[part]
	var pivot: Array = spec["part_pivots"][part]
	var mask := Image.new()
	assert_that(mask.load_svg_from_string(
		'<svg xmlns="http://www.w3.org/2000/svg" width="96" height="96">%s<use href="#%s" transform="translate(%d %d) rotate(%d %d %d)"/></svg>' % [
			defs, part, int(pose[0]), int(pose[1]), int(pose[2]), int(pivot[0]), int(pivot[1])
		]
	)).is_equal(OK)
	return mask


func _sheet_image() -> Image:
	var image := Image.new()
	assert_that(image.load_png_from_buffer(FileAccess.get_file_as_bytes(SHEET))).is_equal(OK)
	return image


func _mask_overlap(first: Image, second: Image) -> int:
	var count := 0
	for y in 96:
		for x in 96:
			if first.get_pixel(x, y).a >= 0.5 and second.get_pixel(x, y).a >= 0.5:
				count += 1
	return count
