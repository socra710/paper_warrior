extends GdUnitTestSuite


func test_small_pixel_warrior_walks_inside_the_map() -> void:
	var runner := scene_runner("res://scenes/main/game.tscn")
	var scene := runner.scene()
	var walker := scene.find_child("MapWalker") as Control
	var warrior := scene.find_child("WarriorSprite") as AnimatedSprite2D
	assert_that(walker).is_not_null()
	assert_that(warrior).is_not_null()
	if walker == null or warrior == null:
		return
	await runner.simulate_frames(2)
	var initial_position := warrior.position
	walker.call("_process", 1.0)
	assert_that(warrior.position.distance_to(initial_position)).is_greater(0.1)
	assert_that(Rect2(Vector2.ZERO, walker.size).has_point(warrior.position)).is_true()
	assert_that(warrior.scale.x <= 2.0).is_true()
	assert_that(warrior.sprite_frames.get_frame_count("walk")).is_equal(6)
	assert_that(warrior.is_playing()).is_true()


func test_rotation_preserves_game_and_open_menu_with_no_clipped_controls() -> void:
	var runner := scene_runner("res://scenes/main/game.tscn")
	var scene := runner.scene()
	await runner.simulate_frames(2)
	var original_size := get_window().size
	(scene.find_child("EquipmentButton") as Button).pressed.emit()
	var original_gold := (scene.find_child("GoldValue") as Label).text
	get_window().size = Vector2i(960, 540)
	await runner.simulate_frames(5)
	assert_that(scene.size.x > scene.size.y).is_true()
	assert_that((scene.find_child("MenuNotice") as Control).visible).is_true()
	assert_that((scene.find_child("GoldValue") as Label).text).is_equal(original_gold)
	for name in ["BattleArea", "GrowthButton", "EquipmentButton", "DecorationButton", "PrototypeNotice"]:
		var bounds := (scene.find_child(name) as Control).get_global_rect()
		assert_that(bounds.position.x >= 0.0 and bounds.position.y >= 0.0 and bounds.end.x <= scene.size.x and bounds.end.y <= scene.size.y).is_true()
	get_window().size = original_size
	await runner.simulate_frames(5)
	assert_that((scene.find_child("MenuNotice") as Control).visible).is_true()
	assert_that((scene.find_child("MenuNoticeTitle") as Label).text).contains("장비")


func test_unavailable_menus_explain_their_status_and_can_be_closed() -> void:
	var runner := scene_runner("res://scenes/main/game.tscn")
	var scene := runner.scene()
	var overlay := scene.find_child("MenuNotice") as Control
	assert_that(overlay).is_not_null()
	if overlay == null:
		return
	await runner.simulate_frames(2)
	for menu_name in ["GrowthButton", "EquipmentButton", "DecorationButton"]:
		var button := scene.find_child(menu_name) as Button
		assert_that(button.get_theme_font("font").resource_path).contains("Pretendard")
		runner.set_mouse_position(button.get_global_rect().get_center())
		runner.simulate_mouse_button_pressed(MOUSE_BUTTON_LEFT)
		await runner.simulate_frames(2)
		assert_that(overlay.visible).is_true()
		assert_that((scene.find_child("MenuNoticeTitle") as Label).text).is_equal(button.text)
		if menu_name == "DecorationButton":
			runner.simulate_key_pressed(KEY_ESCAPE)
		else:
			var close := scene.find_child("CloseNotice") as Button
			runner.set_mouse_position(close.get_global_rect().get_center())
			runner.simulate_mouse_button_pressed(MOUSE_BUTTON_LEFT)
		await runner.simulate_frames(2)
		assert_that(overlay.visible).is_false()
		assert_that(button.has_focus()).is_true()
