extends "res://scripts/ui/responsive_screen.gd"

const MENU_NOTICES := {
	"growth": ["성장 · 준비 중", "접기와 겹치기로 성장하는 기능을 준비해요.\n지금은 레벨과 골드가 변하지 않아요."],
	"equipment": ["장비 · 준비 중", "무기와 방패를 장착하는 기능을 준비해요.\n현재 검과 방패는 대기 연출용이에요."],
	"decoration": ["꾸미기 · 준비 중", "색과 문양, 작은 장식을 더할 예정이에요.\n지금은 전사 모습을 변경할 수 없어요."],
	"shop": ["상점 · 준비 중", "작은 종이 상점을 준비하고 있어요.\n구매·결제와 프리미엄 재화는 아직 없어요."],
	"event": ["이벤트 · 준비 중", "종이 숲의 특별한 소식을 준비하고 있어요.\n현재 진행 중인 이벤트나 받을 보상은 없어요."],
	"mission": ["미션 · 준비 중", "첫 임무를 정성껏 접고 있어요.\n처치 목표·진행도·보상은 전투 구현 후 연결해요."],
	"settings": ["설정 · 준비 중", "소리와 플레이 설정을 준비하고 있어요.\n현재는 화면 방향에 맞춰 자동으로 배치해요."],
}

@export var initial_state: PrototypeState
var _last_menu: Button
@onready var _hud: Control = $GameHUD


func _ready() -> void:
	super._ready()
	if initial_state == null:
		push_error("게임 화면의 초기 상태 Resource가 없습니다.")
	_hud.call("bind_state", initial_state)
	_hud.connect("menu_requested", _show_menu)
	%CloseNotice.pressed.connect(_close_notice)


func _show_menu(menu: String, source: Button) -> void:
	_last_menu = source
	if menu == "battle":
		_close_notice()
		return
	%MenuNoticeTitle.text = MENU_NOTICES[menu][0]
	%MenuNoticeBody.text = MENU_NOTICES[menu][1]
	%MenuNotice.show()
	_hud.call("set_menu_open", menu, true)
	%CloseNotice.grab_focus()


func _close_notice() -> void:
	%MenuNotice.hide()
	_hud.call("set_menu_open", "battle", false)
	if is_instance_valid(_last_menu):
		_last_menu.grab_focus()


func _unhandled_key_input(event: InputEvent) -> void:
	if %MenuNotice.visible and event.is_action_pressed("ui_cancel"):
		_close_notice()
		get_viewport().set_input_as_handled()


func _update_layout() -> void:
	var landscape := size.x > size.y
	$BattleArea.position = Vector2(120, 215) if landscape else Vector2(84, 304)
	$BattleArea.size = Vector2(size.x - 360, 128) if landscape else Vector2(size.x - 168, 184)
	($BattleArea/MapWalker/WarriorSprite as AnimatedSprite2D).scale = Vector2.ONE
