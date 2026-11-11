extends "res://scripts/ui/responsive_screen.gd"


func _update_layout() -> void:
	var landscape := size.x > size.y
	$TopLine.offset_top = 14.0 if landscape else 24.0
	$TopLine.offset_bottom = 15.0 if landscape else 25.0
	$Eyebrow.offset_top = 24.0 if landscape else 45.0
	$Eyebrow.offset_bottom = 45.0 if landscape else 66.0
	$GameTitle.offset_top = 58.0 if landscape else 79.0
	$GameTitle.offset_bottom = 123.0 if landscape else 179.0
	$Subtitle.offset_top = 132.0 if landscape else 190.0
	$Subtitle.offset_bottom = 154.0 if landscape else 216.0
	$Subtitle.add_theme_font_size_override("font_size", 16)
	$WarriorArt.set_anchors_preset(Control.PRESET_TOP_LEFT)
	$Footer.set_anchors_preset(Control.PRESET_TOP_LEFT)
	if landscape:
		$WarriorArt.position = Vector2(36, 150)
		$WarriorArt.size = Vector2(size.x * 0.46 - 36, size.y - 174)
		$Footer.position = Vector2(size.x * 0.54, 158)
		$Footer.size = Vector2(size.x * 0.46 - 32, size.y - 186)
	else:
		$WarriorArt.position = Vector2(25, 220)
		$WarriorArt.size = Vector2(size.x - 50, 290)
		$Footer.position = Vector2(42, size.y - 126)
		$Footer.size = Vector2(size.x - 84, 99)
