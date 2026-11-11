extends "res://scripts/ui/responsive_screen.gd"

const NEXT_SCENE := "res://scenes/main/loading.tscn"
const DISPLAY_SECONDS := 1.2
var scene_change: Callable = _change_scene
var _elapsed := 0.0
var _transition_requested := false
var _opened := false


func _ready() -> void:
	super._ready()
	$SplashLogo.modulate.a = 0.0
	create_tween().tween_property($SplashLogo, "modulate:a", 1.0, 0.4)


func _process(delta: float) -> void:
	if _transition_requested:
		return
	_elapsed += delta
	if _elapsed >= DISPLAY_SECONDS:
		_transition_requested = true
		set_process(false)
		call_deferred("_open_loading")


func _open_loading() -> void:
	if not is_inside_tree() or _opened:
		return
	_opened = true
	var error: Error = scene_change.call(NEXT_SCENE)
	if error != OK:
		$StartupError.text = "시작 준비에 실패했어요.\n창을 닫고 다시 실행해 주세요."
		$StartupError.show()
		push_error("Splash에서 Loading 씬으로 이동하지 못했습니다: %s" % error)


func _change_scene(path: String) -> Error:
	return get_tree().change_scene_to_file(path)


func _update_layout() -> void:
	var landscape := size.x > size.y
	$SplashLogo.position = Vector2(70, 130) if landscape else Vector2(40, 230)
	$SplashLogo.size = Vector2(size.x - 140, 135) if landscape else Vector2(size.x - 80, 128)
	$Intro.position = Vector2(32, 285) if landscape else Vector2(32, 390)
	$Intro.size = Vector2(size.x - 64, 30)
	$StartupError.position = Vector2(32, 330) if landscape else Vector2(32, 445)
	$StartupError.size = Vector2(size.x - 64, 60)
