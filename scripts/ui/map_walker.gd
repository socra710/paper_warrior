extends Control

const WAYPOINTS := [Vector2(0.25, 0.65), Vector2(0.72, 0.45), Vector2(0.62, 0.78), Vector2(0.28, 0.4)]
const WALK_SPEED := 36.0
const RUN_SPEED := 60.0

var _target_index := 1
var _pause_remaining := 0.0
var _last_size := Vector2.ZERO
@onready var warrior: AnimatedSprite2D = $WarriorSprite


func _ready() -> void:
	resized.connect(_fit_bounds)
	_fit_bounds()


func _fit_bounds() -> void:
	var normalized: Vector2 = WAYPOINTS[0]
	if _last_size.x > 0.0 and _last_size.y > 0.0:
		normalized = warrior.position / _last_size
	warrior.position = _inside_map(normalized * size)
	_last_size = size


func _inside_map(point: Vector2) -> Vector2:
	var padding := minf(36.0, minf(size.x, size.y) * 0.25)
	return point.clamp(Vector2.ONE * padding, size - Vector2.ONE * padding)


func _process(delta: float) -> void:
	if size.x < 72.0 or size.y < 72.0:
		return
	if _pause_remaining > 0.0:
		_pause_remaining -= delta
		warrior.play("idle")
		return
	var target := _inside_map(WAYPOINTS[_target_index] * size)
	var direction := target - warrior.position
	if absf(direction.x) > 0.1:
		warrior.flip_h = direction.x < 0.0
	var running := _target_index == 2
	warrior.play("run" if running else "walk")
	warrior.position = warrior.position.move_toward(target, (RUN_SPEED if running else WALK_SPEED) * delta)
	if warrior.position.distance_to(target) < 0.5:
		_target_index = (_target_index + 1) % WAYPOINTS.size()
		_pause_remaining = 0.65
