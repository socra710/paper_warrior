extends Control

const NEXT_SCENE := "res://scenes/main/loading.tscn"
const DISPLAY_SECONDS := 1.2


func _ready() -> void:
	$WarriorArt.modulate.a = 0.0
	create_tween().tween_property($WarriorArt, "modulate:a", 1.0, 0.6)
	await get_tree().create_timer(DISPLAY_SECONDS).timeout
	var error := get_tree().change_scene_to_file(NEXT_SCENE)
	if error != OK:
		push_error("Splash에서 Loading 씬으로 이동하지 못했습니다: %s" % error)
