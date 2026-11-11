extends "res://scripts/ui/start_screen.gd"

const NEXT_SCENE := "res://scenes/main/loading.tscn"
const DISPLAY_SECONDS := 1.2
var _elapsed := 0.0


func _ready() -> void:
	super._ready()
	$WarriorArt.modulate.a = 0.0
	create_tween().tween_property($WarriorArt, "modulate:a", 1.0, 0.6)


func _process(delta: float) -> void:
	_elapsed += delta
	if _elapsed >= DISPLAY_SECONDS:
		set_process(false)
		call_deferred("_open_loading")


func _open_loading() -> void:
	if not is_inside_tree():
		return
	var error := get_tree().change_scene_to_file(NEXT_SCENE)
	if error != OK:
		($Footer/PhaseLabel as Label).text = "시작 준비에 실패했어요. 다시 실행해 주세요."
		push_error("Splash에서 Loading 씬으로 이동하지 못했습니다: %s" % error)
