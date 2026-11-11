extends GdUnitTestSuite


func test_redesigned_hud_binds_long_real_values_without_invented_currencies() -> void:
	var screen: Control = auto_free(load("res://scenes/main/game.tscn").instantiate())
	var state := PrototypeState.new()
	state.level = 9999
	state.gold = 999999999
	screen.set("initial_state", state)
	var runner := scene_runner(screen)
	await runner.simulate_frames(3)
	var gold := screen.find_child("GoldValue") as Label
	assert_that(gold.text).contains("억")
	assert_that(gold.tooltip_text).contains("999,999,999")
	assert_that(screen.find_child("PremiumCurrency")).is_null()
	var experience := screen.find_child("ExperienceValue") as Label
	assert_that(experience).is_not_null()
	if experience:
		assert_that(experience.text).contains("준비")
	var mission := screen.find_child("MissionStatus") as Label
	assert_that(mission).is_not_null()
	if mission:
		assert_that(mission.text).contains("준비")
	for node_name in ["LevelValue", "GoldValue"]:
		var control := screen.find_child(node_name) as Control
		assert_that(control.get_global_rect().end.x <= screen.size.x).is_true()
	state.gold = 12500
	state.emit_changed()
	await runner.simulate_frames(2)
	assert_that(gold.text).contains("만")


func test_redesigned_world_has_independent_layers_and_complete_navigation() -> void:
	var runner := scene_runner("res://scenes/main/game.tscn")
	var screen := runner.scene()
	await runner.simulate_frames(3)
	for node_name in ["BackgroundSky", "BackgroundMountains", "BackgroundForest", "BackgroundStructures", "BattleGround", "ForegroundObjects"]:
		var layer := screen.find_child(node_name)
		assert_that(layer).is_not_null()
		if layer:
			assert_that(layer.find_children("*", "TextureRect", true, false).is_empty()).is_false()
	var paintings := screen.find_child("PaperBackground").find_children("*", "TextureRect", true, false)
	for painting in paintings:
		assert_that((painting as TextureRect).texture.resource_path.begins_with("res://")).is_true()
	for node_name in ["BattleButton", "GrowthButton", "EquipmentButton", "DecorationButton", "ShopButton", "EventButton", "MissionButton", "SettingsButton"]:
		var button := screen.find_child(node_name) as Button
		assert_that(button).is_not_null()
		if button:
			assert_that(button.size.x >= 68 and button.size.y >= 68).is_true()


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
	for name in ["BattleArea", "BattleButton", "GrowthButton", "EquipmentButton", "DecorationButton", "ShopButton", "EventButton", "MissionButton", "SettingsButton", "PrototypeNotice"]:
		var bounds := (scene.find_child(name) as Control).get_global_rect()
		assert_that(bounds.position.x >= 0.0 and bounds.position.y >= 0.0 and bounds.end.x <= scene.size.x and bounds.end.y <= scene.size.y).is_true()
	for node_name in ["BattleButton", "GrowthButton", "EquipmentButton", "DecorationButton", "ShopButton", "EventButton", "MissionButton", "SettingsButton"]:
		var button := scene.find_child(node_name) as Control
		assert_that(button.size.x >= 68 and button.size.y >= 68).is_true()
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
	for menu_name in ["GrowthButton", "EquipmentButton", "DecorationButton", "ShopButton", "EventButton", "MissionButton", "SettingsButton"]:
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
