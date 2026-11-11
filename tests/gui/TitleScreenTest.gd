extends GdUnitTestSuite


func test_title_uses_galmuri_heading_and_pretendard_ui() -> void:
	var runner := scene_runner("res://scenes/main/title.tscn")
	var scene := runner.scene()
	var heading := scene.find_child("GameTitle") as Label
	var start_button := scene.find_child("StartButton") as Button

	assert_that(heading.get_theme_default_font().resource_path.get_file()).is_equal("Galmuri11-Bold.ttf")
	assert_that(start_button.get_theme_default_font().resource_path.get_file()).is_equal("Pretendard-Regular.otf")


func test_title_shows_warrior_art_and_prototype_notice() -> void:
	var runner := scene_runner("res://scenes/main/title.tscn")
	var scene := runner.scene()
	var illustration := scene.find_child("WarriorArt") as TextureRect
	var notice := scene.find_child("PrototypeNotice") as Label

	assert_that(illustration).is_not_null()
	assert_that(notice).is_not_null()
	if illustration == null or notice == null:
		return
	assert_that(illustration.texture).is_not_null()
	assert_that(notice.text).contains("프로토타입")


func test_loading_transitions_to_title() -> void:
	var runner := scene_runner("res://scenes/main/loading.tscn")
	get_tree().current_scene = runner.scene()
	await assert_func(self, "_current_scene_path").wait_until(2500).is_equal("res://scenes/main/title.tscn")


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


func test_start_button_enters_empty_main_game() -> void:
	var runner := scene_runner("res://scenes/main/title.tscn")
	var title_scene := runner.scene()
	var start_button := title_scene.find_child("StartButton") as Button

	get_tree().current_scene = title_scene
	runner.set_mouse_position(start_button.get_global_rect().get_center())
	runner.simulate_mouse_button_pressed(MOUSE_BUTTON_LEFT)
	await runner.simulate_frames(2)

	var main_game := get_tree().current_scene
	assert_that(main_game.scene_file_path).is_equal("res://scenes/main/game.tscn")
	assert_that(main_game.get_child_count()).is_equal(0)
