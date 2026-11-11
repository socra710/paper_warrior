extends BoxContainer

signal menu_requested(menu: String, source: Button)

const ICONS := preload("res://assets/ui/ingame_icons.svg")
const ITEMS := [
	["battle", "BattleButton", "전투", 1],
	["growth", "GrowthButton", "성장", 2],
	["equipment", "EquipmentButton", "장비", 3],
	["decoration", "DecorationButton", "꾸미기", 4],
	["shop", "ShopButton", "상점", 5],
]

var buttons: Array[Button] = []
var selected_menu := "battle"


func _ready() -> void:
	add_theme_constant_override("separation", 4)
	for item in ITEMS:
		var button := Button.new()
		button.name = item[1]
		button.text = item[2] if item[0] == "battle" else "%s · 준비 중" % item[2]
		button.tooltip_text = button.text
		button.custom_minimum_size = Vector2(68, 68)
		button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		button.size_flags_vertical = Control.SIZE_EXPAND_FILL
		button.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
		button.set_meta("menu_id", item[0])
		# 안내용 이름은 유지하고, 보이는 아이콘과 글자는 세로로 배치한다.
		button.add_theme_font_size_override("font_size", 1)
		for color_key in ["font_color", "font_hover_color", "font_pressed_color", "font_focus_color", "font_disabled_color"]:
			button.add_theme_color_override(color_key, Color.TRANSPARENT)
		add_child(button)
		var content := VBoxContainer.new()
		content.mouse_filter = Control.MOUSE_FILTER_IGNORE
		button.add_child(content)
		content.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		content.offset_top = 7
		content.offset_bottom = -5
		content.alignment = BoxContainer.ALIGNMENT_CENTER
		content.add_theme_constant_override("separation", 2)
		var icon := TextureRect.new()
		var atlas := AtlasTexture.new()
		atlas.atlas = ICONS
		atlas.region = Rect2(item[3] * 32, 0, 32, 32)
		icon.texture = atlas
		icon.custom_minimum_size = Vector2(28, 28)
		icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
		content.add_child(icon)
		var label := Label.new()
		label.text = item[2]
		label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		label.add_theme_font_size_override("font_size", 15)
		label.mouse_filter = Control.MOUSE_FILTER_IGNORE
		content.add_child(label)
		if item[0] != "battle":
			var lock_icon := TextureRect.new()
			var lock_atlas := AtlasTexture.new()
			lock_atlas.atlas = ICONS
			lock_atlas.region = Rect2(288, 0, 32, 32)
			lock_icon.texture = lock_atlas
			lock_icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
			lock_icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
			button.add_child(lock_icon)
			lock_icon.set_anchors_and_offsets_preset(Control.PRESET_TOP_RIGHT)
			lock_icon.offset_left = -19
			lock_icon.offset_right = -5
			lock_icon.offset_top = 5
			lock_icon.offset_bottom = 19
		button.pressed.connect(func(): menu_requested.emit(item[0], button))
		buttons.append(button)
	set_selected("battle")


func set_selected(menu: String) -> void:
	selected_menu = menu
	for button in buttons:
		button.add_theme_stylebox_override("normal", get_theme_stylebox(
			"selected" if button.get_meta("menu_id") == menu else "normal", "Button"))


func set_blocked(blocked: bool) -> void:
	for button in buttons:
		button.disabled = blocked
