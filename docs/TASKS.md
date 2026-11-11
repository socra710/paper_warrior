# 개발 단계

기준 문서: [게임 기획서](GAME_DESIGN.md), [기술 설계](TECHNICAL_DESIGN.md), [아트 가이드](ART_GUIDE.md)

| 단계 | 작업 | 완료 기준 | 상태 |
|---|---|---|---|
| 0. 기반 | Godot 프로젝트, Copilot 규칙, 씬/스크립트/데이터/에셋 구조, Web Export 설정, GdUnit4 GUI 테스트, 글꼴 | 웹 화면 흐름과 자동 테스트 확인 | 완료 |
| 0.1. 웹 프레젠테이션 | 별도 랜딩페이지, 중앙 세로형 웹 게임 프레임, 공용 키 아트와 시작 화면 디자인, 로고/파비콘 | 데스크톱/모바일 배치와 기존 빈 게임 흐름 확인 | 완료 |
| 0.2. 초기 배포 | 소스/배포 저장소 분리, GitHub Pages, Web/Windows ZIP 사전 릴리즈 | 공개 URL과 릴리즈 파일·원본 커밋 추적 확인 | 완료 |
| 0.3. 첫 장 미리보기 | 시작 화면 역할 분리, 실제 로딩, 전사 대기 연출, 초기 HUD와 메뉴 안내 | 패키지/웹에서 흐름과 준비 중 구분 확인 | 완료 |
| 0.4. 시작 안정화와 픽셀 연출 | 실패/재시도, 버전, 공통 부품 기반 PNG 전사, 맵 이동, 방향별 재배치 | 실제 오류 회귀/웹 재시도/방향 변경 상태 보존과 패키지 검증 | 완료 |
| 1. 캐릭터 | 기본 전사, 대기/공격/피격 애니메이션 | 캐릭터가 자연스럽게 반복 동작 | 대기 |
| 2. 전투 | 몬스터 1~3종, 자동 전투, HP/보상 | 전투가 자동 진행되고 결과 계산 | 대기 |
| 3. 성장 | 레벨, 골드, 능력치 강화 | 전투 보상으로 캐릭터 성장 | 대기 |
| 4. 장비 | 무기/방어구 획득·장착·강화 | 능력치와 외형 반영 | 대기 |
| 5. 종이 공작 | 접기/겹치기/문양 성장 | 세 갈래가 서로 다른 효과 제공 | 대기 |
| 6. 꾸미기 | 무료 꾸미기 파츠 일부 적용 | 장착/해제 및 외형 저장 | 대기 |
| 7. 저장 | 저장/불러오기, 오프라인 보상 | 재접속 후 진행 상태 복구 | 대기 |
| 8. 배포 | 웹 빌드 자동화, 모바일 브라우저 검증 | 공개 URL에서 플레이 가능 | 대기 |

## 현재 단계의 범위

현재는 기존 품질 복구에 이어 인게임 UI·배경 1차 개선 단계다. 공개 버전은 `0.3.0`이다. 기존 품질 수정만의 제안은 `0.3.1` PATCH였으나 신규 메뉴 진입점을 함께 포함하면 [버전 정책](VERSION_POLICY.md)에 따라 `0.4.0` MINOR를 **제안**한다. 승인·배포 전이며 위 단계 번호는 SemVer 번호가 아니다. 게임 시스템은 준비 중 안내이고 전투·성장·보상·저장은 포함하지 않는다. [캐릭터 제작 지침](CHARACTER_SPRITE_STANDARD.md)의 미래 애니메이션 목록도 구현 완료 목록이 아니다.

0.1단계는 기반 화면의 표현 개선이다. 랜딩페이지에 소개하는 성장·방치·꾸미기는 기획 중인 방향이며 현재 플레이 가능한 기능으로 표시하지 않는다. 종이전사 고유의 크림·민트·하늘색·노랑 팔레트, 종이 메모와 접힘 디자인, 생성한 얼굴 심볼/파비콘을 사용한다.

원본은 `socra710/paper_warrior`, 랜딩/Web 빌드와 다운로드 릴리즈는 `socra710/paper_warrior_releases`에서 분리 관리한다. Windows 초기 배포는 휴대용 ZIP이며 설치 마법사·서명·자동 업데이트는 포함하지 않는다.

### 공개 프로토타입 v0.1.0

- 랜딩페이지: <https://socra710.github.io/paper_warrior_releases/>
- 웹 게임: <https://socra710.github.io/paper_warrior_releases/play.html>
- Web/Windows 다운로드: <https://github.com/socra710/paper_warrior_releases/releases/tag/v0.1.0>
- 소스 저장소의 GdUnit/웹 로더 CI와 배포 저장소의 Pages workflow 성공을 확인했다.
- 공개 사이트의 데스크톱 랜딩과 모바일 폭 게임 화면, 시작 버튼 이후 빈 Main Game 전환을 브라우저에서 확인했다.

이는 기반 프레젠테이션의 첫 사전 릴리즈이며, 아래 8단계의 실제 게임 MVP 배포 완료를 뜻하지 않는다.

### 첫 장 미리보기 v0.2.0

- 소스 작업은 요청한 `socra710` 브랜치에서 진행했다. 배포 원본은 `2753978`이며 소스 `main`은 변경하지 않았다.
- [v0.2.0 Web/Windows 다운로드](https://github.com/socra710/paper_warrior_releases/releases/tag/v0.2.0)를 별도 배포 저장소에 게시했다.
- GdUnit GUI 9개·웹 로더 4개 테스트와 소스 브랜치 CI, Pages workflow가 통과했다.
- 실제 Web/Windows 패키지에서 Splash → Loading → Title → Game 콜드 시작과 HUD/리소스/화면 경계를 확인했다.
- 공개 게임의 Chrome 데스크톱 및 390px 모바일 폭에서 시작, 초기 HUD와 세 메뉴 안내/ESC 닫기를 확인했다. 모바일 폭에서 가로 넘침은 없다.
- Windows는 계속 휴대용·미서명 ZIP이며 전투·성장·보상·저장은 구현하지 않았다.

### 기반 단계 완료 기록 (v0.1.0)

- [x] Godot 4 프로젝트가 headless 에디터 검사에서 오류 없이 로드된다.
- [x] Web Export preset으로 `build/web/index.html`을 생성할 수 있다.
- [x] 브라우저에서 Splash → Loading → Title이 표시된다.
- [x] Title의 시작 버튼을 누르면 비어 있는 Main Game 화면이 열린다.
- [x] 게임 기획서와 아트 가이드, 기술 문서 및 Copilot 규칙이 준비된다.
- [x] GdUnit4 SceneRunner가 GUI 클릭으로 Title에서 빈 Main Game까지 확인한다.
- [x] Galmuri는 제목, Pretendard는 일반 UI에 적용하고 글꼴 라이선스를 보존한다.

### 첫 장 미리보기 점검

- [x] Loading을 캐릭터 인트로와 다른 화면으로 분리하고 실제 준비율을 표시한다.
- [x] 게임 씬 준비가 끝난 뒤 Title로 이동하고 시작 버튼에서 준비한 씬을 사용한다.
- [x] 초기 레벨 1·골드 0·스테이지 1-1과 전사 대기 연출을 표시한다.
- [x] 세 메뉴를 준비 중으로 표시하고 안내창 열기·닫기를 구현한다.
- [x] Web/Windows 패키지에서 실제 시작 흐름, 리소스와 480×640 화면 경계를 검증한다.
- [x] 공개 웹에서 데스크톱/모바일 폭 흐름을 확인하고 별도 배포 저장소에 새 버전을 게시한다.

### 시작 안정화와 픽셀 연출 v0.3.0

발견한 문제는 중복 웹 엔진 생성, 무응답 부팅의 무한 대기, Title 연속 입력 후 제거된 씬 접근, 제거된 Splash의 타이머, 로딩 시간 초과 뒤 같은 요청의 타이머만 재설정하는 동작이었다. 웹은 엔진 스크립트 다운로드도 제한 시간 안에 포함하고, 게임의 일반 실패 재요청과 시간 초과 후 앱 재시작을 구분했다.

| 변경 영역 | 주요 파일 |
|---|---|
| 시작/복구/버전 | `scripts/main/*.gd`, `scripts/ui/responsive_screen.gd`, `start_screen.gd`, `version_label.gd`, `project.godot` |
| 화면/작은 맵 전사 | `scenes/main/game.tscn`, `loading.tscn`, `scenes/ui/start_screen.tscn`, `warrior_idle.tscn`, `map_walker.tscn`, `scripts/ui/map_walker.gd`, `warrior_preview.gd` |
| 공유 부품 제작 | `warrior_parts.svg`, `data/presentation/warrior_animation.json`, `scripts/art/build_warrior_sprites.gd`, 생성 SVG/PNG와 `scenes/characters/warrior_sprite.tscn` |
| 로딩 UI 에셋 | `assets/ui/paper_fold.svg`, `scenes/ui/paper_fold_sprite.tscn` |
| 웹/패키징 | `web/play.html`, `game-loader.mjs`, `game-viewport.mjs`, CSS, `scripts/web/build.mjs`, `export_presets.cfg` |
| 회귀 검사 | `tests/gui/{GameScreen,LoadingScreen,SpriteAsset,TitleScreen}Test.gd`, `tests/web/{loader,viewport}.test.mjs`, `tests/export/StartupLayoutCheck.gd`, CI |
| 지침/배포 안내 | `CHARACTER_SPRITE_STANDARD.md`, 아트/기술/작업 문서, README, Copilot 규칙, 배포 README/릴리즈 노트 |

- [x] 공통 SVG 부품 + JSON 동작에서 48×48 PNG 10프레임과 SpriteFrames를 생성한다. Idle 4 / Walk 6만 구현한다.
- [x] 창 모드 GdUnit 16개와 Node 9개 통과. 주입한 로딩 실패/시간 초과의 예상 오류 로그를 실제 런타임 오류와 구분했다.
- [x] 실제 Native 콜드 시작과 네 화면의 양방향 렌더링, PNG/SVG 4배 비교와 10프레임 확대 품질을 확인했다.
- [x] 실제 Native 시간 초과 재시작이 새 게임 프로세스를 실행하는 것을 확인하고 생성한 프로세스만 닫았다.
- [x] Chrome에서 PCK/엔진 JS 다운로드를 각각 차단해 오류 → 실제 새로고침 재시도를 확인했다.
- [x] Chrome 390×844 ↔ 844×390에서 같은 문서/Engine 1개와 열린 장비 안내를 유지하고 가로 넘침 없이 맵 이동을 확인했다.
- [x] Chrome 1440×1000에서 중앙의 작은 세로 프레임, 시작과 세 메뉴/ESC를 확인했다.
- [x] 최종 Web/Windows 릴리즈 패키지, 원본 커밋/체크섬, CI/Pages와 공개 배포를 확인한다.

배포 원본은 `socra710` 브랜치의 `319f0d0`, 배포 저장소 커밋은 `4d404bc`다. 소스 main은 변경하지 않았다. [v0.3.0 Web/Windows ZIP](https://github.com/socra710/paper_warrior_releases/releases/tag/v0.3.0)을 새 사전 릴리즈로 게시했다. 소스 CI `42996989156`과 Pages `42997283064` 성공, 공개 `version.json`의 버전/원본 커밋 및 두 ZIP의 GitHub SHA-256을 로컬 manifest와 대조했다.

실제 Windows EXE에서도 콜드 시작 → Title → Game, PNG 리소스, 가로/세로와 열린 메뉴 유지, 오류 없는 정상 종료를 확인했다. 공개 [웹 게임](https://socra710.github.io/paper_warrior_releases/play.html)은 데스크톱/모바일 폭과 방향 왕복, 세 메뉴/ESC를 확인했고 예상하지 않은 브라우저 런타임 오류는 없었다. 공개 랜딩페이지도 390px/1440px 폭에서 이미지와 글꼴 및 가로 넘침을 확인했다.

실제 휴대전화, iOS/Safari는 아직 검증하지 않았다. 전투·성장·보상·저장 및 Attack/Hit/Death/Victory 에셋은 미구현이다. UI까지 멈춘 엔진이나 OS 재실행 차단은 수동 재실행이 필요할 수 있다. Windows 배포는 계속 미서명 휴대용 ZIP이며 설치 프로그램이 아니다.

### 시작 화면·캐릭터 품질 복구 (미배포)

조사·원인·선택한 대안·변경 파일·동일 조건 전후 이미지·실제 결과는 [품질 복구 기록](VISUAL_QUALITY_RECOVERY.md)에서 관리한다.

- [x] 실제 시작 씬/상속/리소스 준비/웹 다운로드 화면과 Git 외형 변경 원인 조사, 정상 참조·작업 전 복구 태그 보존.
- [x] 원본 도형·색을 공통 부품으로 복원하고 96px 예외로 PNG 생성. 실제 표시 크기 유지와 얼굴/발 기준선/전체 프레임 검증.
- [x] 로고 Splash, 파일 준비 웹 패널, 하늘색 작업대 Loading, 기준 전사/버튼 Title 구분. 미완료 100% 방지.
- [x] GdUnit 22개 / Node 12개, 실제 Web PCK/Windows EXE 콜드 흐름과 레이아웃, Chrome 실패/실제 재시도/반복/양방향/이전 캐시 검증.
- [x] Linux CI의 27픽셀 RGB 1LSB 반올림 차이를 실측하고 원본 경로/알파/얼굴 검사 유지. 코드 `868efc1`의 CI `43011418246`에서 GdUnit 22개·Node 12개 통과.
- [x] SemVer 정책을 에이전트 규칙·README와 연결하고 CHANGELOG Unreleased 도입. 공개·프로젝트 v0.3.0 유지.
- [ ] 사용자에게 PATCH 제안 승인받기, 승인 버전으로 최종 빌드·별도 배포 후 공개 버전/캐시/Pages 확인. 승인 전 배포하지 않음.

### 중앙 종이접기·가독성 후속 개선 (미배포)

- [x] 실제 클릭 외곽선, 정적 웹 접기, 작은 버퍼·낮은 대비 원인을 재현하고 기존 품질 복구 문서에 설계 기록.
- [x] 공통 48px/8프레임 PNG 접기와 카드 없는 중앙 구성, 실제 진행률·실패·재시도 유지.
- [x] 표시 크기×DPR 버퍼, 캔버스 전체 pixelated 제거, 캐릭터 Nearest·기존 외형 보존.
- [x] 과한 폰트 확대를 되돌려 역할별 크기를 절제하고 정상 로딩 문구를 종이전사 표현으로 수정.
- [x] 최신 창 모드 GdUnit 23개·Node 13개, Web PCK 흐름·경계, Chrome DPR 1/2·양방향·포커스·실제 다운로드 대기·실패/재시도 확인.
- [ ] 승인 버전 확정 및 별도 배포 저장소 공개 검증. 현재 프로젝트·공개 버전은 0.3.0 유지.

### 인게임 UI·배경 리디자인 1차 (미배포)

- [x] 기존 씬/실제 데이터/보호된 전사 조사와 Git 복구 지점, 단계별 계획 기록.
- [x] 독립 HUD·프로필·리본·임무 준비 패널·다섯 탭, 잠금 안내와 실제 데이터 표시.
- [x] 독립 환경 PNG 13종, 원본 보존과 재생성 도구, 여섯 깊이 레이어.
- [x] GdUnit 25개·Node 13개, 실제 Web PCK 흐름과 리소스, Chrome 세로/가로/PC와 일곱 준비 메뉴 검증.
- [x] 원본 캐릭터 무변경 확인, 동일 크기 전후 및 현재 전투 예정 영역/장비 안내 스크린샷.
- [ ] 2차 전투·몬스터·HP·공격/피격/사망과 실제 목표·보상 데이터 연결. 이번 UI 작업에 임의 게임 규칙을 넣지 않음.
- [ ] 승인 버전 확정 후 별도 배포 저장소 게시와 실제 공개 브라우저 검증.

파일·이미지·실행 결과와 한계는 [리디자인 보고서](INGAME_REDESIGN.md)에 기록한다.

## 명시적 MVP 제외 항목

실시간/비동기 PvP, 로그인·계정·서버 동기화, 유료 BM·결제, 재접기·환생, 자유 그림 그리기, 다수 캐릭터 수집·파티, 복잡한 제작·거래·길드 시스템.
