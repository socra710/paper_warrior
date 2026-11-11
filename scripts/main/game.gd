extends "res://scripts/ui/responsive_screen.gd"

const MENU_NOTICES := {
	"growth": ["성장 · 준비 중", "접기와 겹치기로 성장하는 기능을 준비해요.\n지금은 레벨과 골드가 변하지 않아요."],
	"equipment": ["장비 · 준비 중", "무기와 방패를 장착하는 기능을 준비해요.\n현재 검과 방패는 대기 연출용이에요."],
	"decoration": ["꾸미기 · 준비 중", "색과 문양, 작은 장식을 더할 예정이에요.\n지금은 전사 모습을 변경할 수 없어요."],
}

@export var initial_state: PrototypeState
var _last_menu: Button


func _ready() -> void:
	super._ready()
	if initial_state == null:
		push_error("게임 화면의 초기 상태 Resource가 없습니다.")
		%StageValue.text = "초기 상태를 읽지 못했어요"
	else:
		%LevelValue.text = "Lv. %d" % initial_state.level
		%GoldValue.text = "골드 %d" % initial_state.gold
		%StageValue.text = "%s  %s" % [initial_state.stage_id, initial_state.stage_name]
	%GrowthButton.pressed.connect(_show_menu.bind("growth", %GrowthButton))
	%EquipmentButton.pressed.connect(_show_menu.bind("equipment", %EquipmentButton))
	%DecorationButton.pressed.connect(_show_menu.bind("decoration", %DecorationButton))
	%CloseNotice.pressed.connect(_close_notice)


func _show_menu(menu: String, source: Button) -> void:
	_last_menu = source
	%MenuNoticeTitle.text = MENU_NOTICES[menu][0]
	%MenuNoticeBody.text = MENU_NOTICES[menu][1]
	%MenuNotice.show()
	for button in [%GrowthButton, %EquipmentButton, %DecorationButton]:
		button.disabled = true
	%CloseNotice.grab_focus()


func _close_notice() -> void:
	%MenuNotice.hide()
	for button in [%GrowthButton, %EquipmentButton, %DecorationButton]:
		button.disabled = false
	if is_instance_valid(_last_menu):
		_last_menu.grab_focus()


func _unhandled_key_input(event: InputEvent) -> void:
	if %MenuNotice.visible and event.is_action_pressed("ui_cancel"):
		_close_notice()
		get_viewport().set_input_as_handled()


func _update_layout() -> void:
	var landscape := size.x > size.y
	$Margin/Layout/Body.vertical = not landscape
	$Margin/Layout/Body/Sidebar.custom_minimum_size.x = 232.0 if landscape else 0.0
	%Menus.vertical = landscape
	for button in [%GrowthButton, %EquipmentButton, %DecorationButton]:
		button.add_theme_font_size_override("font_size", 16 if landscape else 12)
