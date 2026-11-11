# 인게임 UI·배경 리디자인

## 기준과 범위

- 기준: Godot 4.4.1, 프로젝트/공개 버전 0.3.0, `socra710`의 `c430185`.
- 복구 지점: `backup/ingame-ui-20261111-c430185`. 캐릭터 원본·PNG·동작 데이터는 수정하지 않는다.
- 사용자 시안은 정보 계층, 따뜻한 종이 풍경, 리본과 아이콘 메뉴의 참고 자료다. 원본 이미지를 게임 에셋으로 넣거나 시안의 캐릭터를 복제하지 않는다.
- 사용자의 마지막 순서 지침에 따라 이번 범위는 **1차 UI 레이아웃·배경**이다. 2차 전투·몬스터·공격/피격/사망은 별도 작업이다.
- 현재 실제 데이터는 `PrototypeState`의 level/gold/stage_id/stage_name뿐이다. 경험치·보석·처치 수·임무·보상·알림 데이터를 만들어 표시하지 않는다.

## 조사 결과와 선택

기존 화면은 헤더·레벨·골드·전투 영역·설명·목표·메뉴를 중첩 카드로 쌓아 풍경이 작다. 배경은 단일 SVG이며 세 메뉴만 있고 아이콘이 없다. 캐릭터는 보호된 96px PNG의 Idle/Walk를 사용하며 이동은 전투가 아닌 산책 연출이다.

선택 A는 독립된 HUD와 재사용 가능한 풍경 오브젝트/깊이 레이어다. 종이 그림자 방향과 낮은 원경 대비, 크고 선명한 근경으로 깊이를 만든다. B인 완성 화면 이미지 삽입은 편집·반응형·데이터 연결을 막으므로 사용하지 않는다. C인 전투 시스템까지 동시 구현은 원본 보호와 단계별 진행 원칙에 맞지 않아 제외한다.

상단은 원본 전사 프로필·레벨·골드·설정 안내로 압축하고 경험치는 수치 없이 준비 상태를 표시한다. 중앙 리본은 실제 스테이지를 표시한다. 이벤트/미션은 잠금 안내를 열고 가짜 알림을 만들지 않는다. 목표 패널의 진행선은 비활성 준비 상태이며 보상 숫자를 표시하지 않는다. 하단은 전투/성장/장비/꾸미기/상점이며 현재 화면만 활성 표시한다.

풍경은 BackgroundSky / BackgroundMountains / BackgroundForest / BackgroundStructures / BattleGround / ForegroundObjects로 나눈다. 산·성·풍차·강·다리·나무·꽃·바위를 별도 텍스처/노드로 배치한다. 방향별 위치를 계산하되 개별 오브젝트와 전사의 비율은 유지한다.

## Implementation Plan

**Goal:** 기존 시작 흐름과 실제 상태를 보존하면서 독립 HUD·종이 숲을 구성한다.

**Architecture:** MainGame은 상태 전달·안내 열기·반응형 조정을 담당한다. GameHUD는 상태 표시와 메뉴 신호, MainNavigation은 선택 상태와 아이콘 버튼, PaperBackground는 풍경만 담당한다. 게임 규칙이나 저장 포맷을 UI에 추가하지 않는다.

**Tech Stack:** Godot 4.4.1, GDScript, SVG 마스터/PNG, Galmuri/Pretendard, GdUnit4/Node, Chrome CDP.

### 1. 회귀 검사와 복구

- [ ] Git 상태 확인 후 위 복구 태그를 만든다.
- [ ] `tests/gui/GameScreenTest.gd`에서 긴 실제 재화 표시·누락 기능 비표시와 여섯 풍경 레이어/확장 메뉴 검사를 추가한다.
- [ ] 기존 화면에서 새 구조 검사가 실패하는 것을 확인한다.

### 2. UI 구성

- [ ] `scenes/ui/ingame_hud.tscn`, `scripts/ui/ingame_hud.gd`: `bind_state(state)`와 실제 Resource 변경 시 갱신. 긴 골드는 만/억 단위, 툴팁은 전체 숫자.
- [ ] `scenes/ui/main_navigation.tscn`, `scripts/ui/main_navigation.gd`: 다섯 아이콘 버튼, 선택/잠금 상태, `menu_requested(menu, source)` 신호.
- [ ] `assets/ui/ingame_icons.svg`, `assets/ui/stage_ribbon.svg`, `assets/fonts/theme_ingame.tres`: 재사용 아이콘·리본·종이 스타일.
- [ ] `scenes/main/game.tscn`, `scripts/main/game.gd`: 기존 메뉴/ESC/초기 상태/산책을 유지하고 새 HUD와 연결한다.
- [ ] 가로에서는 다섯 메뉴를 우측으로 재배치한다. 실제 모바일 CSS 크기에서도 터치 영역을 확인한다.

### 3. 독립 풍경

- [ ] `scenes/ui/paper_background.tscn`, `scripts/ui/paper_background.gd`: 여섯 레이어와 화면 비율별 오브젝트 배치.
- [ ] `assets/backgrounds/`의 별도 원본/런타임 에셋과 `scripts/art/`의 생성 도구를 추가한다. 기존 단일 SVG는 복구용으로 보존한다.
- [ ] 성·풍차·강·다리와 다양한 수목을 구성하되 플레이어가 걷는 공간은 비운다.

### 4. 연결·검증·보고

- [ ] 기존 테스트를 유지하면서 새 구조에 직접 의존하는 `tests/export/StartupLayoutCheck.gd`만 맞춘다.
- [ ] 창 모드 GdUnit, Node, Web Export/PCK 흐름 검사를 실행한다.
- [ ] Chrome 세로/가로/PC, 실제 클릭/ESC, 열린 메뉴 방향 왕복과 콘솔을 확인한다.
- [ ] 전체 화면, 전투 예정 영역, 장비 안내를 캡처한다. **실제 전투 화면은 미구현이므로 제출했다고 주장하지 않는다.**
- [ ] 이 문서에 파일·에셋·전후 사진·실제 결과·미검증 범위를 기록한다.

검증 명령:

```powershell
& '<Godot 4.4.1 콘솔 실행 파일>' --headless --editor --path . --import --quit
& '<Godot 4.4.1 콘솔 실행 파일>' --path . -s res://addons/gdUnit4/bin/GdUnitCmdTool.gd -a res://tests
node --test tests\web\*.test.mjs
node scripts\web\build.mjs '<Godot 4.4.1 콘솔 실행 파일>'
git -c core.whitespace=cr-at-eol diff --check
```

현재 버전은 바꾸지 않는다. 기존 PATCH 제안과 함께 배포할 경우 새 메뉴 진입점까지 포함하므로 최고 변경 유형인 **MINOR / 0.4.0 제안**으로 재평가하되 확정·배포는 사용자 승인 전이다. 저장 데이터 변경은 없다.
