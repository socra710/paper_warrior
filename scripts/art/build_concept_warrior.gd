extends SceneTree
## Standalone, import-free concept profile builder for Godot 4.4.1.
## Run with --check to validate existing outputs, or --preview for a 4x contact sheet.

const PARTS_PATH := "res://assets/characters/warrior/concept_parts.svg"
const DATA_PATH := "res://data/presentation/concept_warrior_animation.json"
const SVG_PATH := "res://assets/characters/warrior/concept_idle_walk_run.svg"
const PNG_PATH := "res://assets/characters/warrior/concept_idle_walk_run.png"
const SCENE_PATH := "res://scenes/characters/concept_warrior.tscn"
const PREVIEW_PATH := "res://assets/characters/warrior/concept_preview_4x.png"
const ORDER := ["cape", "left_thigh", "right_thigh", "left_boot", "right_boot", "torso", "left_arm", "right_arm", "head", "face", "sword", "shield"]
const ANIMATIONS := ["idle", "walk", "run"]
const SIZE := 96
const BASELINE := 88


func _initialize() -> void:
	quit(_generate())


func _generate() -> int:
	var parsed: Variant = JSON.parse_string(FileAccess.get_file_as_string(DATA_PATH))
	if typeof(parsed) != TYPE_DICTIONARY:
		return _fail("Concept animation source must be a JSON object")
	var spec: Dictionary = parsed
	var source := FileAccess.get_file_as_string(PARTS_PATH)
	var start := source.find("<defs>")
	var end := source.find("</defs>")
	if start < 0 or end < start:
		return _fail("Concept shared SVG needs one defs section")
	var defs := source.substr(start, end + 7 - start)
	var problem := _validate_spec(spec, defs)
	if not problem.is_empty():
		return _fail(problem)
	var palette: Array[Color] = []
	for value in spec["palette"].values():
		palette.append(Color(value))
	var svg := _build_svg(spec, defs)
	var image := Image.new()
	if OS.get_cmdline_user_args().has("--check"):
		if not FileAccess.file_exists(PNG_PATH):
			return _fail("Concept PNG has not been generated")
		if FileAccess.get_file_as_string(SVG_PATH) != svg:
			return _fail("Concept SVG is stale; rerun the generator")
		if image.load_png_from_buffer(FileAccess.get_file_as_bytes(PNG_PATH)) != OK:
			return _fail("Could not read the generated concept PNG")
		var expected := Image.new()
		if expected.load_svg_from_string(svg) != OK:
			return _fail("Could not rasterize the expected concept PNG")
		_finalize_raster(expected, palette)
		if expected.get_data() != image.get_data():
			return _fail("Concept PNG is stale; rerun the generator")
		if FileAccess.get_file_as_string(SCENE_PATH) != _build_scene(spec):
			return _fail("Concept scene is stale; rerun the generator")
	else:
		if image.load_svg_from_string(svg) != OK:
			return _fail("Could not rasterize shared concept anatomy")
		_finalize_raster(image, palette)
	problem = _validate_pixels(image, spec, defs, palette)
	if not problem.is_empty():
		return _fail(problem)
	if not OS.get_cmdline_user_args().has("--check"):
		if _write(SVG_PATH, svg) != OK or image.save_png(PNG_PATH) != OK:
			return _fail("Could not persist the concept sheets")
		if _write(SCENE_PATH, _build_scene(spec)) != OK:
			return _fail("Could not persist the concept scene")
	if OS.get_cmdline_user_args().has("--preview"):
		var preview := Image.create_empty(SIZE * 4, SIZE * 4, false, Image.FORMAT_RGBA8)
		for index in 16:
			preview.blit_rect(image, Rect2i(index * SIZE, 0, SIZE, SIZE), Vector2i((index % 4) * SIZE, (index / 4) * SIZE))
		preview.resize(SIZE * 16, SIZE * 16, Image.INTERPOLATE_NEAREST)
		if preview.save_png(PREVIEW_PATH) != OK:
			return _fail("Could not save 4x concept preview")
	print("CONCEPT_OK: %s; 1536x96 RGBA8; idle 4@4, walk 6@8, run 6@12; center 48; baseline 88; %d colors; face/hip/grip overlap validated" % [PNG_PATH, palette.size()])
	return 0


func _validate_spec(spec: Dictionary, defs: String) -> String:
	if spec.get("schema_version") != 1 or spec.get("reference_profile") != "concept_pixel_96":
		return "Expected the isolated concept_pixel_96 profile"
	if spec.get("frame_size") != {"width": 96.0, "height": 96.0} or spec.get("frame_count") != 16:
		return "Concept sheet must have sixteen 96x96 frames"
	if spec.get("anchor") != {"center_x": 48.0, "ground_baseline_y": 88.0}:
		return "Concept anchor must remain center 48, baseline 88"
	if spec.get("node") != {"name": "WarriorSprite", "scale": [0.75, 0.75], "default_animation": "idle"}:
		return "Concept scene must be WarriorSprite, scale 0.75, autoplay idle"
	if spec.get("animation_order") != ANIMATIONS or spec.get("render_order") != ORDER:
		return "Unexpected concept animation or shared-part order"
	var pivots: Dictionary = spec.get("part_pivots", {})
	if pivots.size() != ORDER.size():
		return "Each concept part needs an integer pivot"
	for name in ORDER:
		if not _integer_array(pivots.get(name), 2) or not defs.contains('id="%s"' % name):
			return "Missing shared SVG part or integer pivot: %s" % name
	if pivots["head"] != pivots["face"] or pivots["sword"] != pivots["left_arm"] or pivots["shield"] != pivots["right_arm"]:
		return "Face and equipment must share their parent pivots"
	if pivots["left_thigh"] != [39.0, 72.0] or pivots["right_thigh"] != [57.0, 72.0]:
		return "Hip pivots must remain inside the overlapping waist"
	var palette: Dictionary = spec.get("palette", {})
	if palette.size() != 14:
		return "Concept art must preserve its 14-color palette"
	var palette_values: Array = palette.values()
	for color_match in RegEx.create_from_string('fill="(#[0-9a-f]{6})"').search_all(defs):
		if not palette_values.has(color_match.get_string(1)):
			return "Shared concept SVG uses an undeclared color"
	if RegEx.create_from_string("[-+]?\\d*\\.\\d+").search(defs) != null:
		return "Shared anatomy must use integer coordinates"
	var face: Dictionary = spec.get("face_validation", {})
	if not _integer_array(face.get("roi"), 4):
		return "Face validation needs an integer region"
	var eyes: Array = face.get("eyes", [])
	if eyes.size() != 2:
		return "Face validation needs two short vertical eyes"
	for eye in eyes:
		if not _integer_array(eye, 4) or eye[2] != 3 or eye[3] != 7:
			return "Reference eyes must remain 3x7 pixels"
	if eyes[1][0] - eyes[0][0] != 14 or eyes[1][1] - eyes[0][1] != 1:
		return "Reference eye line must slope gently down-right"
	for sample_group in ["smile_ink_samples", "paper_samples"]:
		var samples: Array = face.get(sample_group, [])
		if samples.is_empty():
			return "Face validation needs smile and clear paper/collar samples"
		for sample in samples:
			if not _integer_array(sample, 2):
				return "Face validation samples must use integer coordinates"
	var animations: Dictionary = spec.get("animations", {})
	if animations.size() != 3:
		return "Concept profile only contains idle, walk and run"
	var poses: Dictionary = {}
	var statistics: Dictionary = {}
	for name in ANIMATIONS:
		var animation: Dictionary = animations.get(name, {})
		var expected_count := 4 if name == "idle" else 6
		var expected_fps := 4 if name == "idle" else (8 if name == "walk" else 12)
		var frames: Array = animation.get("frames", [])
		if frames.size() != expected_count or animation.get("fps") != expected_fps or animation.get("loop") != true:
			return "Wrong frame count, speed or loop flag for %s" % name
		var bobs: Dictionary = {}
		var feet: Dictionary = {}
		var capes: Dictionary = {}
		var stride := 0
		var flight := 0
		for local_index in frames.size():
			var frame: Dictionary = frames[local_index]
			var pose := str(frame.get("pose", ""))
			if pose != "%s_%d" % [name, local_index] or poses.has(pose):
				return "Every concept frame needs its own ordered animation-local pose name"
			poses[pose] = true
			if typeof(frame.get("flight")) != TYPE_BOOL or not _integer_array(frame.get("hip_offset"), 2):
				return "%s needs an explicit flight flag and integer hip offset" % pose
			var parts: Dictionary = frame.get("parts", {})
			if parts.size() != ORDER.size():
				return "%s must transform each shared body part exactly once" % pose
			for part in ORDER:
				if not _integer_array(parts.get(part), 3):
					return "%s/%s requires integer translation and integer rotation" % [pose, part]
				var transform: Array = parts[part]
				if absf(transform[0]) > 8 or transform[1] < -6 or transform[1] > 1 or absf(transform[2]) > 12:
					return "%s/%s exceeds the small-body motion envelope" % [pose, part]
			if parts["face"] != parts["head"] or parts["head"][2] != 0:
				return "%s must preserve the rigid, unrotated reference face" % pose
			if parts["sword"] != parts["left_arm"] or parts["shield"] != parts["right_arm"]:
				return "%s must keep equipment on its gripping arm" % pose
			var hip: Array = frame["hip_offset"]
			for thigh in ["left_thigh", "right_thigh"]:
				if parts[thigh] != [hip[0], hip[1], 0.0]:
					return "%s must keep both thigh roots on the stable hip pivots" % pose
			var left: Array = parts["left_boot"]
			var right: Array = parts["right_boot"]
			if left[2] != 0 or right[2] != 0:
				return "Pixel soles must remain horizontal"
			if name == "idle" and (left != [0.0, 0.0, 0.0] or right != [0.0, 0.0, 0.0]):
				return "Idle feet must remain planted without sliding"
			if frame["flight"]:
				if name != "run" or left[1] >= 0 or right[1] >= 0:
					return "Only running may have explicit two-foot flight"
				flight += 1
			elif maxi(int(left[1]), int(right[1])) != 0:
				return "%s needs a planted support foot at baseline 88" % pose
			if name == "run" and (parts["torso"][2] >= 0 or parts["head"][0] <= hip[0]):
				return "Running must lean the torso forward without warping the face"
			bobs[parts["head"][1]] = true
			feet[str([left, right])] = true
			capes[str(parts["cape"])] = true
			stride = maxi(stride, absi(int(left[0]) - int(right[0])))
		statistics[name] = {"bob": bobs.size(), "feet": feet.size(), "cape": capes.size(), "stride": stride, "flight": flight}
	if statistics["idle"]["bob"] < 2 or statistics["walk"]["feet"] < 4:
		return "Idle needs breathing and walking needs alternating planted/swing feet"
	if statistics["run"]["stride"] <= statistics["walk"]["stride"] or statistics["walk"]["stride"] <= statistics["idle"]["stride"]:
		return "Walk and run must have progressively wider strides"
	if statistics["run"]["bob"] <= statistics["walk"]["bob"] or statistics["run"]["flight"] < 1:
		return "Run needs a stronger bob and an explicit flight phase"
	if statistics["run"]["cape"] <= statistics["idle"]["cape"]:
		return "Run needs distinct cape follow-through"
	return ""


func _build_svg(spec: Dictionary, defs: String) -> String:
	var svg := '<svg xmlns="http://www.w3.org/2000/svg" width="1536" height="96" viewBox="0 0 1536 96" shape-rendering="crispEdges">\n'
	svg += "  <title>Concept-sheet Paper Warrior: idle 4, walk 6, run 6</title>\n"
	svg += "  <desc>Shared integer-pivot anatomy. Center 48, foot baseline 88. Face rigid; folded tunic overlaps fixed hip roots; equipment follows gripping arms. PNG is palette-snapped binary-alpha pixel master. No baked shadow.</desc>\n"
	svg += defs + "\n"
	var index := 0
	for name in ANIMATIONS:
		for frame in spec["animations"][name]["frames"]:
			svg += '  <g id="%s" transform="translate(%d 0)">\n' % [frame["pose"], index * SIZE]
			for part in ORDER:
				svg += _part_use(part, frame["parts"][part], spec["part_pivots"][part])
			svg += "  </g>\n"
			index += 1
	return svg + "</svg>\n"


func _part_use(name: String, pose: Array, pivot: Array) -> String:
	return '    <use href="#%s" transform="translate(%d %d) rotate(%d %d %d)"/>\n' % [
		name, int(pose[0]), int(pose[1]), int(pose[2]), int(pivot[0]), int(pivot[1])
	]


func _finalize_raster(image: Image, palette: Array[Color]) -> void:
	image.convert(Image.FORMAT_RGBA8)
	var cache: Dictionary = {}
	for y in image.get_height():
		for x in image.get_width():
			var color := image.get_pixel(x, y)
			if color.a < 0.5:
				image.set_pixel(x, y, Color(0, 0, 0, 0))
				continue
			var key := color.to_rgba32()
			if not cache.has(key):
				var closest := palette[0]
				var distance := INF
				for candidate in palette:
					var delta := Vector3(color.r - candidate.r, color.g - candidate.g, color.b - candidate.b)
					if delta.length_squared() < distance:
						distance = delta.length_squared()
						closest = candidate
				cache[key] = closest
			image.set_pixel(x, y, cache[key])


func _validate_pixels(image: Image, spec: Dictionary, defs: String, palette: Array[Color]) -> String:
	if image.get_size() != Vector2i(SIZE * 16, SIZE) or image.get_format() != Image.FORMAT_RGBA8:
		return "Concept PNG must be 1536x96 RGBA8"
	var allowed: Dictionary = {}
	for color in palette:
		allowed[color.to_rgba32()] = true
	var clear := 0
	for y in image.get_height():
		for x in image.get_width():
			var pixel := image.get_pixel(x, y)
			if pixel.a8 == 0:
				if pixel.to_rgba32() != 0:
					return "Transparent pixels must have zero RGB (no hidden fringe)"
				clear += 1
			elif pixel.a8 != 255 or not allowed.has(pixel.to_rgba32()):
				return "Concept PNG has partial alpha or a color outside the limited palette"
	if clear == 0:
		return "Concept background must be transparent"
	var face: Dictionary = spec["face_validation"]
	var roi: Array = face["roi"]
	var reference_rect := Rect2i(int(roi[0]), int(roi[1]), int(roi[2]), int(roi[3]))
	var reference_face := image.get_region(reference_rect).get_data()
	var ink := Color(spec["palette"]["ink"])
	var index := 0
	for name in ANIMATIONS:
		var silhouettes: Dictionary = {}
		for frame in spec["animations"][name]["frames"]:
			var pixels := image.get_region(Rect2i(index * SIZE, 0, SIZE, SIZE))
			var bounds := pixels.get_used_rect()
			if bounds.size == Vector2i.ZERO or bounds.position.x <= 1 or bounds.position.y <= 1 or bounds.end.x >= 94:
				return "%s is empty or clips a frame edge" % frame["pose"]
			if bounds.end.y > BASELINE or (not frame["flight"] and bounds.end.y != BASELINE):
				return "%s must preserve the planted baseline 88" % frame["pose"]
			if frame["flight"] and bounds.end.y >= BASELINE:
				return "%s is marked flight but still touches the ground" % frame["pose"]
			var parts: Dictionary = frame["parts"]
			var head: Array = parts["head"]
			var face_rect := Rect2i(reference_rect.position + Vector2i(int(head[0]), int(head[1])), reference_rect.size)
			if pixels.get_region(face_rect).get_data() != reference_face:
				return "%s changes or obscures the reference face/front panels" % frame["pose"]
			for eye in face["eyes"]:
				for eye_x in range(int(eye[0]), int(eye[0]) + int(eye[2])):
					for eye_y in range(int(eye[1]), int(eye[1]) + int(eye[3])):
						if pixels.get_pixel(eye_x + int(head[0]), eye_y + int(head[1])) != ink:
							return "%s loses an eye on the sloped reference face plane" % frame["pose"]
			for sample in face["smile_ink_samples"]:
				if pixels.get_pixel(int(sample[0]) + int(head[0]), int(sample[1]) + int(head[1])) != ink:
					return "%s loses the small friendly curved smile" % frame["pose"]
			for sample in face["paper_samples"]:
				var paper := pixels.get_pixel(int(sample[0]) + int(head[0]), int(sample[1]) + int(head[1]))
				if paper.a8 != 255 or paper == ink:
					return "%s loses clear face panels or the thin connected collar" % frame["pose"]
			var layers: Dictionary = {}
			for part in ORDER:
				var layer := Image.new()
				var layer_svg := '<svg xmlns="http://www.w3.org/2000/svg" width="96" height="96">%s%s</svg>' % [
					defs, _part_use(part, parts[part], spec["part_pivots"][part])
				]
				if layer.load_svg_from_string(layer_svg) != OK:
					return "Could not inspect shared concept attachment masks"
				layers[part] = layer
			var left_boot: Image = layers["left_boot"]
			var boot_pose: Array = parts["left_boot"]
			var toe := left_boot.get_pixel(30 + int(boot_pose[0]), 86 + int(boot_pose[1]))
			var toe_fold := left_boot.get_pixel(33 + int(boot_pose[0]), 85 + int(boot_pose[1]))
			if toe.a < 0.5 or toe_fold.a < 0.5 or toe_fold == ink:
				return "%s loses the down-left folded toe" % frame["pose"]
			for side in ["left", "right"]:
				var thigh: Image = layers[side + "_thigh"]
				var boot: Image = layers[side + "_boot"]
				if _overlap(layers["torso"], thigh) < 16:
					return "%s has a detached %s hip: tunic must overlap the thigh root" % [frame["pose"], side]
				if _overlap(thigh, boot) < 12:
					return "%s has a detached %s boot" % [frame["pose"], side]
			for pair in [["head", "torso"], ["left_arm", "torso"], ["right_arm", "torso"], ["left_arm", "sword"], ["right_arm", "shield"]]:
				if _overlap(layers[pair[0]], layers[pair[1]]) < 6:
					return "%s disconnects %s from %s" % [frame["pose"], pair[0], pair[1]]
			var hip: Array = frame["hip_offset"]
			for hip_x in [39, 57]:
				for seam_y in range(70 + int(hip[1]), 79 + int(hip[1])):
					if pixels.get_pixel(hip_x + int(hip[0]), seam_y).a8 != 255:
						return "%s opens a blank gap through the waist/leg seam" % frame["pose"]
			silhouettes[hash(pixels.get_data())] = true
			print("CONCEPT_FRAME %s bounds=%s hip-overlap=%s/%s" % [
				frame["pose"], bounds, _overlap(layers["torso"], layers["left_thigh"]), _overlap(layers["torso"], layers["right_thigh"])
			])
			index += 1
		if silhouettes.size() < (3 if name == "idle" else 6):
			return "%s needs visibly independent animation poses" % name
	return ""


func _overlap(first: Image, second: Image) -> int:
	var count := 0
	for y in SIZE:
		for x in SIZE:
			if first.get_pixel(x, y).a >= 0.5 and second.get_pixel(x, y).a >= 0.5:
				count += 1
	return count


func _build_scene(spec: Dictionary) -> String:
	var scene := '[gd_scene load_steps=20 format=3]\n\n'
	scene += '[ext_resource type="Texture2D" path="%s" id="1_sheet"]\n' % PNG_PATH
	scene += '[ext_resource type="Script" path="res://scripts/ui/warrior_shadow.gd" id="2_shadow"]\n'
	var index := 0
	for name in ANIMATIONS:
		for local_index in spec["animations"][name]["frames"].size():
			scene += '\n[sub_resource type="AtlasTexture" id="AtlasTexture_%s_%d"]\natlas = ExtResource("1_sheet")\nregion = Rect2(%d, 0, 96, 96)\n' % [
				name, local_index, index * SIZE
			]
			index += 1
	scene += '\n[sub_resource type="SpriteFrames" id="SpriteFrames_concept"]\nanimations = ['
	for animation_index in ANIMATIONS.size():
		var name: String = ANIMATIONS[animation_index]
		if animation_index > 0:
			scene += ", "
		scene += '{\n"frames": ['
		var animation: Dictionary = spec["animations"][name]
		for local_index in animation["frames"].size():
			if local_index > 0:
				scene += ", "
			scene += '{"duration": 1.0, "texture": SubResource("AtlasTexture_%s_%d")}' % [name, local_index]
		scene += '],\n"loop": true,\n"name": &"%s",\n"speed": %s\n}' % [name, str(float(animation["fps"]))]
	scene += ']\n\n[node name="WarriorSprite" type="AnimatedSprite2D"]\ntexture_filter = 1\nscale = Vector2(0.75, 0.75)\nsprite_frames = SubResource("SpriteFrames_concept")\nanimation = &"idle"\nautoplay = "idle"\n'
	scene += '\n[node name="FootShadow" type="Node2D" parent="."]\nshow_behind_parent = true\nposition = Vector2(0, 40)\nscript = ExtResource("2_shadow")\n'
	return scene


func _integer_array(value: Variant, length: int) -> bool:
	if typeof(value) != TYPE_ARRAY or value.size() != length:
		return false
	for number in value:
		if typeof(number) != TYPE_INT and typeof(number) != TYPE_FLOAT:
			return false
		if not is_finite(float(number)) or float(number) != floor(float(number)):
			return false
	return true


func _write(path: String, contents: String) -> Error:
	var file := FileAccess.open(path, FileAccess.WRITE)
	if file == null:
		return FileAccess.get_open_error()
	file.store_string(contents)
	return OK


func _fail(message: String) -> int:
	push_error(message)
	return 1
