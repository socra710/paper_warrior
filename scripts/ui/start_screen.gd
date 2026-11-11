extends "res://scripts/ui/responsive_screen.gd"


func _update_layout() -> void:
	var landscape := size.x > size.y
	$Eyebrow.offset_top = 24.0 if landscape else 45.0
	$Eyebrow.offset_bottom = 45.0 if landscape else 66.0
	$GameTitle.offset_top = 48.0 if landscape else 79.0
	$GameTitle.offset_bottom = 104.0 if landscape else 154.0
	$GameTitle.add_theme_font_size_override("font_size", 42 if landscape else 64)
	$Subtitle.offset_top = 110.0 if landscape else 157.0
	$Subtitle.offset_bottom = 142.0 if landscape else 183.0
	$Subtitle.add_theme_font_size_override("font_size", 14 if landscape else 17)
	$WarriorArt.set_anchors_preset(Control.PRESET_TOP_LEFT)
	$Footer.set_anchors_preset(Control.PRESET_TOP_LEFT)
	if landscape:
		$WarriorArt.position = Vector2(36, 150)
		$WarriorArt.size = Vector2(size.x * 0.46 - 36, size.y - 174)
		$Footer.position = Vector2(size.x * 0.54, 158)
		$Footer.size = Vector2(size.x * 0.46 - 32, size.y - 186)
	else:
		$WarriorArt.position = Vector2(25, 185)
		$WarriorArt.size = Vector2(size.x - 50, 325)
		$Footer.position = Vector2(42, size.y - 126)
		$Footer.size = Vector2(size.x - 84, 99)
