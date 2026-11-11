# 기술 설계

## 초기 범위

Godot 4와 GDScript를 사용하며 브라우저 우선으로 검증한다. 이번 단계는 프로젝트 설정과 네 화면의 전환 골격만 제공한다. 전투, 캐릭터, HUD, 데이터 로딩, 저장, 오프라인 보상, Android Export는 포함하지 않는다.

## 시작 화면 흐름

```text
project.godot
  └── scenes/main/splash.tscn
        └── 1.2초 후 scenes/main/loading.tscn
              └── 0.9초 후 scenes/main/title.tscn
                    └── 시작 버튼 → scenes/main/game.tscn
```

| 씬 | 책임 | 스크립트 |
|---|---|---|
| `scenes/main/splash.tscn` | 프로젝트 시작 화면, Loading으로 자동 이동 | `scripts/main/splash.gd` |
| `scenes/main/loading.tscn` | 준비 단계 표시, Title로 자동 이동 | `scripts/main/loading.gd` |
| `scenes/main/title.tscn` | 게임명과 시작 버튼 표시 | `scripts/main/title.gd` |
| `scenes/main/game.tscn` | 비어 있는 Main Game 목적지 | `scripts/main/game.gd` |

씬 전환은 `SceneTree.change_scene_to_file`을 사용하고 반환된 오류를 출력한다. Splash/Loading의 Timer는 화면 흐름만 확인하기 위한 임시 대기이며 리소스 로더가 아니다. Main Game은 빈 `Control`만 표시한다.

세 시작 씬은 `scenes/ui/start_screen.tscn`을 상속한다. 제목, 일러스트, 하단 안내와 버튼 스타일을 공유하고 각 씬에서 표시할 문구/컨트롤만 재정의한다. Splash는 일러스트 페이드인, Loading은 준비 문구 점멸을 사용한다. Title 버튼의 씬 변경은 GUI 입력 처리와 충돌하지 않게 지연 호출한다.

## 웹사이트

- `web/index.html`: 별도 설치가 필요 없는 정적 랜딩페이지. 소개, 기획 중인 특징, 현재 프로토타입 범위를 표시한다.
- `web/play.html`: Godot 커스텀 HTML 셸. 제목 → 작은 중앙 게임 프레임 → 조작/프로토타입 안내 순서다.
- `web/site.css`, `web/game-loader.css`: 공용 사이트 스타일과 플레이 프레임/부팅 화면 스타일.
- `web/game-loader.mjs`: 실제 Godot 다운로드 진행률, 부팅 완료, 미지원 브라우저 및 다운로드 오류 처리. 오류는 화면에 출력하고 새로고침 재시도를 제공한다.
- `scripts/web/build.mjs`: Godot import/Export 후 정적 웹 파일과 에셋을 `build/web/`에 복사한다. Node 내장 기능만 사용한다.
- `scripts/web/serve.mjs`: MIME 형식을 지원하는 로컬 전용 HTTP 서버. 기본 주소는 `127.0.0.1:8000`, 포트는 `PORT`로 변경한다.

랜딩페이지는 `/`, 플레이 페이지는 `/play.html`이다. 루트 경로를 하드코딩하지 않아 정적 호스팅의 하위 경로에서도 배포할 수 있다. Pages 배포와 다운로드 릴리즈는 별도 `socra710/paper_warrior_releases` 저장소에서 관리하고 Godot/웹 원본은 `socra710/paper_warrior`에서 관리한다. 계정/백엔드는 구성하지 않는다.

## 배포 저장소 분리

`scripts/release/build.ps1`은 Web 사이트와 임베디드 PCK를 포함한 Windows x86_64 실행 파일을 만들고 각각 ZIP으로 묶는다. Windows 배포는 설치 마법사가 없는 휴대용·미서명 빌드다. Export preset의 `application/modify_resources=false`는 별도 Windows 리소스 편집 도구 없이 빌드하기 위한 설정이며 파일 탐색기에 보이는 실행 파일 아이콘은 엔진 기본값일 수 있다. 게임 창 아이콘은 프로젝트 로고를 사용한다.

릴리즈 빌드는 깨끗한 소스 작업 트리에서만 수행하고 `build/releases/manifest.json`에 버전·원본 커밋·두 ZIP의 SHA-256을 기록한다. `scripts/release/publish.ps1`은 이 정보가 현재 소스/산출물과 일치하는지 검사하고, 체크섬을 검증한 Web ZIP을 풀어 `build/release-repo/`의 별도 checkout에 복사한 뒤 커밋/푸시한다. 배포 버전과 원본 커밋을 `version.json`에 남기며 Web/Windows ZIP을 배포 저장소 GitHub Releases에 업로드한다. 업로드 실패 후 재시도할 때 변경 없는 배포 커밋은 건너뛴다. 소스 origin은 배포 저장소로 바꾸지 않는다. 인증은 로컬 GitHub CLI credential helper를 사용하고 토큰을 코드에 보관하지 않는다.

배포 저장소의 `main` 푸시는 `deployment/pages.yml`에서 복사된 workflow로 GitHub Pages를 갱신한다. 공개 주소는 `https://socra710.github.io/paper_warrior_releases/`다. 배포 저장소 Pages Source는 GitHub Actions여야 한다.

## 폴더 책임

| 경로 | 책임 |
|---|---|
| `scenes/main/` | 시작 화면과 이후 메인 화면 씬 |
| `scenes/ui/` | 시작 화면의 재사용 가능한 프레젠테이션 |
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
| `data/items/`, `data/monsters/`, `data/stages/`, `data/growth/` | 추후 밸런스/콘텐츠 데이터 |
| `docs/` | 기획, 아트, 기술, 작업 문서 |
| `web/`, `scripts/web/` | 정적 랜딩/플레이 페이지와 빌드/서버 도구 |

빈 콘텐츠 디렉터리는 `.gitkeep`으로 추적한다. 시작 화면과 웹의 정적 키 아트 외에 전투용 데이터나 애니메이션은 추가하지 않는다.

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
node --test tests\web\loader.test.mjs
```

## 실행·검증

프로젝트 루트에서:

```powershell
node scripts\web\build.mjs
node scripts\web\serve.mjs
```

로컬 서버가 준비된 후 `/`의 소개/플레이 링크와 `/play.html`의 Splash → Loading → Title → 시작 버튼 → 빈 Main Game 순서를 확인한다. 데스크톱/모바일에서 가로 넘침과 게임 비율도 확인한다. 브라우저나 Web Export 검사 결과는 실제 실행한 경우에만 성공으로 기록한다.

## 글꼴

`assets/fonts/theme_ui.tres`는 일반 UI에 Pretendard Regular를 적용하고, `theme_galmuri.tres`는 게임 제목에 Galmuri 11 Bold 아웃라인 글꼴을 적용한다. Web 호환성을 위해 임베디드 비트맵 글리프가 아닌 스케일러블 글리프를 사용한다. Splash/Title의 제목은 Galmuri, 버튼과 Loading UI는 Pretendard를 사용한다. 두 글꼴의 라이선스 전문은 각 `LICENSE-*.txt` 파일에 보존한다.

## 향후 구조 원칙

기획서의 전투 계산은 렌더링/애니메이션과 분리된 순수 로직으로 둔다. 스테이지 난이도와 보상은 코드에 상수로 고정하지 않고 `data/`에서 관리한다. 저장 포맷과 Resource/JSON 선택은 실제 저장 기능 단계에서 정한다. 이들은 현재 구현되어 있지 않다.
