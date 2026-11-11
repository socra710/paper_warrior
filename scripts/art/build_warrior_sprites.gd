extends SceneTree

const PARTS_PATH := "res://assets/characters/warrior/warrior_parts.svg"
const DATA_PATH := "res://data/presentation/warrior_animation.json"
const SVG_PATH := "res://assets/characters/warrior/warrior_idle_walk.svg"
const PNG_PATH := "res://assets/characters/warrior/warrior_idle_walk.png"
const SCENE_PATH := "res://scenes/characters/warrior_sprite.tscn"
const ORIGINAL_RENDER_ORDER := [
	"left_leg", "right_leg", "torso", "left_arm", "right_arm",
	"head", "face", "sword", "shield",
]


func _initialize() -> void:
	quit(_generate())


func _generate() -> int:
	if not FileAccess.file_exists(PARTS_PATH):
		return _fail("Missing shared warrior parts: %s" % PARTS_PATH)
	if not FileAccess.file_exists(DATA_PATH):
		return _fail("Missing warrior animation data: %s" % DATA_PATH)

	var parsed: Variant = JSON.parse_string(FileAccess.get_file_as_string(DATA_PATH))
	if typeof(parsed) != TYPE_DICTIONARY:
		return _fail("Warrior animation data must be a JSON object")
	var spec: Dictionary = parsed
	if int(spec.get("schema_version", 0)) != 1:
		return _fail("Unsupported warrior animation schema version")

	var frame_size: Dictionary = spec.get("frame_size", {})
	var frame_width := int(frame_size.get("width", 0))
	var frame_height := int(frame_size.get("height", 0))
	var anchor: Dictionary = spec.get("anchor", {})
	var center_x := int(anchor.get("center_x", -1))
	var baseline_y := int(anchor.get("ground_baseline_y", -1))
	if spec.get("reference_profile", "") != "original_geometry_96":
		return _fail("Expected the explicit original_geometry_96 reference profile")
	if spec.get("source_view_box", []) != [64.0, 50.0, 336.0, 336.0]:
		return _fail("Original geometry must use source viewBox 64 50 336 336")
	if frame_width != 96 or frame_height != 96:
		return _fail("Original-reference warrior frames must remain 96x96")
	if center_x != 48 or baseline_y != 88:
		return _fail("Warrior center and ground baseline must remain x=48, y=88")

	var animations: Dictionary = spec.get("animations", {})
	var animation_order: Array = spec.get("animation_order", [])
	var render_order: Array = spec.get("render_order", [])
	var part_origins: Dictionary = spec.get("part_origins", {})
	if animation_order != ["idle", "walk"]:
		return _fail("Only the idle and walk animations are defined by this source")
	if render_order.is_empty():
		return _fail("Warrior part render order is empty")
	if not _has_unique_names(render_order):
		return _fail("Warrior part render order contains duplicate names")
	if render_order != ORIGINAL_RENDER_ORDER:
		return _fail("Shared parts must preserve the original anatomy draw order")
	if part_origins.size() != render_order.size():
		return _fail("Each shared part needs one named pivot/origin")
	for part_name in render_order:
		if not part_origins.has(part_name):
			return _fail("Part origin is missing for %s" % str(part_name))

	var total_frames := 0
	for animation_name in animation_order:
		if not animations.has(animation_name):
			return _fail("Missing animation data for %s" % animation_name)
		var animation: Dictionary = animations[animation_name]
		if int(animation.get("fps", 0)) <= 0 or typeof(animation.get("loop")) != TYPE_BOOL:
			return _fail("Animation %s needs a positive rate and loop flag" % animation_name)
		var frames: Array = animation.get("frames", [])
		if frames.is_empty():
			return _fail("Animation %s has no frames" % animation_name)
		total_frames += frames.size()
	if total_frames != int(spec.get("frame_count", -1)):
		return _fail("Animation frame total does not match frame_count")
	if animations["idle"]["frames"].size() != 4 or animations["walk"]["frames"].size() != 6:
		return _fail("Expected four idle frames followed by six walk frames")
	if int(animations["idle"]["fps"]) != 4 or int(animations["walk"]["fps"]) != 8:
		return _fail("Expected idle at 4 fps and walk at 8 fps")
	if not animations["idle"]["loop"] or not animations["walk"]["loop"]:
		return _fail("Idle and walk animations must loop")
	var node: Dictionary = spec.get("node", {})
	if str(node.get("name", "")) != "WarriorSprite":
		return _fail("Warrior scene root must be named WarriorSprite")
	if str(node.get("default_animation", "")) != "idle":
		return _fail("WarriorSprite must autoplay idle")
	if node.get("scale", []) != [0.75, 0.75]:
		return _fail("Original-reference WarriorSprite scale must remain 0.75 (72px)")

	var parts_source := FileAccess.get_file_as_string(PARTS_PATH)
	var defs_start := parts_source.find("<defs>")
	var defs_close := parts_source.find("</defs>", defs_start)
	if defs_start < 0 or defs_close < 0:
		return _fail("Shared warrior parts SVG must contain a defs section")
	var defs := parts_source.substr(defs_start, defs_close + 7 - defs_start)
	var palette: Dictionary = spec.get("palette", {})
	var palette_order: Array = spec.get("palette_order", [])
	if palette.is_empty():
		return _fail("Warrior palette is empty")
	if palette_order.size() != palette.size() or not _has_unique_names(palette_order):
		return _fail("Palette order must name every palette color exactly once")
	var palette_values: Dictionary = {}
	for palette_name in palette:
		var color := str(palette[palette_name]).to_lower()
		if not defs.contains("=\"%s\"" % color):
			return _fail("Palette color %s is not used by the shared parts" % color)
		palette_values[color] = true
	for palette_name in palette_order:
		if not palette.has(palette_name):
			return _fail("Palette order contains an unknown color %s" % str(palette_name))

	var fill_regex := RegEx.new()
	if fill_regex.compile("(?:fill|stroke|stop-color)=\"(#[0-9a-fA-F]{6})\"") != OK:
		return _fail("Could not compile SVG palette validation")
	for color_match in fill_regex.search_all(defs):
		if not palette_values.has(color_match.get_string(1).to_lower()):
			return _fail("Shared parts use an undefined palette color")
	for part_name in render_order:
		if not defs.contains("id=\"%s\"" % str(part_name)):
			return _fail("Shared parts are missing group %s" % str(part_name))
	for animation_name in animation_order:
		for frame in animations[animation_name]["frames"]:
			if typeof(frame) != TYPE_DICTIONARY or typeof(frame.get("parts")) != TYPE_DICTIONARY:
				return _fail("Every animation frame must contain a part-position object")
			var frame_parts: Dictionary = frame["parts"]
			if frame_parts.size() != render_order.size():
				return _fail("Every animation frame must position each shared part exactly once")
			for part_name in render_order:
				if not frame_parts.has(part_name):
					return _fail("Animation frame is missing part position %s" % str(part_name))
				var position: Variant = frame_parts[part_name]
				if typeof(position) != TYPE_ARRAY or position.size() != 2:
					return _fail("Part positions must be two-element integer translations")
				if not _is_integer_translation(position[0]) or not _is_integer_translation(position[1]):
					return _fail("Part positions must be integer translations")
				if abs(float(position[0])) > 2 or float(position[1]) < -1 or float(position[1]) > 0:
					return _fail("Reference animation permits only small translations, never geometry changes")
				if animation_name == "idle":
					if position[0] != 0:
						return _fail("Idle motion must remain a vertical 0/1px micro translation")
					if part_name in ["left_leg", "right_leg"] and position != [0.0, 0.0]:
						return _fail("Idle feet must remain planted")
			if not frame.get("variants", {}).is_empty():
				return _fail("Original-reference animation does not permit face or part variants")
			if frame_parts["face"] != frame_parts["head"] or frame_parts["head"] != frame_parts["torso"]:
				return _fail("The original face, head and torso must move together")
			if frame_parts["sword"] != frame_parts["left_arm"] or frame_parts["shield"] != frame_parts["right_arm"]:
				return _fail("Equipment must move with its gripping arm")
			if frame_parts["left_leg"][1] != 0 and frame_parts["right_leg"][1] != 0:
				return _fail("Every frame must keep one foot at the original ground baseline")

	var svg := _build_svg(spec, defs, animations, animation_order, render_order, total_frames)
	var write_error := _write_text(SVG_PATH, svg)
	if write_error != OK:
		return _fail("Could not write generated SVG (error %d)" % write_error)

	var image := Image.new()
	var load_error := image.load_svg_from_string(svg, 1.0)
	if load_error != OK:
		return _fail("Could not rasterize generated SVG (error %d)" % load_error)
	if image.get_width() != frame_width * total_frames or image.get_height() != frame_height:
		return _fail("Generated SVG raster has unexpected dimensions")
	_finalize_raster(image)
	for frame_index in range(total_frames):
		var bounds := image.get_region(Rect2i(frame_index * frame_width, 0, frame_width, frame_height)).get_used_rect()
		if bounds.size == Vector2i.ZERO or bounds.position.x <= 0 or bounds.position.y <= 0:
			return _fail("Frame %d is empty or touches the top/left frame boundary" % frame_index)
		if bounds.end.x >= frame_width or bounds.end.y != baseline_y:
			return _fail("Frame %d must fit the frame and retain ground baseline %d" % [frame_index, baseline_y])
	var png_path := ProjectSettings.globalize_path(PNG_PATH)
	var png_error := image.save_png(png_path)
	if png_error != OK:
		return _fail("Could not save generated PNG (error %d)" % png_error)

	var scene_text := _build_scene(spec, animations, animation_order, frame_width, frame_height, total_frames)
	write_error = _write_text(SCENE_PATH, scene_text)
	if write_error != OK:
		return _fail("Could not write generated WarriorSprite scene (error %d)" % write_error)

	print("Generated warrior sprite sheets and scene: %dx%d, %d frames" % [
		frame_width * total_frames,
		frame_height,
		total_frames,
	])
	return 0


func _build_svg(
	spec: Dictionary,
	defs: String,
	animations: Dictionary,
	animation_order: Array,
	render_order: Array,
	total_frames: int
) -> String:
	var frame_size: Dictionary = spec["frame_size"]
	var width := int(frame_size["width"])
	var height := int(frame_size["height"])
	var anchor: Dictionary = spec["anchor"]
	var palette: Dictionary = spec["palette"]
	var palette_order: Array = spec["palette_order"]
	var palette_description := PackedStringArray()
	for palette_name in palette_order:
		palette_description.append("%s %s" % [palette_name, palette[palette_name]])

	var svg := "<svg xmlns=\"http://www.w3.org/2000/svg\" width=\"%d\" height=\"%d\" viewBox=\"0 0 %d %d\">\n" % [
		width * total_frames,
		height,
		width * total_frames,
		height,
	]
	svg += "  <title>Paper Warrior idle and walk sprite sheet</title>\n"
	svg += "  <desc>Original geometry reference profile; %d transparent %dx%d frames; idle then walk. Center x=%d, ground baseline y=%d. Original colors and gradients (not quantized): %s.</desc>\n" % [
		total_frames,
		width,
		height,
		anchor["center_x"],
		anchor["ground_baseline_y"],
		", ".join(palette_description),
	]
	svg += "%s\n" % defs

	var frame_index := 0
	for animation_name in animation_order:
		var frames: Array = animations[animation_name]["frames"]
		for frame in frames:
			var frame_parts: Dictionary = frame["parts"]
			var variants: Dictionary = frame.get("variants", {})
			svg += "  <g id=\"frame_%s_%d\" transform=\"translate(%d 0)\">\n" % [
				animation_name,
				frame_index,
				frame_index * width,
			]
			for part_name in render_order:
				var position: Array = frame_parts[part_name]
				var group_name := str(variants.get(part_name, part_name))
				svg += "    <use href=\"#%s\" transform=\"translate(%d %d)\"/>\n" % [
					group_name,
					int(position[0]),
					int(position[1]),
				]
			svg += "  </g>\n"
			frame_index += 1
	svg += "</svg>\n"
	return svg


func _build_scene(
	spec: Dictionary,
	animations: Dictionary,
	animation_order: Array,
	frame_width: int,
	frame_height: int,
	total_frames: int
) -> String:
	var node: Dictionary = spec.get("node", {})
	var node_name := str(node.get("name", "WarriorSprite"))
	var scale: Array = node.get("scale", [0.75, 0.75])
	var default_animation := str(node.get("default_animation", "idle"))
	var scene := "[gd_scene load_steps=%d format=3]\n\n" % (total_frames + 3)
	scene += "[ext_resource type=\"Texture2D\" path=\"res://assets/characters/warrior/warrior_idle_walk.png\" id=\"1_sheet\"]\n"

	var frame_index := 0
	for animation_name in animation_order:
		var frames: Array = animations[animation_name]["frames"]
		for local_index in range(frames.size()):
			var atlas_id := "AtlasTexture_%s_%d" % [animation_name, local_index]
			scene += "\n[sub_resource type=\"AtlasTexture\" id=\"%s\"]\n" % atlas_id
			scene += "atlas = ExtResource(\"1_sheet\")\n"
			scene += "region = Rect2(%d, 0, %d, %d)\n" % [
				frame_index * frame_width,
				frame_width,
				frame_height,
			]
			frame_index += 1

	scene += "\n[sub_resource type=\"SpriteFrames\" id=\"SpriteFrames_warrior\"]\n"
	scene += "animations = ["
	for animation_index in range(animation_order.size()):
		var animation_name: String = animation_order[animation_index]
		var animation: Dictionary = animations[animation_name]
		var frames: Array = animation["frames"]
		if animation_index > 0:
			scene += ", "
		scene += "{\n\"frames\": ["
		for local_index in range(frames.size()):
			if local_index > 0:
				scene += ", "
			scene += "{\"duration\": 1.0, \"texture\": SubResource(\"AtlasTexture_%s_%d\")}" % [
				animation_name,
				local_index,
			]
		scene += "],\n\"loop\": %s,\n\"name\": &\"%s\",\n\"speed\": %s\n}" % [
			str(animation["loop"]).to_lower(),
			animation_name,
			str(float(animation["fps"])),
		]
	scene += "]\n\n"
	scene += "[node name=\"%s\" type=\"AnimatedSprite2D\"]\n" % node_name
	scene += "texture_filter = 1\n"
	scene += "scale = Vector2(%s, %s)\n" % [str(scale[0]), str(scale[1])]
	scene += "sprite_frames = SubResource(\"SpriteFrames_warrior\")\n"
	scene += "animation = &\"%s\"\n" % default_animation
	scene += "autoplay = \"%s\"\n" % default_animation
	return scene


func _write_text(path: String, contents: String) -> Error:
	var file := FileAccess.open(path, FileAccess.WRITE)
	if file == null:
		return FileAccess.get_open_error()
	file.store_string(contents)
	return OK


func _fail(message: String) -> int:
	push_error(message)
	return 1


func _is_integer_translation(value: Variant) -> bool:
	var value_type := typeof(value)
	if value_type != TYPE_INT and value_type != TYPE_FLOAT:
		return false
	var number := float(value)
	return is_finite(number) and number == floor(number)


func _has_unique_names(names: Array) -> bool:
	var seen: Dictionary = {}
	for name in names:
		if seen.has(name):
			return false
		seen[name] = true
	return true


func _finalize_raster(image: Image) -> void:
	image.convert(Image.FORMAT_RGBA8)
	for y in range(image.get_height()):
		for x in range(image.get_width()):
			var source_color := image.get_pixel(x, y)
			if source_color.a < 0.5:
				image.set_pixel(x, y, Color.TRANSPARENT)
				continue

			source_color.a = 1.0
			image.set_pixel(x, y, source_color)
