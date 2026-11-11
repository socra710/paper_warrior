extends Control

const NEXT_SCENE := "res://scenes/main/game.tscn"

@onready var start_button: Button = %StartButton


func _ready() -> void:
	start_button.pressed.connect(_on_start_pressed)


func _exit_tree() -> void:
	if ResourceLoader.load_threaded_get_status(NEXT_SCENE) == ResourceLoader.THREAD_LOAD_LOADED:
		ResourceLoader.load_threaded_get(NEXT_SCENE)


func _on_start_pressed() -> void:
	call_deferred("_change_to_game_scene")


func _change_to_game_scene() -> void:
	var game: PackedScene
	if ResourceLoader.load_threaded_get_status(NEXT_SCENE) == ResourceLoader.THREAD_LOAD_LOADED:
		game = ResourceLoader.load_threaded_get(NEXT_SCENE) as PackedScene
	else:
		game = load(NEXT_SCENE) as PackedScene
	if game == null:
		push_error("준비한 게임 화면을 열지 못했습니다.")
		return
	var error := get_tree().change_scene_to_packed(game)
	if error != OK:
		push_error("Title에서 Main Game 씬으로 이동하지 못했습니다: %s" % error)
