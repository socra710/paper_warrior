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

- [x] Git 상태 확인 후 위 복구 태그를 만든다.
- [x] `tests/gui/GameScreenTest.gd`에서 긴 실제 재화 표시·누락 기능 비표시와 여섯 풍경 레이어/확장 메뉴 검사를 추가한다.
- [x] 기존 화면에서 새 구조 검사가 실패하는 것을 확인한다.

### 2. UI 구성

- [x] `scenes/ui/ingame_hud.tscn`, `scripts/ui/ingame_hud.gd`: `bind_state(state)`와 실제 Resource 변경 시 갱신. 긴 골드는 만/억 단위, 툴팁은 전체 숫자.
- [x] `scenes/ui/main_navigation.tscn`, `scripts/ui/main_navigation.gd`: 다섯 아이콘 버튼, 선택/잠금 상태, `menu_requested(menu, source)` 신호.
- [x] `assets/ui/ingame_icons.svg`, `assets/ui/stage_ribbon.svg`, `assets/fonts/theme_ingame.tres`: 재사용 아이콘·리본·종이 스타일.
- [x] `scenes/main/game.tscn`, `scripts/main/game.gd`: 기존 메뉴/ESC/초기 상태/산책을 유지하고 새 HUD와 연결한다.
- [x] 가로에서는 다섯 메뉴를 우측으로 재배치한다. 실제 모바일 CSS 크기에서도 터치 영역을 확인한다.

### 3. 독립 풍경

- [x] `scenes/ui/paper_background.tscn`, `scripts/ui/paper_background.gd`: 여섯 레이어와 화면 비율별 오브젝트 배치.
- [x] `assets/backgrounds/`의 별도 원본/런타임 에셋과 `scripts/art/`의 생성 도구를 추가한다. 기존 단일 SVG는 복구용으로 보존한다.
- [x] 성·풍차·강·다리와 다양한 수목을 구성하되 플레이어가 걷는 공간은 비운다.

### 4. 연결·검증·보고

- [x] 기존 테스트를 유지하면서 새 구조에 직접 의존하는 `tests/export/StartupLayoutCheck.gd`만 맞춘다.
- [x] 창 모드 GdUnit, Node, Web Export/PCK 흐름 검사를 실행한다.
- [x] Chrome 세로/가로/PC, 실제 클릭/ESC, 열린 메뉴 방향 왕복과 콘솔을 확인한다.
- [x] 전체 화면, 전투 예정 영역, 장비 안내를 캡처한다. **실제 전투 화면은 미구현이므로 제출했다고 주장하지 않는다.**
- [x] 이 문서에 파일·에셋·전후 사진·실제 결과·미검증 범위를 기록한다.

검증 명령:

```powershell
& '<Godot 4.4.1 콘솔 실행 파일>' --headless --editor --path . --import --quit
& '<Godot 4.4.1 콘솔 실행 파일>' --path . -s res://addons/gdUnit4/bin/GdUnitCmdTool.gd -a res://tests
node --test tests\web\*.test.mjs
node scripts\web\build.mjs '<Godot 4.4.1 콘솔 실행 파일>'
git -c core.whitespace=cr-at-eol diff --check
```

현재 버전은 바꾸지 않는다. 기존 PATCH 제안과 함께 배포할 경우 새 메뉴 진입점까지 포함하므로 최고 변경 유형인 **MINOR / 0.4.0 제안**으로 재평가하되 확정·배포는 사용자 승인 전이다. 저장 데이터 변경은 없다.

## 구현 결과

### 문제와 원인

1. 기존 중첩 카드·긴 설명·텍스트 메뉴가 공간을 차지해 세계와 전사가 작게 보였다. HUD를 압축하고 배경을 화면 전체에 배치했다.
2. 한 장의 평면 풍경에는 원경/중경/근경의 독립 제어와 소재 디테일이 부족했다. 첫 기하학 SVG 시제품도 시안보다 평면적이어서 종이 질감이 있는 독립 소재로 교체했다.
3. 새 배경 통합 중 원본 PNG를 `Image.load`로 읽는 코드에서 Export 경고를 재현했다. import된 `Texture2D`를 ResourceLoader로 읽도록 수정하고 실제 PCK에서 확인했다.
4. `TextureRect`의 기본 최소 크기가 계산한 축소 크기를 덮어쓰는 문제를 발견해 `EXPAND_IGNORE_SIZE`로 수정했다.
5. 가로 모바일에서 64 논리 픽셀 버튼은 약 42 CSS px였다. 최소 68로 보정해 검증 프레임에서는 약 44 CSS px 이상을 확보했다.

### 수정·추가 파일

| 파일 | 내용 |
|---|---|
| `scenes/main/game.tscn`, `scripts/main/game.gd` | 기존 상태·산책·안내 유지, HUD/풍경 연결과 방향별 배치 |
| `scenes/ui/ingame_hud.tscn`, `scripts/ui/ingame_hud.gd` | 실제 상태 바인딩·변경 구독·재화 축약·보조 메뉴 |
| `scenes/ui/player_profile.tscn`, `stage_banner.tscn`, `mission_progress_panel.tscn` | 편집/재사용 가능한 독립 프로필·리본·목표 준비 패널 |
| `scenes/ui/main_navigation.tscn`, `scripts/ui/main_navigation.gd` | 다섯 탭·잠금·선택 상태 |
| `assets/fonts/theme_ingame.tres`, `assets/ui/ingame_icons.svg`, `stage_ribbon.svg` | 공통 테마·아이콘 12칸·종이 리본 |
| `scenes/ui/paper_background.tscn`, `scripts/ui/paper_background.gd` | 여섯 깊이 레이어와 비율 유지 배치 |
| `scripts/art/build_paper_background.gd`, `assets/backgrounds/paper_forest_diorama/` | 원본 소재와 재현 가능한 개별 PNG 생성 |
| `tests/gui/GameScreenTest.gd`, `tests/export/StartupLayoutCheck.gd` | 실제 값·일곱 안내·터치 영역·회전·패키지 텍스처 회귀 검사 |
| `README.md`, `CHANGELOG.md`, `.github/copilot-instructions.md`, 아트/기술/캐릭터 규격/작업 문서 | 구조·범위·버전 제안·검증 연결 |
| `docs/images/ingame-redesign/` | 최종 Native 및 실제 Chrome 스크린샷 |

기존 캐릭터 SVG·공통 부품·PNG·동작 JSON·SpriteFrames와 초기 상태 Resource는 변경하지 않았다. 맵 인스턴스 표시 영역만 72→96px로 조정했고 Title은 그대로다. 전사는 기존 Idle/Walk를 재생하며 전투 동작으로 보고하지 않는다.

### 새 환경 에셋

원본은 `source/cutouts_master.png`(새로 생성한 4×3 투명 환경 소재 시트)와 `source/paper_forest_parts.svg`다. 사용자 시안의 캐릭터나 UI를 추출하지 않았으며 완성 화면을 게임 배경에 삽입하지 않았다. 원본 폴더의 `.gdignore`로 제작용 마스터를 런타임에서 제외한다.

| PNG | 크기 | PNG | 크기 |
|---|---|---|---|
| sky | 480×640 | cloud | 168×78 |
| mountain | 240×176 | pine | 100×146 |
| round_tree | 112×126 | castle | 184×218 |
| windmill | 150×196 | bush | 116×72 |
| flower | 54×62 | rock | 92×54 |
| fence | 164×82 | river | 220×92 |
| bridge | 184×92 | | |

생성기는 시트 행 경계의 나무 밑동·깃발·계단 잘림을 보정하고 연결된 실루엣/가장자리를 보존한다. 분리된 저알파 잡티 제거와 premultiplied-alpha 축소 후 비율을 유지해 각각의 캔버스에 배치한다. 13 PNG 합계는 338,095 bytes다. 하늘/풍경은 Linear, 전사는 Nearest이며 캐릭터를 새로 그리지 않았다.

## 실제 실행·검증 결과

| 실행 | 결과 |
|---|---|
| Godot 4.4.1 headless editor import | 종료 코드 0, 경고/오류 없음 |
| 창 모드 GdUnit 전체 | **25/25**, errors/failures/flaky/skipped/orphans 0 |
| Node 웹 회귀 검사 | **13/13**, 실패 0 |
| Web Export와 실제 PCK 시작 흐름/레이아웃 | Splash→Loading→Title→Game, 여섯 레이어/리소스 기반 텍스처 정상. 이전 raw-image 경고 없음 |
| Native 480×640 / 960×540 | 전체 화면·장비 안내·현재 산책 영역 캡처, 주요 UI 겹침/잘림 없음 |
| Chrome 모바일 에뮬레이션 390×844, DPR 2 | 실제 시작과 일곱 준비 메뉴/ESC, 세로 화면 정상. CSS 356×474.656 / 버퍼 712×949 |
| Chrome 844×390 및 세로 왕복 | 같은 문서/Engine 1개·열린 장비 안내 유지. CSS 520.656×292.859 / 버퍼 1041×586, 가로 넘침 없음 |
| Chrome PC 1440×1000, DPR 1 | 중앙 세로 프레임과 실제 시작·일곱 안내/ESC 확인 |
| Chrome 로그/포커스 | 예상 밖 런타임 오류 없음. canvas focus 유지, outline none, image-rendering auto |

새 HUD가 없는 상태에서 구조 검사가 실패하는 것을 먼저 확인했다. 이어 리소스 경로/68px 회귀 검사가 실패하는 것을 확인한 뒤 수정했다. 최종 GdUnit은 원본 보호와 기존 시작·오류·재시도·시간 초과 검사를 포함한다. 이전 작업의 브라우저 다운로드 실패·재시도 결과는 [품질 복구 기록](VISUAL_QUALITY_RECOVERY.md)에 있으며 이번 UI 작업에서 그 웹 실패 매트릭스를 다시 실행했다고 주장하지 않는다.

## 변경 전후 스크린샷

동일 Native 창 크기 비교이며 현재 사진은 전사를 동일 Idle 프레임에 고정해 아트 원형을 확인했다.

| 화면 | 변경 전 | 변경 후 |
|---|---|---|
| 세로 480×640 | [기존 화면](images/quality-v040/folding-game-portrait.png) | [전체 인게임](images/ingame-redesign/full-portrait.png) |
| 가로 960×540 | [기존 화면](images/quality-v040/folding-game-landscape.png) | [전체 인게임](images/ingame-redesign/full-landscape.png) |
| 장비 안내 | 기존 안내 동작 유지 | [세로](images/ingame-redesign/equipment-portrait.png) / [가로](images/ingame-redesign/equipment-landscape.png) |
| 현재 전투 예정 영역 | 실제 전투 미구현 | [산책 미리보기](images/ingame-redesign/battle-area-preview.png) |
| 실제 Web | | [모바일](images/ingame-redesign/web-mobile.png) / [가로](images/ingame-redesign/web-landscape.png) / [PC](images/ingame-redesign/web-desktop.png) |

요청한 전체 인게임·성장/장비 사진은 제공한다. **캐릭터와 몬스터가 전투하는 사진은 실제 시스템이 없어 제공할 수 없다.** 산책 영역 사진은 전투를 구현했다는 증거가 아니며 몬스터/HP/데미지·보상을 합성하지 않았다.

## 남은 범위와 배포 판단

- 2차: 전투 규칙/데이터를 별도로 정한 뒤 원본 전사 Attack/Hit/Death, 몬스터와 HP/이펙트·실제 임무/보상을 연결한다. 기존 로직·저장을 임의로 바꾸지 않는 원칙 때문에 이번 단계에 가짜 전투를 넣지 않았다.
- 실제 휴대전화, iOS/Safari와 새 Windows 배포 패키지는 이번 변경에서 검증하지 않았다.
- 웹 산출물은 로컬 <http://localhost:8000/play.html>에서 확인했다. 공개 배포 저장소·Pages·공개 버전은 변경하지 않았다. 승인된 버전으로 다시 빌드한 뒤 게시하고 `version.json`·화면 버전·캐시·콘솔을 실제 공개 페이지에서 확인해야 한다.

| 버전 보고 | 판단 |
|---|---|
| 현재 버전 | 0.3.0 |
| 제안 버전 / 유형 | 0.4.0 / MINOR, 미확정 |
| 사유 | 기존 품질 수정에 신규 메뉴 안내 진입점이 함께 포함됨 |
| 신규 게임 기능 | 없음. 실제 전투·장비·상점·설정 시스템은 미구현 |
| 수정 / 영향 | 인게임 표시·풍경·메뉴 배치, 시작 흐름과 기존 산책/안내 유지 |
| 저장 데이터 호환성 | 변경 없음, 저장 기능 자체 미구현 |
| 배포 가능 여부 | 로컬 Web 검증 완료, 정식 배포는 버전 승인 및 공개 검증 전 |
