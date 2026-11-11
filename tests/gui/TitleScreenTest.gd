extends GdUnitTestSuite


func test_title_uses_galmuri_heading_and_pretendard_ui() -> void:
	var runner := scene_runner("res://scenes/main/title.tscn")
	var scene := runner.scene()
	var heading := scene.find_child("Eyebrow") as Label
	var logo := scene.find_child("GameTitle") as TextureRect
	var start_button := scene.find_child("StartButton") as Button

	assert_that(heading.get_theme_default_font().resource_path.get_file()).is_equal("Galmuri11-Bold.ttf")
	assert_that(start_button.get_theme_default_font().resource_path.get_file()).is_equal("Pretendard-Regular.otf")
	assert_that(logo.texture.resource_path).is_equal("res://assets/branding/logo_wordmark.png")


func test_title_shows_animated_pixel_warrior_version_and_prototype_notice() -> void:
	var runner := scene_runner("res://scenes/main/title.tscn")
	var scene := runner.scene()
	var illustration := scene.find_child("WarriorSprite") as AnimatedSprite2D
	var notice := scene.find_child("PrototypeNotice") as Label

	assert_that(illustration).is_not_null()
	assert_that(notice).is_not_null()
	if illustration == null or notice == null:
		return
	assert_that(illustration.is_playing()).is_true()
	assert_that(illustration.animation).is_equal(&"idle")
	await assert_func(illustration, "get_frame").wait_until(1800).is_equal(1)
	var version := scene.find_child("VersionLabel") as Label
	assert_that(version).is_not_null()
	if version != null:
		assert_that(version.text).is_equal("v%s" % ProjectSettings.get_setting("application/config/version"))
	assert_that(notice.text).contains("프로토타입")


func test_loading_prepares_game_resources_before_entering_title() -> void:
	var runner := scene_runner("res://scenes/main/loading.tscn")
	get_tree().current_scene = runner.scene()
	await assert_func(self, "_current_scene_path").wait_until(2500).is_equal("res://scenes/main/title.tscn")
	assert_that(ResourceLoader.load_threaded_get_status("res://scenes/main/game.tscn")).is_equal(ResourceLoader.THREAD_LOAD_LOADED)
	if ResourceLoader.load_threaded_get_status("res://scenes/main/game.tscn") == ResourceLoader.THREAD_LOAD_LOADED:
		assert_that(ResourceLoader.load_threaded_get("res://scenes/main/game.tscn")).is_not_null()


func test_loading_is_a_progress_screen_not_the_warrior_intro() -> void:
	var runner := scene_runner("res://scenes/main/loading.tscn")
	var scene := runner.scene()
	scene.set_process(false)
	assert_that(scene.find_child("LoadProgress")).is_not_null()
	assert_that(scene.find_child("WarriorArt")).is_null()
	for path in ["res://scenes/main/title.tscn", "res://scenes/main/game.tscn"]:
		assert_that(ResourceLoader.load_threaded_get(path)).is_not_null()


func test_closing_title_releases_prepared_game_without_starting() -> void:
	var runner := scene_runner("res://scenes/main/loading.tscn")
	get_tree().current_scene = runner.scene()
	await assert_func(self, "_current_scene_path").wait_until(2500).is_equal("res://scenes/main/title.tscn")
	var title := get_tree().current_scene
	get_tree().current_scene = null
	title.queue_free()
	await runner.simulate_frames(2)
	var status := ResourceLoader.load_threaded_get_status("res://scenes/main/game.tscn")
	assert_that(status).is_equal(ResourceLoader.THREAD_LOAD_INVALID_RESOURCE)
	if status == ResourceLoader.THREAD_LOAD_LOADED:
		ResourceLoader.load_threaded_get("res://scenes/main/game.tscn")


func _current_scene_path() -> String:
	var current := get_tree().current_scene
	return current.scene_file_path if current != null else ""


func test_galmuri_import_uses_outlines_for_web_rendering() -> void:
	var font_import := ConfigFile.new()
	var load_result := font_import.load("res://assets/fonts/Galmuri11-Bold.ttf.import")

	assert_that(load_result).is_equal(OK)
	if load_result != OK:
		return
	assert_that(font_import.get_value("params", "disable_embedded_bitmaps")).is_equal(true)


func test_start_press_immediately_locks_duplicate_transitions() -> void:
	var runner := scene_runner("res://scenes/main/title.tscn")
	var scene := runner.scene()
	get_tree().current_scene = scene
	var button := scene.find_child("StartButton") as Button
	button.pressed.emit()
	assert_that(button.disabled).is_true()
	button.pressed.emit()
	await runner.simulate_frames(2)
	assert_that(_current_scene_path()).is_equal("res://scenes/main/game.tscn")


func test_start_button_enters_game_with_player_state_and_idle_warrior() -> void:
	var runner := scene_runner("res://scenes/main/title.tscn")
	var title_scene := runner.scene()
	var start_button := title_scene.find_child("StartButton") as Button
	await runner.simulate_frames(2)

	get_tree().current_scene = title_scene
	runner.set_mouse_position(start_button.get_global_rect().get_center())
	runner.simulate_mouse_button_pressed(MOUSE_BUTTON_LEFT)
	await runner.simulate_frames(2)

	var main_game := get_tree().current_scene
	assert_that(main_game.scene_file_path).is_equal("res://scenes/main/game.tscn")
	var level := main_game.find_child("LevelValue") as Label
	var gold := main_game.find_child("GoldValue") as Label
	var idle := main_game.find_child("WarriorSprite") as AnimatedSprite2D
	assert_that(level).is_not_null()
	assert_that(gold).is_not_null()
	assert_that(idle).is_not_null()
	if level == null or gold == null or idle == null:
		return
	assert_that(level.text).is_equal("Lv. 1")
	assert_that(gold.text).is_equal("골드 0")
	assert_that(idle.is_playing()).is_true()
