extends Control

const NEXT_SCENE := "res://scenes/main/game.tscn"

@onready var start_button: Button = %StartButton


func _ready() -> void:
	start_button.pressed.connect(_on_start_pressed)


func _on_start_pressed() -> void:
	call_deferred("_change_to_game_scene")


func _change_to_game_scene() -> void:
	var error := get_tree().change_scene_to_file(NEXT_SCENE)
	if error != OK:
		push_error("Title에서 Main Game 씬으로 이동하지 못했습니다: %s" % error)
