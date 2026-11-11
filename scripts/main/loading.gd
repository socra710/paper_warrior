extends Control

const TITLE_SCENE := "res://scenes/main/title.tscn"
const GAME_SCENE := "res://scenes/main/game.tscn"
const SCENES := [TITLE_SCENE, GAME_SCENE]


func _ready() -> void:
	%RetryButton.pressed.connect(_retry)
	for path in SCENES:
		var status := ResourceLoader.load_threaded_get_status(path)
		if status == ResourceLoader.THREAD_LOAD_IN_PROGRESS or status == ResourceLoader.THREAD_LOAD_LOADED:
			continue
		if status == ResourceLoader.THREAD_LOAD_FAILED:
			ResourceLoader.load_threaded_get(path)
		var error := ResourceLoader.load_threaded_request(path, "PackedScene")
		if error != OK:
			_show_error("리소스 준비를 시작하지 못했습니다: %s (%s)" % [path, error])
			return


func _process(_delta: float) -> void:
	var total_progress := 0.0
	var completed := 0
	for path in SCENES:
		var progress: Array = []
		var status := ResourceLoader.load_threaded_get_status(path, progress)
		if status == ResourceLoader.THREAD_LOAD_LOADED:
			total_progress += 1.0
			completed += 1
		elif status == ResourceLoader.THREAD_LOAD_IN_PROGRESS:
			if not progress.is_empty():
				total_progress += clampf(float(progress[0]), 0.0, 1.0)
		else:
			_show_error("리소스를 준비하지 못했습니다: %s" % path)
			return
	%LoadProgress.value = total_progress / SCENES.size() * 100.0
	%LoadPercent.text = "%d%%" % int(%LoadProgress.value)
	%LoadPhase.text = "시작 화면과 종이 숲 준비 · %d / %d" % [completed, SCENES.size()]
	if completed == SCENES.size():
		set_process(false)
		%LoadPhase.text = "준비 완료! 첫 장을 펼쳐요."
		call_deferred("_enter_title")


func _enter_title() -> void:
	var title := ResourceLoader.load_threaded_get(TITLE_SCENE) as PackedScene
	if title == null:
		_show_error("준비한 시작 화면을 열지 못했습니다.")
		return
	# 완료된 게임 요청은 타이틀에서 시작할 때 가져와 리소스를 유지한다.
	await create_tween().tween_property(self, "modulate:a", 0.0, 0.15).finished
	var error := get_tree().change_scene_to_packed(title)
	if error != OK:
		_show_error("Loading에서 Title로 이동하지 못했습니다: %s" % error)


func _show_error(message: String) -> void:
	set_process(false)
	modulate.a = 1.0
	%LoadPhase.text = "준비에 실패했어요.\n%s" % message
	%RetryButton.show()
	push_error(message)


func _retry() -> void:
	var error := get_tree().reload_current_scene()
	if error != OK:
		_show_error("로딩 화면을 다시 열지 못했습니다: %s" % error)
