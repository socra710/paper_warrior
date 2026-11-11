extends SceneTree

var _observed_scenes: Array[String] = []


func _initialize() -> void:
	call_deferred("_check")


func _check() -> void:
	var flow_valid: bool = await _check_startup_flow()
	if not flow_valid:
		quit(1)
		return
	var scene: Control = load("res://scenes/main/title.tscn").instantiate()
	root.add_child(scene)
	await process_frame
	await process_frame
	var art := scene.find_child("WarriorArt") as Control
	var heading := scene.find_child("GameTitle") as TextureRect
	var subtitle := scene.find_child("Subtitle") as Label
	var button := scene.find_child("StartButton") as Button
	var valid := (
		art.size.y > 200.0
		and art.position.y >= 180.0
		and heading.position.y > 0.0
		and subtitle.position.y >= heading.get_rect().end.y
		and button.get_global_rect().position.x > 0.0
		and button.get_global_rect().end.x < scene.size.x
	)
	if not valid:
		push_error("Exported startup layout is invalid: art=%s, heading=%s, subtitle=%s, button=%s" % [
			art.get_global_rect(), heading.get_global_rect(), subtitle.get_global_rect(), button.get_global_rect()
		])
	scene.queue_free()
	await process_frame
	var game: Control = load("res://scenes/main/game.tscn").instantiate()
	root.add_child(game)
	await process_frame
	await process_frame
	var arena := game.find_child("BattleArea") as Control
	var warrior := game.find_child("WarriorSprite") as AnimatedSprite2D
	var state := game.get("initial_state") as Resource
	var game_valid := (
		state != null
		and (game.find_child("LevelValue") as Label).text == "Lv. 1"
		and (game.find_child("GoldValue") as Label).text == "골드 0"
		and (game.find_child("StageValue") as Label).text.contains("1-1")
		and arena.size.y >= 184.0
		and warrior.sprite_frames.get_frame_count("idle") == 4
		and warrior.sprite_frames.get_frame_count("walk") == 6
		and warrior.is_playing()
		and warrior.scale.x <= 2.0
		and game.find_child("BackgroundForest") != null
		and game.find_child("BackgroundStructures") != null
	)
	for name in ["LevelValue", "GoldValue", "StageValue", "BattleArea", "GrowthButton", "EquipmentButton", "DecorationButton", "PrototypeNotice"]:
		var control := game.find_child(name) as Control
		var bounds := control.get_global_rect()
		game_valid = game_valid and bounds.position.x >= 0.0 and bounds.position.y >= 0.0
		game_valid = game_valid and bounds.end.x <= game.size.x and bounds.end.y <= game.size.y
	var paintings := game.find_child("PaperBackground").find_children("*", "TextureRect", true, false)
	game_valid = game_valid and not paintings.is_empty()
	for painting in paintings:
		var texture := (painting as TextureRect).texture
		game_valid = game_valid and texture != null and not texture.resource_path.is_empty()
	for layer_name in ["BackgroundSky", "BackgroundMountains", "BackgroundForest", "BackgroundStructures", "BattleGround", "ForegroundObjects"]:
		var layer := game.find_child(layer_name)
		game_valid = game_valid and layer != null
		if layer:
			game_valid = game_valid and not layer.find_children("*", "TextureRect", true, false).is_empty()
	if not game_valid:
		push_error("Exported game layout/resources are invalid: viewport=%s, arena=%s, warrior=%s, menus=%s" % [
			game.size, arena.get_global_rect(), warrior.position,
			(game.find_child("Menus") as Control).get_global_rect()
		])
	valid = valid and game_valid
	var old_size := root.size
	(game.find_child("EquipmentButton") as Button).pressed.emit()
	root.size = Vector2i(960, 540)
	for index in 5:
		await process_frame
	var landscape_valid := game.size.x > game.size.y and (game.find_child("MenuNotice") as Control).visible
	for name in ["BattleArea", "GrowthButton", "EquipmentButton", "DecorationButton", "PrototypeNotice"]:
		var bounds := (game.find_child(name) as Control).get_global_rect()
		landscape_valid = landscape_valid and bounds.position.x >= 0.0 and bounds.position.y >= 0.0
		landscape_valid = landscape_valid and bounds.end.x <= game.size.x and bounds.end.y <= game.size.y
	if not landscape_valid:
		push_error("Exported landscape layout/state is invalid: viewport=%s, arena=%s, menus=%s" % [
			game.size, arena.get_global_rect(), (game.find_child("Menus") as Control).get_global_rect()
		])
	valid = valid and landscape_valid
	root.size = old_size
	for index in 3:
		await process_frame
	valid = valid and (game.find_child("MenuNotice") as Control).visible
	game.queue_free()
	await process_frame
	quit(0 if valid else 1)


func _check_startup_flow() -> bool:
	var error := change_scene_to_file("res://scenes/main/splash.tscn")
	if error != OK:
		push_error("Exported Splash could not start: %s" % error)
		return false
	var reached_title: bool = await _wait_for_scene("res://scenes/main/title.tscn")
	if not reached_title:
		return false
	if ResourceLoader.load_threaded_get_status("res://scenes/main/game.tscn") != ResourceLoader.THREAD_LOAD_LOADED:
		push_error("Exported Title appeared before Game resources were ready.")
		return false
	(current_scene.find_child("StartButton") as Button).pressed.emit()
	var reached_game: bool = await _wait_for_scene("res://scenes/main/game.tscn")
	if not reached_game:
		return false
	var expected: Array[String] = [
		"res://scenes/main/splash.tscn", "res://scenes/main/loading.tscn",
		"res://scenes/main/title.tscn", "res://scenes/main/game.tscn",
	]
	if _observed_scenes != expected:
		push_error("Exported startup skipped or repeated a screen: %s" % [_observed_scenes])
		return false
	var game := current_scene
	current_scene = null
	game.queue_free()
	await process_frame
	print("Exported Splash -> Loading -> Title -> Game flow verified.")
	return true


func _wait_for_scene(path: String) -> bool:
	var deadline := Time.get_ticks_msec() + 10000
	while Time.get_ticks_msec() < deadline:
		if current_scene != null:
			var observed := current_scene.scene_file_path
			if _observed_scenes.is_empty() or _observed_scenes.back() != observed:
				_observed_scenes.append(observed)
		if current_scene != null and current_scene.scene_file_path == path:
			return true
		await process_frame
	push_error("Exported startup timed out before reaching %s." % path)
	return false
