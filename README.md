# 종이전사 (Paper Warrior)

종이 접기 전사 한 명을 키우는 웹 우선 2D 픽셀 방치형 RPG의 Godot 4 프로토타입이다. 소개 랜딩페이지와 중앙의 작은 웹 게임 프레임을 제공한다. Splash → 실제 리소스 Loading → Title → Main Game 흐름에서 픽셀 전사의 대기/맵 이동 연출, 초기 레벨·골드, 스테이지와 메뉴 안내를 확인할 수 있다. 이동은 프레젠테이션이며 전투·성장·보상·저장은 아직 구현하지 않았다.

| 저장소 | 역할 |
|---|---|
| <https://github.com/socra710/paper_warrior> | Godot/웹 원본, 테스트, 에셋과 개발 문서 |
| <https://github.com/socra710/paper_warrior_releases> | 랜딩페이지·Web 빌드 게시, GitHub Pages와 다운로드 릴리즈 |

공개 랜딩페이지는 <https://socra710.github.io/paper_warrior_releases/>, 웹 게임은 같은 주소의 `play.html`, Windows 다운로드는 [배포 저장소 Releases](https://github.com/socra710/paper_warrior_releases/releases)에서 제공한다. 원본은 소스 저장소에서 수정하고 검증된 산출물만 배포 저장소에 게시한다.

## 요구 도구

- Godot 4.x 및 Web export templates
- GUI 입력 테스트를 실행할 수 있는 데스크톱 환경
- Chrome 또는 Edge (웹 실행 확인용)
- 로컬 정적 HTTP 서버 (브라우저에서 Web Export를 열 때 필요)
- Node.js 22 이상 (웹사이트 빌드·로컬 서버·웹 로더 테스트, 별도 npm 패키지 불필요)

프로젝트 설정은 웹 호환성을 고려해 Compatibility 렌더러를 사용한다.
화면 제목에는 Galmuri, 일반 UI에는 Pretendard를 사용한다.

## 실행

프로젝트 디렉터리에서:

```powershell
godot --path .
```

Godot 편집기에서 `project.godot`을 열고 F6으로 현재 씬을 실행할 수도 있다. 전체 시작 흐름은 F6 대신 프로젝트 실행(F5)으로 확인한다.

## 웹사이트 빌드와 실행

랜딩페이지와 게임 페이지는 한 디렉터리에 배포한다. 프로젝트 루트에서:

```powershell
node scripts\web\build.mjs
node scripts\web\serve.mjs
```

Godot가 PATH에 없다면 실행 파일 경로를 빌드 명령의 첫 번째 인자로 넘기거나 `GODOT_BIN` 환경 변수로 설정한다.

```powershell
node scripts\web\build.mjs "C:\Tools\Godot\Godot_v4.4.1-stable_win64_console.exe"
```

첫 Export 전에 Godot에서 **Editor → Manage Export Templates**로 현재 엔진 버전의 export templates를 설치한다. 빌드 스크립트가 프로젝트 import, Web Export, HTML/CSS/글꼴/라이선스/일러스트 복사를 수행한다. 출력은 `build\web\`이며, 개별 Export만으로는 랜딩페이지와 공용 파일이 복사되지 않는다.

- 랜딩페이지: <http://127.0.0.1:8000/>
- 게임 페이지: <http://127.0.0.1:8000/play.html>

두 주소는 로컬 전용이다. 공개 배포는 별도 정적 호스팅에 `build\web\` 전체를 업로드한다. HTML은 HTTP(S)로 열고 `file://`로 직접 실행하지 않는다. 기본 포트가 사용 중이면 `$env:PORT = "8001"`로 변경한다.

게임 프레임은 기본 최대 420px 폭의 세로형 3:4다. 높이가 짧은 가로 화면에서는 16:9와 맵/사이드 메뉴 배치로 전환한다. 방향을 바꿔도 같은 엔진과 씬을 유지해 열린 메뉴와 상태가 보존된다. Splash는 로고와 픽셀 전사의 짧은 인사, Loading은 별도 종이 접기 화면이다. 브라우저는 실제 다운로드 바이트, 게임은 Title/Game 씬의 실제 준비율을 표시한다. 준비가 빠르면 Loading도 짧다.

Title의 **모험 시작하기**를 누르면 작은 전사가 종이 숲을 둘러보고 스테이지 1-1, 레벨 1·골드 0과 전투 대기 영역이 표시된다. 성장·장비·꾸미기 버튼은 **준비 중** 안내만 열며 닫기나 Escape로 돌아온다. 모든 화면과 웹 셸은 `project.godot`의 버전을 표시한다.

웹 부팅은 엔진 스크립트 다운로드부터 90초 제한을 적용하고 실패 시 실제 새로고침으로 재시도한다. 게임 Loading은 일반 실패와 20초 시간 초과를 구분한다. 일반 실패는 요청을 다시 수행하고 시간 초과는 **처음부터 다시 시작**으로 웹 새로고침/데스크톱 앱 재실행을 수행한다. 엔진이 UI까지 완전히 멈추거나 OS가 재실행을 차단하면 수동으로 다시 열어야 한다.

## 캐릭터 에셋 제작

[캐릭터 스프라이트 제작 지침](docs/CHARACTER_SPRITE_STANDARD.md)에 SVG 허용 범위, PNG 기본 정책, 48×48 규격, 모든 애니메이션 프레임 수와 품질 점검 기준을 기록했다. 외형은 공통 `warrior_parts.svg`, 동작은 `data/presentation/warrior_animation.json`에서 관리한다. 프레임 SVG를 따로 편집하지 않는다.

```powershell
godot --headless --path . --script res://scripts/art/build_warrior_sprites.gd
godot --headless --editor --path . --import
```

생성기는 공통 부품과 동작 데이터에서 SVG 시트, 투명 PNG와 SpriteFrames 씬을 생성한다. 현재 Idle 4·Walk 6프레임만 사용하며 나머지 전투 애니메이션은 제작 기준만 문서화했다. 런타임은 PNG/Nearest를 사용하고 마스터/제작 도구는 배포 패키지에서 제외한다.

## Web · Windows 릴리즈

PowerShell 7에서 변경 사항을 검증·커밋한 뒤, 깨끗한 소스 작업 트리에서 버전 태그와 Godot 실행 파일을 지정해 빌드한다.

```powershell
.\scripts\release\build.ps1 -Version v0.3.0 -Godot "C:\Tools\Godot\Godot_v4.4.1-stable_win64_console.exe"
```

`build\releases\`에 Web ZIP과 Windows x86_64 휴대용 ZIP, 버전·소스 커밋·ZIP SHA-256을 기록한 `manifest.json`이 생성된다. 게시 시 이 정보와 현재 커밋을 비교해 다른 버전의 빌드를 잘못 배포하지 않도록 한다. Windows ZIP은 압축을 풀고 `PaperWarrior.exe`를 실행하는 방식이며 설치 마법사와 코드 서명은 없다.

소스를 커밋·푸시한 뒤 GitHub CLI로 인증된 배포 권한 계정에서 게시한다. 다음 명령은 **배포 저장소 main에 커밋·푸시하고 공개 사전 릴리즈를 생성**한다.

```powershell
.\scripts\release\publish.ps1 -Version v0.3.0
```

`build\release-repo\`에 배포 저장소를 별도로 복제한다. 빌드 산출물·글꼴 라이선스·Pages workflow·원본 커밋 추적용 `version.json`만 게시하며 소스 저장소 origin은 변경하지 않는다. 사용한 버전은 재사용하지 않는다. 최초 게시 시 배포 저장소 **Settings → Pages → Source: GitHub Actions**를 설정한다. 배포 저장소에 포함되는 workflow 원본은 `deployment\pages.yml`이다. 교차 저장소 PAT를 소스나 빌드 파일에 넣지 않는다.

## 테스트

프로젝트 루트에서 GUI 입력을 처리할 수 있는 창 모드로 실행한다. `--headless`는 SceneRunner의 마우스/키보드 입력을 전달하지 못하므로 사용하지 않는다.

```powershell
godot --path . -s res://addons/gdUnit4/bin/GdUnitCmdTool.gd -a res://tests
node --test tests\web\loader.test.mjs tests\web\viewport.test.mjs
```

GdUnit4 v5.1.1의 SceneRunner로 글꼴, 실제 리소스 준비, 로딩 실패/재시도/시간 초과, 중복 시작 방지, PNG 프레임과 맵 이동, 버전, 메뉴와 방향 변경 시 상태 보존을 검사한다. Node 테스트는 웹 부팅 진행률/실패/시간 초과/중복 방지와 같은 캔버스의 방향 전환을 검사한다. Web/Windows 빌드는 패키지의 콜드 시작과 양방향 레이아웃을 검사한다. 브라우저의 실제 다운로드 실패·재시도와 콘솔/시각 품질은 별도 실행 확인이 필요하다.

## 프로젝트 문서

- [종합 게임 기획서](docs/GAME_DESIGN.md)
- [아트 가이드](docs/ART_GUIDE.md)
- [캐릭터 스프라이트 제작 지침](docs/CHARACTER_SPRITE_STANDARD.md)
- [기술 설계](docs/TECHNICAL_DESIGN.md)
- [개발 로드맵](docs/TASKS.md)
- [초기 기반 설계](docs/superpowers/specs/2026-11-11-paper-warrior-foundation-design.md)
- [구현 계획](docs/superpowers/plans/2026-11-11-paper-warrior-foundation.md)
