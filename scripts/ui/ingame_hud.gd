extends Control

signal menu_requested(menu: String, source: Button)

const ICONS := preload("res://assets/ui/ingame_icons.svg")
const PROFILE := preload("res://scenes/ui/player_profile.tscn")
const STAGE := preload("res://scenes/ui/stage_banner.tscn")
const MISSION := preload("res://scenes/ui/mission_progress_panel.tscn")
const NAVIGATION := preload("res://scenes/ui/main_navigation.tscn")
const VERSION := preload("res://scripts/ui/version_label.gd")

var _state: PrototypeState
var _profile: PanelContainer
var _currency: PanelContainer
var _settings: Button
var _stage: Control
var _actions: VBoxContainer
var _mission: PanelContainer
var _navigation: BoxContainer
var _version: Label
var _notice: Label
var _level_value: Label
var _gold_value: Label
var _stage_value: Label
var _auxiliary_buttons: Array[Button] = []


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	_build_profile()
	_build_currency()
	_settings = _action_button("SettingsButton", "설정", 6, "settings")
	add_child(_settings)
	_build_stage()
	_actions = VBoxContainer.new()
	_actions.name = "AuxiliaryMenus"
	_actions.add_theme_constant_override("separation", 8)
	add_child(_actions)
	for item in [["EventButton", "이벤트", 7, "event"], ["MissionButton", "미션", 8, "mission"]]:
		_actions.add_child(_action_button(item[0], item[1], item[2], item[3]))
	_build_mission()
	_navigation = NAVIGATION.instantiate()
	add_child(_navigation)
	_navigation.connect("menu_requested", func(menu: String, source: Button): menu_requested.emit(menu, source))
	_version = _label("PreviewBadge", "", 11)
	_version.set_script(VERSION)
	_version.set("prefix", "둘러보기 · ")
	add_child(_version)
	_own_nodes(self)
	resized.connect(_layout)
	_layout()


func _build_profile() -> void:
	_profile = PROFILE.instantiate()
	add_child(_profile)
	_level_value = _profile.find_child("LevelValue") as Label


func _build_currency() -> void:
	_currency = PanelContainer.new()
	_currency.name = "CurrencyPanel"
	add_child(_currency)
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 5)
	_currency.add_child(row)
	row.add_child(_icon(0, 25))
	_gold_value = _label("GoldValue", "골드 —", 17)
	_gold_value.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_gold_value.clip_text = true
	row.add_child(_gold_value)


func _build_stage() -> void:
	_stage = STAGE.instantiate()
	add_child(_stage)
	_stage_value = _stage.find_child("StageValue") as Label
	_notice = _label("PrototypeNotice", "둘러보기 · 전투 준비 중", 12)
	_notice.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_notice.tooltip_text = "산책 연출과 초기 정보 화면이에요. 전투·성장·보상·저장은 아직 준비 중이에요."
	var caption_paper := StyleBoxFlat.new()
	caption_paper.bg_color = Color(1.0, 0.98, 0.91, 0.9)
	caption_paper.corner_radius_top_left = 5
	caption_paper.corner_radius_top_right = 5
	caption_paper.corner_radius_bottom_left = 5
	caption_paper.corner_radius_bottom_right = 5
	_notice.add_theme_stylebox_override("normal", caption_paper)
	add_child(_notice)


func _build_mission() -> void:
	_mission = MISSION.instantiate()
	add_child(_mission)


func _action_button(node_name: String, title: String, icon_index: int, menu: String) -> Button:
	var button := Button.new()
	button.name = node_name
	button.text = "%s · 준비 중" % title
	button.tooltip_text = button.text
	button.custom_minimum_size = Vector2(68, 68)
	button.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	button.add_theme_font_size_override("font_size", 1)
	for color_key in ["font_color", "font_hover_color", "font_pressed_color", "font_focus_color", "font_disabled_color"]:
		button.add_theme_color_override(color_key, Color.TRANSPARENT)
	var content := VBoxContainer.new()
	button.add_child(content)
	content.mouse_filter = Control.MOUSE_FILTER_IGNORE
	content.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	content.offset_top = 5
	content.offset_bottom = -5
	content.alignment = BoxContainer.ALIGNMENT_CENTER
	content.add_theme_constant_override("separation", 1)
	content.add_child(_icon(icon_index, 27))
	var label := _label("Caption", title, 14)
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	content.add_child(label)
	var lock_icon := _icon(9, 12)
	button.add_child(lock_icon)
	lock_icon.set_anchors_and_offsets_preset(Control.PRESET_TOP_RIGHT)
	lock_icon.offset_left = -17
	lock_icon.offset_right = -3
	lock_icon.offset_top = 3
	lock_icon.offset_bottom = 17
	button.pressed.connect(func(): menu_requested.emit(menu, button))
	_auxiliary_buttons.append(button)
	return button


func _icon(index: int, side: int) -> TextureRect:
	var icon := TextureRect.new()
	var atlas := AtlasTexture.new()
	atlas.atlas = ICONS
	atlas.region = Rect2(index * 32, 0, 32, 32)
	icon.texture = atlas
	icon.custom_minimum_size = Vector2(side, side)
	icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return icon


func _label(node_name: String, text: String, font_size: int) -> Label:
	var label := Label.new()
	label.name = node_name
	label.text = text
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	label.add_theme_font_size_override("font_size", font_size)
	return label


func bind_state(state: PrototypeState) -> void:
	if _state and _state.changed.is_connected(refresh_state):
		_state.changed.disconnect(refresh_state)
	_state = state
	if _state:
		_state.changed.connect(refresh_state)
	refresh_state()


func refresh_state() -> void:
	if _state == null:
		_level_value.text = "Lv. —"
		_gold_value.text = "골드 —"
		_stage_value.text = "모험을 준비해요"
		_notice.text = "초기 정보를 읽지 못했어요"
		return
	_level_value.text = "Lv. %d" % _state.level
	var amount := str(_state.gold)
	var groups: PackedStringArray = []
	while amount.length() > 3:
		groups.insert(0, amount.right(3))
		amount = amount.left(amount.length() - 3)
	groups.insert(0, amount)
	_gold_value.tooltip_text = "골드 %s" % ",".join(groups)
	var compact := str(_state.gold)
	if _state.gold >= 100000000:
		compact = "%s억" % String.num(floorf(_state.gold / 10000000.0) / 10.0, 1)
	elif _state.gold >= 10000:
		compact = "%s만" % String.num(floorf(_state.gold / 1000.0) / 10.0, 1)
	_gold_value.text = "골드 %s" % compact
	_stage_value.text = "%s  %s" % [_state.stage_id, _state.stage_name]
	_stage_value.tooltip_text = _stage_value.text


func set_menu_open(menu: String, opened: bool) -> void:
	_navigation.call("set_selected", menu if opened else "battle")
	_navigation.call("set_blocked", opened)
	for button in _auxiliary_buttons:
		button.disabled = opened


func _layout() -> void:
	if not is_instance_valid(_navigation) or size.x < 1:
		return
	var landscape := size.x > size.y
	_navigation.vertical = landscape
	if landscape:
		_place(_profile, Rect2(12, 12, 266, 64))
		_place(_currency, Rect2(290, 12, 164, 44))
		_place(_settings, Rect2(466, 12, 68, 68))
		_place(_version, Rect2(544, 32, 140, 18))
		_place(_stage, Rect2((size.x - 104 - 312) * 0.5, 85, 312, 59))
		_place(_notice, Rect2((size.x - 104 - 300) * 0.5, 145, 300, 20))
		_place(_actions, Rect2(12, 102, 68, 144))
		_place(_mission, Rect2(100, size.y - 78, size.x - 240, 66))
		_place(_navigation, Rect2(size.x - 104, 12, 92, size.y - 24))
	else:
		_place(_profile, Rect2(8, 10, 232, 70))
		_place(_currency, Rect2(248, 12, 144, 44))
		_place(_settings, Rect2(size.x - 76, 10, 68, 68))
		_place(_version, Rect2(250, 61, 150, 18))
		_place(_stage, Rect2((size.x - 320) * 0.5, 92, 320, 61))
		_place(_notice, Rect2((size.x - 290) * 0.5, 154, 290, 20))
		_place(_actions, Rect2(12, 181, 68, 144))
		_place(_mission, Rect2(12, size.y - 148, size.x - 24, 66))
		_place(_navigation, Rect2(12, size.y - 76, size.x - 24, 68))


func _place(control: Control, rect: Rect2) -> void:
	control.position = rect.position
	control.size = rect.size


func _own_nodes(parent: Node) -> void:
	for child in parent.get_children():
		if child.owner == null:
			child.owner = self
		_own_nodes(child)
