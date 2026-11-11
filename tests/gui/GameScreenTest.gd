extends GdUnitTestSuite


func test_idle_animation_moves_the_warrior() -> void:
	var runner := scene_runner("res://scenes/main/game.tscn")
	var scene := runner.scene()
	var animation := scene.find_child("IdleAnimation") as AnimationPlayer
	var warrior := scene.find_child("WarriorVisual") as TextureRect
	assert_that(animation).is_not_null()
	assert_that(warrior).is_not_null()
	if animation == null or warrior == null:
		return
	animation.seek(0.0, true)
	var initial_position := warrior.position
	animation.advance(0.5)
	assert_that(warrior.position.distance_to(initial_position)).is_greater(0.1)


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
