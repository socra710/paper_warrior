extends GdUnitTestSuite


func test_splash_is_a_logo_intro_without_loading_or_title_controls() -> void:
	var runner := scene_runner("res://scenes/main/splash.tscn")
	var screen := runner.scene()
	screen.set_process(false)
	assert_that(screen.find_child("SplashLogo")).is_not_null()
	for name in ["WarriorSprite", "LoadProgress", "RetryButton", "StartButton"]:
		assert_that(screen.find_child(name)).is_null()


func test_failed_initial_transition_stays_visible_without_repeating() -> void:
	var screen: Control = auto_free(load("res://scenes/main/splash.tscn").instantiate())
	assert_that(screen.get("scene_change")).is_not_null()
	if screen.get("scene_change") == null:
		return
	var calls: Array[String] = []
	screen.set("scene_change", func(path: String) -> Error:
		calls.append(path)
		return ERR_CANT_OPEN
	)
	var runner := scene_runner(screen)
	screen.call("_process", 1.3)
	await runner.simulate_frames(2)
	screen.call("_process", 1.3)
	await runner.simulate_frames(2)
	assert_that(calls.size()).is_equal(1)
	assert_that(screen.is_inside_tree()).is_true()
	assert_that((screen.find_child("StartupError") as Label).visible).is_true()
	assert_that(screen.modulate.a).is_equal(1.0)


func test_removed_intro_does_not_run_its_deferred_transition() -> void:
	var screen: Control = auto_free(load("res://scenes/main/splash.tscn").instantiate())
	assert_that(screen.get("scene_change")).is_not_null()
	if screen.get("scene_change") == null:
		return
	var calls: Array[String] = []
	screen.set("scene_change", func(path: String) -> Error:
		calls.append(path)
		return OK
	)
	var runner := scene_runner(screen)
	screen.call("_process", 1.3)
	screen.get_parent().remove_child(screen)
	await runner.simulate_frames(2)
	assert_that(calls).is_empty()
