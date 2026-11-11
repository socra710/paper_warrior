extends SceneTree


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
	var art := scene.find_child("WarriorArt") as TextureRect
	var heading := scene.find_child("GameTitle") as Label
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
	var warrior := game.find_child("WarriorVisual") as TextureRect
	var animation := game.find_child("IdleAnimation") as AnimationPlayer
	var state := game.get("initial_state") as Resource
	var game_valid := (
		state != null
		and (game.find_child("LevelValue") as Label).text == "Lv. 1"
		and (game.find_child("GoldValue") as Label).text == "골드 0"
		and (game.find_child("StageValue") as Label).text.contains("1-1")
		and arena.size.y >= 184.0
		and warrior.texture != null
		and warrior.size.y > 140.0
		and animation.is_playing()
		and (game.find_child("Forest") as TextureRect).texture != null
	)
	for name in ["LevelValue", "GoldValue", "StageValue", "BattleArea", "GrowthButton", "EquipmentButton", "DecorationButton", "PrototypeNotice"]:
		var control := game.find_child(name) as Control
		var bounds := control.get_global_rect()
		game_valid = game_valid and bounds.position.x >= 0.0 and bounds.position.y >= 0.0
		game_valid = game_valid and bounds.end.x <= game.size.x and bounds.end.y <= game.size.y
	if not game_valid:
		push_error("Exported game layout/resources are invalid: viewport=%s, arena=%s, warrior=%s, menus=%s" % [
			game.size, arena.get_global_rect(), warrior.get_global_rect(),
			(game.find_child("Menus") as Control).get_global_rect()
		])
	valid = valid and game_valid
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
	var game := current_scene
	current_scene = null
	game.queue_free()
	await process_frame
	print("Exported Splash -> Loading -> Title -> Game flow verified.")
	return true


func _wait_for_scene(path: String) -> bool:
	var deadline := Time.get_ticks_msec() + 10000
	while Time.get_ticks_msec() < deadline:
		if current_scene != null and current_scene.scene_file_path == path:
			return true
		await process_frame
	push_error("Exported startup timed out before reaching %s." % path)
	return false
