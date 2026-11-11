extends "res://scripts/ui/start_screen.gd"

const NEXT_SCENE := "res://scenes/main/game.tscn"

@onready var start_button: Button = %StartButton
var _starting := false


func _ready() -> void:
	super._ready()
	start_button.pressed.connect(_on_start_pressed)


func _exit_tree() -> void:
	if ResourceLoader.load_threaded_get_status(NEXT_SCENE) == ResourceLoader.THREAD_LOAD_LOADED:
		ResourceLoader.load_threaded_get(NEXT_SCENE)


func _on_start_pressed() -> void:
	if _starting:
		return
	_starting = true
	start_button.disabled = true
	call_deferred("_change_to_game_scene")


func _change_to_game_scene() -> void:
	if not is_inside_tree():
		return
	var game: PackedScene
	if ResourceLoader.load_threaded_get_status(NEXT_SCENE) == ResourceLoader.THREAD_LOAD_LOADED:
		game = ResourceLoader.load_threaded_get(NEXT_SCENE) as PackedScene
	else:
		game = load(NEXT_SCENE) as PackedScene
	if game == null:
		_show_start_error("게임 화면을 열지 못했어요. 다시 시작해 주세요.")
		return
	var error := get_tree().change_scene_to_packed(game)
	if error != OK:
		_show_start_error("게임 화면으로 이동하지 못했어요: %s" % error)


func _show_start_error(message: String) -> void:
	_starting = false
	start_button.disabled = false
	($Footer/PrototypeNotice as Label).text = message
	push_error(message)
