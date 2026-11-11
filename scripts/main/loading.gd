extends Control

const NEXT_SCENE := "res://scenes/main/title.tscn"
const DISPLAY_SECONDS := 0.9


func _ready() -> void:
	var pulse := create_tween().set_loops()
	pulse.tween_property($Footer/PhaseLabel, "modulate:a", 0.4, 0.4)
	pulse.tween_property($Footer/PhaseLabel, "modulate:a", 1.0, 0.4)
	await get_tree().create_timer(DISPLAY_SECONDS).timeout
	var error := get_tree().change_scene_to_file(NEXT_SCENE)
	if error != OK:
		push_error("Loading에서 Title 씬으로 이동하지 못했습니다: %s" % error)
