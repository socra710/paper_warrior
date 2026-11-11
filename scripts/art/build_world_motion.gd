extends SceneTree

const ROOT := "res://assets/backgrounds/paper_forest_diorama/"


func _initialize() -> void:
	var original := Image.new()
	if original.load(ProjectSettings.globalize_path(ROOT + "windmill.png")) != OK:
		quit(1)
		return
	var body := Image.create_empty(150, 196, false, Image.FORMAT_RGBA8)
	body.blit_rect(original, Rect2i(0, 120, 150, 76), Vector2i(0, 120))
	var top := Image.new()
	var sails := Image.new()
	if top.load_svg_from_string(FileAccess.get_file_as_string(ROOT + "source/windmill_roof_body.svg")) != OK or sails.load_svg_from_string(FileAccess.get_file_as_string(ROOT + "source/windmill_sails.svg")) != OK:
		quit(1)
		return
	body.blend_rect(top, Rect2i(0, 0, 150, 196), Vector2i.ZERO)
	if body.save_png(ROOT + "windmill_body.png") != OK or sails.save_png(ROOT + "windmill_sails.png") != OK:
		quit(1)
		return
	print("Generated separate windmill body and centered rotating sails.")
	quit()
