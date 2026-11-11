# 기술 설계

## 초기 범위

Godot 4와 GDScript를 사용하며 브라우저 우선으로 검증한다. 현재 프로토타입은 네 화면의 역할 분리, 실제 씬/리소스 준비, 픽셀 캐릭터 대기/맵 이동 연출과 초기 게임 HUD를 제공한다. 이동은 맵을 둘러보는 연출이며 전투·성장·보상·저장·오프라인 보상·Android Export는 포함하지 않는다.

## 시작 화면 흐름

```text
project.godot
  └── scenes/main/splash.tscn
        └── 1.2초 후 scenes/main/loading.tscn
              └── Title/Game 리소스 준비 완료 후 scenes/main/title.tscn
                    └── 시작 버튼 → scenes/main/game.tscn
```

| 씬 | 책임 | 스크립트 |
|---|---|---|
| `scenes/main/splash.tscn` | 독립된 로고·종이 배경의 짧은 인트로, 전환 실패 안내 | `scripts/main/splash.gd` |
| `scenes/main/loading.tscn` | 독립된 종이 공방 화면, 실제 준비율/오류 표시 | `scripts/main/loading.gd` |
| `scenes/main/title.tscn` | 로고·기준 캐릭터 대기·시작 버튼 표시 | `scripts/main/title.gd` |
| `scenes/main/game.tscn` | 초기 레벨·골드·스테이지, 대기 전사와 준비 중인 메뉴 | `scripts/main/game.gd` |

Splash의 1.2초는 인트로 표시 시간이며 씬 소유의 processing으로 관리해 화면 제거 후 타이머가 전환을 실행하지 않는다. 요청/실행 가드로 지연 전환이 중복 실행되지 않으며 실패 시 로고·오류를 유지한다. Loading은 `ResourceLoader.load_threaded_request`로 Title/Game PackedScene을 요청하고 `load_threaded_get_status`의 실제 준비율 평균을 표시한다. 알 수 없는 값은 불확정 상태이며 진행 중인 값은 최대 99%다. 두 요청이 모두 완료돼야 100%로 표시하고 Title을 가져와 `change_scene_to_packed`로 이동한다. 완료 후 0.15초 페이드아웃 외에 가짜 진행 타이머는 없다.

Loading 상태는 준비/전환/실패로 구분한다. 실패 또는 20초 응답 시간 초과 시 자동 진행을 멈추고 진단 메시지를 표시한다. 일반 실패의 재시도는 실패한 요청을 회수해 실제 요청을 다시 수행하고 다른 진행 중 요청은 유지한다. 시간 초과는 취소 불가능한 엔진 요청의 타이머만 초기화하지 않는다. **처음부터 다시 시작**으로 웹은 페이지를 새로고침하고 데스크톱은 새 앱 인스턴스를 실행한 후 기존 앱을 종료한다. 재실행이 차단되면 수동 재실행 안내를 표시한다. 중복 클릭은 잠근다. 테스트는 호환 로더와 재실행 콜백으로 실패/대기/재시작을 분리 검증한다.

Splash는 독립 씬이며 `scenes/ui/start_screen.tscn`은 Title 전용 레이아웃이다. 화면 전체 구도를 공유하지 않고 Pretendard/공통 버튼 테마를 재사용한다. Loading은 하늘색 전체 배경, 카드 없는 중앙 종이접기와 실제 진행 바를 사용한다. 웹 부팅과 Godot은 같은 48px/8프레임 PNG를 사용하며, Godot은 SpriteFrames/8fps/Nearest, 웹은 steps(8)/1초로 재생한다. 실패하면 접기를 멈추고 재시도하면 재생한다. 종이 애니메이션은 진행률을 만들어내거나 최소 대기 시간을 추가하지 않는다. Game의 완료된 요청은 Title 시작 버튼에서 `load_threaded_get`으로 가져올 때까지 ResourceLoader가 유지한다. 시작하지 않고 Title을 닫으면 완료 요청을 회수해 리소스를 해제한다. Title을 단독 실행한 경우에만 일반 `load`를 사용한다. 시작 버튼은 첫 입력에서 즉시 잠그고 전환을 지연 호출하며 실패 시 안내와 함께 다시 활성화한다.

웹 캔버스 버퍼는 `game-viewport.mjs`가 실제 CSS 크기×DPR로 계산한다. ResizeObserver와 창 resize/방향 변경은 같은 캔버스·엔진만 갱신하며 동일 크기에는 버퍼를 다시 초기화하지 않는다. 캔버스 전체에 pixelated를 적용하지 않고 개별 픽셀 스프라이트의 Nearest를 유지한다. 캔버스 외곽 클릭 포커스 선만 제거하며 키보드 입력과 Godot 버튼 포커스는 유지한다.

## 첫 게임 화면

`PrototypeState`와 `data/growth/initial_preview.tres`는 초기 레벨 1, 골드 0, 스테이지 1-1 / 종이 숲의 입구를 제공한다. Game 씬의 exported Resource로 연결되어 씬과 함께 준비·패키징되며 런타임에서 변경하지 않는다. 저장 데이터나 실제 보상 시스템은 아니다.

`scenes/characters/warrior_sprite.tscn`은 원본 보존 예외인 96×96 PNG 프레임을 Nearest로 표시하는 AnimatedSprite2D다. Idle 4프레임과 Walk 6프레임을 독립 관리한다. 맵 배율 0.75/Title 배율 1.5로 실제 표시 영역은 기존 72px/144px다. `scenes/ui/warrior_idle.tscn`은 Title 대기 미리보기이고 `scenes/ui/map_walker.tscn`은 작은 전사를 정규화된 네 지점 사이로 이동시킨다. 맵 크기가 바뀌면 상대 위치를 유지하며 경계 안으로 제한한다. 전투/스테이지 진행은 준비 중으로 표시한다.

성장·장비·꾸미기는 각각 준비 중인 기능을 설명하는 안내창만 연다. 안내창 표시 중 배경 메뉴는 비활성화하고 닫기/ESC로 원래 버튼에 포커스를 복원한다. 강화·구매·장착·색상 변경이나 가짜 수치 증가는 없다.

## 버전과 화면 방향

버전은 `project.godot`의 `application/config/version`을 단일 기준으로 사용한다. 모든 Godot 화면과 웹 플레이 셸에 표시하고 웹 빌드 시 같은 값으로 치환한다. 공개 배포의 `version.json`은 릴리즈 태그와 실제 원본 커밋을 별도로 추적한다.

[버전 정책](VERSION_POLICY.md)에 따라 이번 품질 복구는 PATCH `0.3.1` 제안이다. 사용자 승인 전 프로젝트·공개 버전 `0.3.0`은 바꾸지 않고 신규 배포를 하지 않는다. 미배포 변경은 CHANGELOG의 Unreleased와 [품질 복구 기록](VISUAL_QUALITY_RECOVERY.md)에서 관리한다.

`responsive_screen.gd`는 세로 480×640, 가로 800×450의 논리 해상도를 선택한다. 시작 화면은 전사/버튼 배치를 재정렬하고 Game은 맵/사이드 메뉴로 재배치한다. 현재 씬을 재생성하지 않으므로 열린 메뉴와 초기 상태, 이동 경로가 유지된다.

웹은 기본 중앙 세로 프레임을 유지하고 짧은 가로 화면에서만 16:9를 사용한다. `game-viewport.mjs`는 같은 캔버스의 내부 크기를 480×640 ↔ 960×540으로 바꾸고 resize를 알린다. Engine을 다시 생성하거나 페이지를 새로고침하지 않는다. 화면 방향 변경과 오류 후 명시적 재시도에 의한 새로고침은 서로 다른 동작이다.

## 웹사이트

- `web/index.html`: 별도 설치가 필요 없는 정적 랜딩페이지. 소개, 기획 중인 특징, 현재 프로토타입 범위를 표시한다.
- `web/play.html`: Godot 커스텀 HTML 셸. 제목 → 작은 중앙 게임 프레임 → 조작/프로토타입 안내 순서다.
- `web/site.css`, `web/game-loader.css`: 공용 사이트 스타일과 플레이 프레임/부팅 화면 스타일.
- `web/game-loader.mjs`: 엔진 JavaScript 다운로드부터 실제 게임 시작까지 공유하는 90초 제한, 실제 다운로드 진행률과 실패 처리. 엔진 스크립트는 재시도 핸들러 설치 후 비동기로 요청한다. 같은 캔버스의 중복 부팅을 막고 실패 뒤 늦은 다운로드/진행 콜백을 무시한다. 재시도는 페이지 새로고침으로 부분 초기화 상태를 제거한다.
- `web/game-viewport.mjs`: 페이지/엔진 재시작 없는 가로·세로 캔버스 변경.
- `scripts/web/build.mjs`: Godot import/Export 후 정적 웹 파일과 에셋을 `build/web/`에 복사한다. Node 내장 기능만 사용한다.
- `scripts/web/fingerprint.mjs`: JS/wasm/PCK/worklet 내용의 해시를 파일명에 넣고 엔진 executable/fileSizes 참조를 함께 변경한다. PCK 가상 파일명에 쿼리를 붙이지 않는다. 로더 모듈·CSS에는 내용별 쿼리를 붙여 이전 파일 캐시와 구분한다. 같은 런타임 묶음을 사용하므로 PCK 변경 시 wasm도 새 URL로 내려받는 비용이 있으며 세분화 최적화는 하지 않았다.
- `scripts/web/serve.mjs`: MIME 형식을 지원하는 로컬 전용 HTTP 서버. 기본 주소는 `127.0.0.1:8000`, 포트는 `PORT`로 변경한다.

랜딩페이지는 `/`, 플레이 페이지는 `/play.html`이다. 루트 경로를 하드코딩하지 않아 정적 호스팅의 하위 경로에서도 배포할 수 있다. Pages 배포와 다운로드 릴리즈는 별도 `socra710/paper_warrior_releases` 저장소에서 관리하고 Godot/웹 원본은 `socra710/paper_warrior`에서 관리한다. 계정/백엔드는 구성하지 않는다.

웹 파일 준비 화면은 대형 게임명/캐릭터 없이 파일 패널만 표시한다. 다운로드가 끝났어도 엔진 시작 Promise가 완료되기 전에는 불확정 초기화 상태로 남는다. HTML 자체가 이전 배포로 캐시된 경우 새 파일 해시만으로 오래된 HTML을 교체할 수 없으므로 게시 후 HTML 재검증과 실제 버전 확인이 필요하다.

## 배포 저장소 분리

`scripts/release/build.ps1`은 Web 사이트와 임베디드 PCK를 포함한 Windows x86_64 실행 파일을 만들고 각각 ZIP으로 묶는다. Windows 배포는 설치 마법사가 없는 휴대용·미서명 빌드다. Export preset의 `application/modify_resources=false`는 별도 Windows 리소스 편집 도구 없이 빌드하기 위한 설정이며 파일 탐색기에 보이는 실행 파일 아이콘은 엔진 기본값일 수 있다. 게임 창 아이콘은 프로젝트 로고를 사용한다.

릴리즈 빌드는 깨끗한 소스 작업 트리에서만 수행하고 `build/releases/manifest.json`에 버전·원본 커밋·두 ZIP의 SHA-256을 기록한다. `scripts/release/publish.ps1`은 이 정보가 현재 소스/산출물과 일치하는지 검사하고, 체크섬을 검증한 Web ZIP을 풀어 `build/release-repo/`의 별도 checkout에 복사한 뒤 커밋/푸시한다. 배포 버전과 원본 커밋을 `version.json`에 남기며 Web/Windows ZIP을 배포 저장소 GitHub Releases에 업로드한다. 업로드 실패 후 재시도할 때 변경 없는 배포 커밋은 건너뛴다. 소스 origin은 배포 저장소로 바꾸지 않는다. 인증은 로컬 GitHub CLI credential helper를 사용하고 토큰을 코드에 보관하지 않는다.

배포 저장소의 `main` 푸시는 `deployment/pages.yml`에서 복사된 workflow로 GitHub Pages를 갱신한다. 공개 주소는 `https://socra710.github.io/paper_warrior_releases/`다. 배포 저장소 Pages Source는 GitHub Actions여야 한다.

## 폴더 책임

| 경로 | 책임 |
|---|---|
| `scenes/main/` | 시작 화면과 이후 메인 화면 씬 |
| `scenes/ui/` | 공용 시작 화면과 전사 대기 연출 |
| `scripts/main/` | 씬별 최소 화면 흐름 제어 |
| `assets/characters/warrior/` | 종이 전사 원화와 애니메이션 |
| `assets/monsters/` | 몬스터 아트 |
| `assets/equipment/` | 장비 아트 |
| `assets/decorations/` | 꾸미기 파츠 |
| `assets/backgrounds/` | 배경 |
| `assets/effects/` | 이펙트 |
| `assets/icons/` | UI 및 아이템 아이콘 |
| `assets/audio/` | 음악과 효과음 |
| `assets/fonts/` | Pretendard UI, Galmuri 제목 글꼴과 각각의 라이선스 |
| `data/growth/`, `scripts/data/` | 초기 미리보기 상태 Resource와 타입 |
| `data/items/`, `data/monsters/`, `data/stages/` | 추후 밸런스/콘텐츠 데이터 |
| `docs/` | 기획, 아트, 기술, 작업 문서 |
| `web/`, `scripts/web/` | 정적 랜딩/플레이 페이지와 빌드/서버 도구 |

빈 콘텐츠 디렉터리는 `.gitkeep`으로 추적한다. 현재 애니메이션은 프레젠테이션용 대기 연출뿐이며 전투 스프라이트나 전투용 밸런스 데이터는 추가하지 않는다.

## 렌더링 및 웹 Export

- 렌더링 방법은 Godot Compatibility (`gl_compatibility`)를 사용한다.
- 뷰포트 시작 크기는 480×640이고 `canvas_items` 스트레치를 사용한다. 웹 프레임은 최대 420px 폭에서 3:4 비율로 표시하고 작은 화면에서는 화면 폭에 맞춘다.
- Export preset 이름은 `Web`, 게임 출력은 `build/web/play.html`이며 `web/play.html`을 커스텀 HTML 셸로 사용한다.
- `html/canvas_resize_policy=0`으로 Godot의 브라우저 전체 화면 맞춤을 끈다. 캔버스의 내부 크기는 HTML의 480×640, 표시 크기는 CSS의 3:4 부모 프레임이 관리한다.
- Godot 4.4.1의 텍스트 리소스 바이너리 변환에서 상속한 Control 씬의 여백/테마 재정의가 유실되는 현상을 재현했으므로 `editor/export/convert_text_resources_to_binary=false`를 사용한다. `.tscn`/`.tres`를 보존하며 게임 기능에는 영향을 주지 않는다.
- `build/`, `reports/`, `addons/gdUnit4/`, `tests/`, `web/`, `scripts/web/`, `docs/`는 게임 패키지에서 제외한다.
- 현재 Godot 4 버전에 맞는 Web export templates가 필요하다.
- 브라우저는 WebGL 2.0 호환성 확인을 위해 Chrome 또는 Edge를 사용한다.
- Web 빌드는 HTTP(S) 서버를 통해 연다. `file://` 실행은 검증 방법으로 사용하지 않는다.

## 테스트 자동화

- 에이전트 작업은 GitHub Copilot Agent를 사용하고, GDScript 테스트는 Godot 4.4.1과 호환되는 GdUnit4 v5.1.1로 실행한다.
- `GdUnitSceneRunner`에서 마우스/키 입력을 시뮬레이션해 GUI 씬 흐름을 검증한다.
- SceneRunner GUI 테스트는 창 모드에서 실행한다. `--headless`에서는 엔진이 입력 이벤트를 처리하지 않아 이 테스트를 실행할 수 없다.
- 로컬 명령과 GitHub Actions workflow는 동일한 `res://tests` 테스트 경로를 사용한다.
- `tests/export/StartupLayoutCheck.gd`는 실제 Export된 PCK 또는 임베디드 PCK 실행 파일에서 일러스트 크기, 제목/설명 순서, 버튼 여백을 확인한다. 웹/Windows 빌드 스크립트가 실행하며 에디터 씬 검사만으로는 잡히지 않는 직렬화 문제를 방지한다.

```powershell
godot --path . -s res://addons/gdUnit4/bin/GdUnitCmdTool.gd -a res://tests
node --test tests\web\*.test.mjs
```

## 실행·검증

프로젝트 루트에서:

```powershell
node scripts\web\build.mjs
node scripts\web\serve.mjs
```

로컬 서버가 준비된 후 `/`의 소개/플레이 링크와 `/play.html`의 Splash → Loading → Title → 시작 버튼 → HUD/작은 전사 Game 순서를 확인한다. 데스크톱/모바일에서 가로 넘침과 게임 비율도 확인한다. 브라우저나 Web Export 검사 결과는 실제 실행한 경우에만 성공으로 기록한다.

## 글꼴

`assets/fonts/theme_ui.tres`는 일반 UI에 Pretendard Regular와 재사용 가능한 버튼 스타일을 적용하고, `theme_galmuri.tres`는 픽셀 강조에 Galmuri 11 Bold 아웃라인 글꼴을 적용한다. 로고 PNG의 글자도 기존 Galmuri 합성 원본이다. Web 호환성을 위해 임베디드 비트맵 글리프가 아닌 스케일러블 글리프를 사용한다. 두 글꼴의 라이선스 전문은 각 `LICENSE-*.txt` 파일에 보존한다.

## 향후 구조 원칙

기획서의 전투 계산은 렌더링/애니메이션과 분리된 순수 로직으로 둔다. 스테이지 난이도와 보상은 코드에 상수로 고정하지 않고 `data/`에서 관리한다. 저장 포맷과 Resource/JSON 선택은 실제 저장 기능 단계에서 정한다. 이들은 현재 구현되어 있지 않다.
