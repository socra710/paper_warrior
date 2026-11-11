extends "res://scripts/ui/responsive_screen.gd"

const TITLE_SCENE := "res://scenes/main/title.tscn"
const GAME_SCENE := "res://scenes/main/game.tscn"
const SCENES := [TITLE_SCENE, GAME_SCENE]
const MAX_WAIT_SECONDS := 20.0

enum Phase { PREPARING, TRANSFERRING, FAILED }
var resource_loader: Object = ResourceLoader
var restart_application: Callable = _restart_application
var _phase := Phase.PREPARING
var _elapsed := 0.0
var _timed_out := false


func _ready() -> void:
	super._ready()
	%RetryButton.pressed.connect(_retry)
	_start_preparation()


func _start_preparation() -> void:
	(find_child("PaperFoldSprite") as AnimatedSprite2D).play("fold")
	_phase = Phase.PREPARING
	_elapsed = 0.0
	_timed_out = false
	modulate.a = 1.0
	%RetryButton.disabled = false
	%RetryButton.text = "다시 펼쳐 보기"
	%RetryButton.hide()
	%LoadProgress.value = 0.0
	%LoadProgress.indeterminate = true
	%LoadPercent.text = "조금만 기다려 주세요"
	%LoadPhase.text = "종이 숲으로 가는 길을 열어요"
	set_process(true)
	for path in SCENES:
		var status: int = resource_loader.load_threaded_get_status(path)
		if status == ResourceLoader.THREAD_LOAD_IN_PROGRESS or status == ResourceLoader.THREAD_LOAD_LOADED:
			continue
		if status == ResourceLoader.THREAD_LOAD_FAILED:
			resource_loader.load_threaded_get(path)
		var error: Error = resource_loader.load_threaded_request(path, "PackedScene")
		if error != OK:
			_show_error("리소스 준비를 시작하지 못했습니다: %s (%s)" % [path, error])
			return


func _process(delta: float) -> void:
	if _phase != Phase.PREPARING:
		return
	_elapsed += delta
	if _elapsed >= MAX_WAIT_SECONDS:
		_timed_out = true
		_show_error("리소스 준비 응답 시간이 초과됐어요.\n처음부터 다시 시작해 주세요.")
		%RetryButton.text = "처음부터 다시 시작"
		return
	var total_progress := 0.0
	var completed := 0
	var progress_known := true
	for path in SCENES:
		var progress: Array = []
		var status: int = resource_loader.load_threaded_get_status(path, progress)
		if status == ResourceLoader.THREAD_LOAD_LOADED:
			total_progress += 1.0
			completed += 1
		elif status == ResourceLoader.THREAD_LOAD_IN_PROGRESS:
			if not progress.is_empty() and is_finite(float(progress[0])):
				total_progress += clampf(float(progress[0]), 0.0, 1.0)
			else:
				progress_known = false
		else:
			_show_error("리소스를 준비하지 못했습니다: %s" % path)
			return
	%LoadProgress.indeterminate = not progress_known
	%LoadProgress.value = minf(total_progress / SCENES.size() * 100.0, 99.0)
	%LoadPercent.text = "%d%%" % int(%LoadProgress.value) if progress_known else "조금만 기다려 주세요"
	%LoadPhase.text = "종이 숲을 펼치고 있어요"
	if completed == SCENES.size():
		_phase = Phase.TRANSFERRING
		set_process(false)
		%LoadProgress.indeterminate = false
		%LoadProgress.value = 100.0
		%LoadPercent.text = "100%"
		%LoadPhase.text = "첫 장이 준비됐어요!"
		call_deferred("_enter_title")


func _enter_title() -> void:
	if not is_inside_tree() or _phase != Phase.TRANSFERRING:
		return
	var title := resource_loader.load_threaded_get(TITLE_SCENE) as PackedScene
	if title == null:
		_show_error("준비한 시작 화면을 열지 못했습니다.")
		return
	# 완료된 게임 요청은 타이틀에서 시작할 때 가져와 리소스를 유지한다.
	await create_tween().tween_property(self, "modulate:a", 0.0, 0.15).finished
	if not is_inside_tree() or _phase != Phase.TRANSFERRING:
		return
	var error := get_tree().change_scene_to_packed(title)
	if error != OK:
		_show_error("Loading에서 Title로 이동하지 못했습니다: %s" % error)


func _show_error(message: String) -> void:
	(find_child("PaperFoldSprite") as AnimatedSprite2D).pause()
	_phase = Phase.FAILED
	set_process(false)
	modulate.a = 1.0
	%LoadProgress.indeterminate = false
	%LoadPercent.text = "준비 중단"
	%LoadPhase.text = "준비에 시간이 조금 더 걸리고 있어요.\n처음부터 다시 펼쳐 주세요." if _timed_out else "모험을 준비하지 못했어요.\n다시 한번 펼쳐 볼까요?"
	%RetryButton.disabled = false
	%RetryButton.show()
	push_error(message)


func _retry() -> void:
	if _phase != Phase.FAILED:
		return
	if _timed_out:
		_phase = Phase.TRANSFERRING
		%RetryButton.disabled = true
		var error: Error = restart_application.call()
		if error != OK:
			_show_error("앱을 다시 열지 못했어요. 창을 닫고 다시 실행해 주세요.")
		return
	_start_preparation()


func _restart_application() -> Error:
	if OS.has_feature("web"):
		JavaScriptBridge.eval("window.location.reload();")
		return OK
	var arguments := PackedStringArray()
	if OS.has_feature("editor"):
		arguments.append_array(["--path", ProjectSettings.globalize_path("res://")])
	if OS.create_instance(arguments) < 0:
		return ERR_CANT_CREATE
	get_tree().quit()
	return OK


func _update_layout() -> void:
	var landscape := size.x > size.y
	$Center/Content.custom_minimum_size.x = minf(400, size.x - 48)
	var side := 112.0 if landscape else 176.0
	$Center/Content/FoldSlot/FoldBox.custom_minimum_size = Vector2.ONE * side
	var folding := find_child("PaperFoldSprite") as AnimatedSprite2D
	folding.position = Vector2.ONE * side * 0.5
	folding.scale = Vector2.ONE * (2 if landscape else 3)
