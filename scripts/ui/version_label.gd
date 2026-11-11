extends Label

@export var prefix: String = ""


func _ready() -> void:
	text = ("%s v%s" % [prefix, ProjectSettings.get_setting("application/config/version")]).strip_edges()
