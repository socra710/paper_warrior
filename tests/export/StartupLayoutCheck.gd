extends SceneTree


func _initialize() -> void:
	call_deferred("_check")


func _check() -> void:
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
	quit(0 if valid else 1)
