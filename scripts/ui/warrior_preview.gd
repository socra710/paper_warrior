extends Control


func _ready() -> void:
	resized.connect(_center_sprite)
	_center_sprite()


func _center_sprite() -> void:
	$WarriorSprite.position = size * 0.5
