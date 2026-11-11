extends Control


const ART_PATH := "res://assets/backgrounds/paper_forest_diorama/"
const AMBIENCE := preload("res://scripts/ui/world_ambience.gd")
const LAYER_NAMES := [
	"BackgroundSky",
	"BackgroundMountains",
	"BackgroundForest",
	"BackgroundStructures",
	"BattleGround",
	"ForegroundObjects",
]
const PLACEMENTS := {
	"BackgroundMountains": [
		{"part": "cloud", "x": 0.14, "y": 0.105, "scale": 0.66},
		{"part": "cloud", "x": 0.56, "y": 0.13, "scale": 0.58, "flip": true},
		{"part": "cloud", "x": 0.89, "y": 0.075, "scale": 0.54},
		{"part": "mountain", "x": 0.04, "y": 0.355, "scale": 1.18, "opacity": 0.67},
		{"part": "mountain", "x": 0.35, "y": 0.35, "scale": 1.2, "flip": true, "opacity": 0.74},
		{"part": "mountain", "x": 0.65, "y": 0.36, "scale": 1.22, "opacity": 0.8},
		{"part": "mountain", "x": 0.96, "y": 0.355, "scale": 1.16, "flip": true, "opacity": 0.71},
	],
	"BackgroundForest": [
		{"part": "pine", "x": 0.02, "y": 0.48, "scale": 1.02, "opacity": 0.9},
		{"part": "round_tree", "x": 0.12, "y": 0.505, "scale": 0.77},
		{"part": "pine", "x": 0.37, "y": 0.46, "scale": 0.57, "opacity": 0.87},
		{"part": "round_tree", "x": 0.47, "y": 0.49, "scale": 0.6, "flip": true},
		{"part": "pine", "x": 0.56, "y": 0.465, "scale": 0.63},
		{"part": "round_tree", "x": 0.89, "y": 0.505, "scale": 0.75, "flip": true},
		{"part": "pine", "x": 0.99, "y": 0.48, "scale": 1.04, "flip": true},
	],
	"BackgroundStructures": [
		{"part": "windmill", "x": 0.25, "y": 0.425, "scale": 0.81},
		{"part": "castle", "x": 0.755, "y": 0.425, "scale": 0.91},
		{"part": "bush", "x": 0.135, "y": 0.542, "scale": 0.68},
		{"part": "bush", "x": 0.345, "y": 0.54, "scale": 0.62, "flip": true},
		{"part": "rock", "x": 0.395, "y": 0.557, "scale": 0.6},
		{"part": "bush", "x": 0.64, "y": 0.547, "scale": 0.68},
		{"part": "bush", "x": 0.865, "y": 0.54, "scale": 0.65, "flip": true},
	],
	"BattleGround": [
		{"part": "river", "x": 0.44, "y": 0.57, "scale": 0.88},
		{"part": "river", "x": 0.68, "y": 0.586, "scale": 0.61, "flip": true},
		{"part": "bridge", "x": 0.61, "y": 0.556, "scale": 0.89},
		{"part": "rock", "x": 0.27, "y": 0.59, "scale": 0.7},
		{"part": "bush", "x": 0.16, "y": 0.595, "scale": 0.8},
		{"part": "flower", "x": 0.24, "y": 0.605, "scale": 0.76},
		{"part": "bush", "x": 0.84, "y": 0.6, "scale": 0.73, "flip": true},
		{"part": "flower", "x": 0.9, "y": 0.615, "scale": 0.8},
	],
	"ForegroundObjects": [
		{"part": "round_tree", "x": 0.005, "y": 0.62, "scale": 1.04},
		{"part": "pine", "x": 0.99, "y": 0.625, "scale": 1.12, "flip": true},
		{"part": "rock", "x": 0.065, "y": 0.697, "scale": 0.7},
		{"part": "bush", "x": 0.06, "y": 0.755, "scale": 0.82},
		{"part": "flower", "x": 0.13, "y": 0.727, "scale": 0.83},
		{"part": "bush", "x": 0.95, "y": 0.755, "scale": 0.88, "flip": true},
		{"part": "flower", "x": 0.89, "y": 0.72, "scale": 0.91},
		{"part": "bush", "x": 0.035, "y": 0.79, "scale": 0.72},
		{"part": "rock", "x": 0.13, "y": 0.82, "scale": 0.66},
		{"part": "flower", "x": 0.205, "y": 0.86, "scale": 0.75},
		{"part": "bush", "x": 0.96, "y": 0.79, "scale": 0.76, "flip": true},
		{"part": "rock", "x": 0.865, "y": 0.82, "scale": 0.7},
		{"part": "flower", "x": 0.79, "y": 0.86, "scale": 0.72, "flip": true},
		{"part": "pine", "x": 0.005, "y": 0.89, "scale": 0.92},
		{"part": "round_tree", "x": 0.09, "y": 0.91, "scale": 0.82},
		{"part": "bush", "x": 0.25, "y": 0.94, "scale": 0.76},
		{"part": "rock", "x": 0.35, "y": 0.96, "scale": 0.58},
		{"part": "flower", "x": 0.44, "y": 0.93, "scale": 0.78},
		{"part": "bush", "x": 0.57, "y": 0.96, "scale": 0.7, "flip": true},
		{"part": "flower", "x": 0.67, "y": 0.91, "scale": 0.85, "flip": true},
		{"part": "rock", "x": 0.75, "y": 0.97, "scale": 0.62},
		{"part": "round_tree", "x": 0.92, "y": 0.91, "scale": 0.8},
		{"part": "pine", "x": 0.995, "y": 0.89, "scale": 0.94, "flip": true},
		{"part": "fence", "x": 0.19, "y": 0.905, "scale": 0.69, "flip": true},
		{"part": "fence", "x": 0.84, "y": 0.91, "scale": 0.72},
		{"part": "bush", "x": 0.02, "y": 0.98, "scale": 0.86},
		{"part": "flower", "x": 0.33, "y": 0.99, "scale": 0.78, "flip": true},
		{"part": "rock", "x": 0.48, "y": 0.985, "scale": 0.72},
		{"part": "bush", "x": 0.71, "y": 0.99, "scale": 0.82},
		{"part": "flower", "x": 0.96, "y": 0.98, "scale": 0.8},
	],
}

var _textures: Dictionary[String, Texture2D] = {}
var _layer_nodes: Dictionary[String, Control] = {}
var _motion: Array[Dictionary] = []
var _sails: Sprite2D
var _details: Node2D
var _elapsed := 0.0


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	clip_contents = true
	for layer_name: String in LAYER_NAMES:
		var layer := get_node_or_null(NodePath(layer_name)) as Control
		if layer == null:
			push_error("종이 숲 배경 레이어가 없습니다: %s" % layer_name)
			continue
		layer.mouse_filter = Control.MOUSE_FILTER_IGNORE
		_layer_nodes[layer_name] = layer
	resized.connect(refresh_layout)
	call_deferred("refresh_layout")


func refresh_layout() -> void:
	if size.x <= 0.0 or size.y <= 0.0:
		return
	var object_scale := minf(size.x / 480.0, size.y / 450.0)
	_motion.clear()
	for layer_name: String in LAYER_NAMES:
		var layer: Control = _layer_nodes.get(layer_name)
		if layer == null:
			continue
		for child: Node in layer.get_children():
			layer.remove_child(child)
			child.free()

	var sky_layer: Control = _layer_nodes.get("BackgroundSky")
	if sky_layer != null:
		_add_sky(sky_layer)
	_add_ground()
	for layer_name: String in PLACEMENTS:
		var layer: Control = _layer_nodes.get(layer_name)
		if layer == null:
			continue
		for placement: Dictionary in PLACEMENTS[layer_name]:
			_add_object(layer, placement, object_scale)
	_details = Node2D.new()
	_details.name = "LivingDetails"
	_details.set_script(AMBIENCE)
	_layer_nodes["BattleGround"].add_child(_details)
	_animate_world()


func _process(delta: float) -> void:
	_elapsed += maxf(0.0, delta)
	_animate_world()


func _animate_world() -> void:
	for item in _motion:
		var sprite: Control = item["sprite"]
		var phase: float = _elapsed * item["speed"] + item["phase"]
		if item["kind"] == "cloud":
			sprite.position.x = item["origin"].x + sin(phase) * 12.0
		else:
			sprite.rotation = sin(phase) * item["amplitude"]
	if is_instance_valid(_sails):
		_sails.rotation = _elapsed * 0.22
	if is_instance_valid(_details):
		_details.call("update_world", size, _elapsed)


func _add_sky(layer: Control) -> void:
	var texture := _get_texture("sky")
	if texture == null:
		return
	var sky := TextureRect.new()
	sky.name = "PaperSky"
	sky.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	sky.mouse_filter = Control.MOUSE_FILTER_IGNORE
	sky.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
	sky.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	sky.stretch_mode = TextureRect.STRETCH_SCALE
	sky.texture = texture
	layer.add_child(sky)


func _add_ground() -> void:
	var ground: Control = _layer_nodes.get("BackgroundSky")
	if ground == null:
		return
	_add_polygon(ground, "MeadowPaper", Color("#adc28a"), [
		Vector2(0, 0.49), Vector2(0.15, 0.476), Vector2(0.29, 0.5),
		Vector2(0.45, 0.485), Vector2(0.61, 0.502), Vector2(0.8, 0.484),
		Vector2(1, 0.5), Vector2(1, 1), Vector2(0, 1),
	])
	_add_polygon(ground, "SandyClearing", Color("#e4d1a2"), [
		Vector2(0.39, 0.574), Vector2(0.64, 0.581), Vector2(0.69, 0.615),
		Vector2(0.83, 0.64), Vector2(0.93, 0.705), Vector2(0.89, 0.768),
		Vector2(0.79, 0.81), Vector2(0.69, 0.838), Vector2(0.73, 0.94),
		Vector2(0.28, 0.94), Vector2(0.31, 0.84), Vector2(0.19, 0.806),
		Vector2(0.08, 0.764), Vector2(0.06, 0.7), Vector2(0.14, 0.654),
		Vector2(0.29, 0.625),
	])
	_add_polygon(ground, "WalkablePaperPath", Color("#eddbb1"), [
		Vector2(0.39, 0.625), Vector2(0.62, 0.633), Vector2(0.77, 0.68),
		Vector2(0.84, 0.717), Vector2(0.75, 0.77), Vector2(0.59, 0.8),
		Vector2(0.64, 0.9), Vector2(0.34, 0.9), Vector2(0.4, 0.799),
		Vector2(0.25, 0.777), Vector2(0.15, 0.72), Vector2(0.23, 0.668),
	])
	_add_polygon(ground, "LeftGrassFold", Color("#a6c58e"), [
		Vector2(0, 0.78), Vector2(0.08, 0.75), Vector2(0.18, 0.78),
		Vector2(0.13, 0.85), Vector2(0, 0.88),
	])
	_add_polygon(ground, "LeftGrassLightFacet", Color("#c4d29a"), [
		Vector2(0, 0.79), Vector2(0.08, 0.76), Vector2(0.055, 0.82),
		Vector2(0, 0.85),
	])
	_add_polygon(ground, "RightGrassFold", Color("#9dbb87"), [
		Vector2(0.82, 0.78), Vector2(0.93, 0.75), Vector2(1, 0.78),
		Vector2(1, 0.88), Vector2(0.87, 0.85),
	])
	_add_polygon(ground, "RightGrassLightFacet", Color("#c0ce96"), [
		Vector2(0.93, 0.76), Vector2(1, 0.79), Vector2(1, 0.85),
		Vector2(0.95, 0.82),
	])
	for index in 22:
		var x := 0.21 + fmod(index * 0.137, 0.58)
		var y := 0.65 + fmod(index * 0.039, 0.142)
		var width := 0.007 + (index % 3) * 0.004
		_add_polygon(ground, "PaperGrain%02d" % index, Color("#dfcba0"), [
			Vector2(x, y), Vector2(x + width, y - 0.001),
			Vector2(x + width * 0.8, y + 0.0025), Vector2(x - 0.002, y + 0.002),
		])


func _add_polygon(
	parent: Control, polygon_name: String, color: Color, normalized_points: Array[Vector2]
) -> void:
	var polygon := Polygon2D.new()
	polygon.name = polygon_name
	polygon.color = color
	var points := PackedVector2Array()
	for point: Vector2 in normalized_points:
		points.append(Vector2(point.x * size.x, point.y * size.y))
	polygon.polygon = points
	parent.add_child(polygon)


func _add_object(parent: Control, placement: Dictionary, object_scale: float) -> void:
	var texture := _get_texture(placement["part"])
	if texture == null:
		return
	var factor := object_scale * float(placement["scale"])
	var object_size := Vector2(texture.get_size()) * factor
	var sprite := TextureRect.new()
	sprite.name = "%s_%02d" % [placement["part"], parent.get_child_count()]
	sprite.position = Vector2(
		float(placement["x"]) * size.x - object_size.x * 0.5,
		float(placement["y"]) * size.y - object_size.y * 0.5
	)
	sprite.size = object_size
	sprite.mouse_filter = Control.MOUSE_FILTER_IGNORE
	sprite.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
	sprite.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	sprite.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	sprite.texture = texture
	sprite.flip_h = placement.get("flip", false)
	sprite.modulate.a = placement.get("opacity", 1.0)
	parent.add_child(sprite)
	var part: String = placement["part"]
	if part in ["cloud", "pine", "round_tree", "bush", "flower"]:
		sprite.pivot_offset = Vector2(object_size.x * 0.5, object_size.y * 0.94)
		_motion.append({
			"sprite": sprite, "kind": part, "origin": sprite.position,
			"phase": float(placement["x"]) * 9.0,
			"speed": 0.045 if part == "cloud" else 0.65,
			"amplitude": 0.012 if part in ["pine", "round_tree"] else 0.025,
		})
	if part == "windmill":
		_sails = Sprite2D.new()
		_sails.name = "WindmillSails"
		_sails.texture = _get_texture("windmill_sails")
		_sails.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
		_sails.position = Vector2(76, 66) * factor
		_sails.scale = Vector2.ONE * factor
		sprite.add_child(_sails)


func _get_texture(part_name: String) -> Texture2D:
	if _textures.has(part_name):
		return _textures[part_name]
	var file_name := "windmill_body" if part_name == "windmill" else part_name
	var texture := load(ART_PATH + file_name + ".png") as Texture2D
	if texture == null:
		push_error("종이 숲 그림 조각을 읽지 못했습니다: %s" % part_name)
		return null
	_textures[part_name] = texture
	return texture
