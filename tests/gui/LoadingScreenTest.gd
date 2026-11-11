extends GdUnitTestSuite

const GAME := "res://scenes/main/game.tscn"


func test_loading_centers_a_visible_folding_animation_without_a_card() -> void:
	var screen: Control = auto_free(load("res://scenes/main/loading.tscn").instantiate())
	screen.set("resource_loader", FakeLoader.new())
	var runner := scene_runner(screen)
	await runner.simulate_frames(3)
	assert_that(screen.find_child("WorkCard")).is_null()
	var content := screen.find_child("Content") as Control
	assert_that(content.get_global_rect().get_center().distance_to(screen.size * 0.5) < 2.0).is_true()
	var folding := screen.find_child("PaperFoldSprite") as AnimatedSprite2D
	assert_that(folding.is_playing()).is_true()
	assert_that(folding.sprite_frames.get_frame_count("fold")).is_equal(8)
	var first_frame := folding.frame
	var deadline := Time.get_ticks_msec() + 1500
	while folding.frame == first_frame and Time.get_ticks_msec() < deadline:
		await runner.simulate_frames(1)
	assert_that(folding.frame != first_frame).is_true()
	screen.set_process(false)


class FakeLoader extends RefCounted:
	var states: Dictionary = {}
	var requests: Array[String] = []
	var fraction := 0.5
	var report_progress := true

	func load_threaded_request(path: String, _hint: String) -> Error:
		requests.append(path)
		states[path] = ResourceLoader.THREAD_LOAD_IN_PROGRESS
		return OK

	func load_threaded_get_status(path: String, progress: Array = []) -> int:
		if report_progress:
			progress.append(fraction)
		return states.get(path, ResourceLoader.THREAD_LOAD_INVALID_RESOURCE)

	func load_threaded_get(path: String) -> Resource:
		states.erase(path)
		return null


func test_pending_resources_show_actual_progress_not_failure() -> void:
	var screen: Control = auto_free(load("res://scenes/main/loading.tscn").instantiate())
	assert_that(screen.get("resource_loader")).is_not_null()
	if screen.get("resource_loader") == null:
		return
	screen.set("resource_loader", FakeLoader.new())
	scene_runner(screen)
	screen.call("_process", 0.1)
	assert_that((screen.find_child("LoadProgress") as ProgressBar).value).is_equal(50.0)
	assert_that((screen.find_child("RetryButton") as Button).visible).is_false()
	screen.set_process(false)


func test_unknown_progress_is_indeterminate_not_zero_percent() -> void:
	var screen: Control = auto_free(load("res://scenes/main/loading.tscn").instantiate())
	var backend := FakeLoader.new()
	backend.report_progress = false
	screen.set("resource_loader", backend)
	scene_runner(screen)
	screen.call("_process", 0.1)
	assert_that((screen.find_child("LoadProgress") as ProgressBar).indeterminate).is_true()
	assert_that((screen.find_child("LoadPercent") as Label).text.contains("%")).is_false()
	screen.set_process(false)


func test_in_progress_resources_cannot_display_one_hundred_percent() -> void:
	var screen: Control = auto_free(load("res://scenes/main/loading.tscn").instantiate())
	var backend := FakeLoader.new()
	backend.fraction = 1.0
	screen.set("resource_loader", backend)
	scene_runner(screen)
	screen.call("_process", 0.1)
	assert_that((screen.find_child("LoadProgress") as ProgressBar).value).is_equal(99.0)
	assert_that((screen.find_child("LoadPhase") as Label).text.contains("완료")).is_false()
	assert_that(screen.is_processing()).is_true()
	screen.set_process(false)


func test_failed_resource_retry_reissues_request_only_once() -> void:
	var screen: Control = auto_free(load("res://scenes/main/loading.tscn").instantiate())
	assert_that(screen.get("resource_loader")).is_not_null()
	if screen.get("resource_loader") == null:
		return
	var backend := FakeLoader.new()
	screen.set("resource_loader", backend)
	scene_runner(screen)
	backend.states[GAME] = ResourceLoader.THREAD_LOAD_FAILED
	screen.call("_process", 0.1)
	var retry := screen.find_child("RetryButton") as Button
	assert_that(retry.visible).is_true()
	retry.pressed.emit()
	retry.pressed.emit()
	assert_that(backend.requests.count(GAME)).is_equal(2)
	assert_that(retry.visible).is_false()
	screen.set_process(false)


func test_stalled_resource_preparation_stops_with_retry() -> void:
	var screen: Control = auto_free(load("res://scenes/main/loading.tscn").instantiate())
	assert_that(screen.get("resource_loader")).is_not_null()
	if screen.get("resource_loader") == null:
		return
	screen.set("resource_loader", FakeLoader.new())
	var restarts: Array[bool] = []
	screen.set("restart_application", func() -> Error:
		restarts.append(true)
		return OK
	)
	scene_runner(screen)
	screen.call("_process", 21.0)
	assert_that(screen.is_processing()).is_false()
	assert_that((screen.find_child("RetryButton") as Button).visible).is_true()
	assert_that((screen.find_child("LoadPhase") as Label).text).contains("시간")
	var retry := screen.find_child("RetryButton") as Button
	retry.pressed.emit()
	retry.pressed.emit()
	assert_that(restarts.size()).is_equal(1)
	assert_that(retry.disabled).is_true()
	screen.set_process(false)
