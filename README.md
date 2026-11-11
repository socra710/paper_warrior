# 종이전사 (Paper Warrior)

종이 접기 전사 한 명을 키우는 웹 우선 2D 픽셀 방치형 RPG의 Godot 4 프로토타입이다. 소개 랜딩페이지와 중앙의 작은 세로형 웹 게임 프레임을 제공한다. Splash → 실제 리소스 Loading → Title → Main Game 흐름에서 전사의 대기 연출, 초기 레벨·골드, 스테이지와 메뉴 안내를 확인할 수 있다. 전투·성장·보상·저장은 아직 구현하지 않았다.

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

게임 프레임은 데스크톱에서 최대 420px 폭, 내부 게임은 480×640(3:4)이다. 모바일에서는 가로 폭에 맞춰 축소한다. Splash는 로고와 전사의 짧은 인사, Loading은 별도의 종이 공방 화면이다. 브라우저 다운로드는 실제 바이트, 게임 Loading은 Title/Game 씬과 종속 리소스의 실제 준비율을 표시한다. 준비가 빠르면 Loading도 짧게 표시된다.

Title의 **모험 시작하기**를 누르면 종이 숲에서 대기 중인 전사, 스테이지 1-1, 레벨 1·골드 0과 전투 대기 영역을 볼 수 있다. 성장·장비·꾸미기 버튼은 각각 **준비 중** 안내만 열며 닫기 버튼이나 Escape로 돌아온다. 초기 수치는 변하지 않고 전투·보상·저장은 진행되지 않는다.

## Web · Windows 릴리즈

PowerShell 7에서 변경 사항을 검증·커밋한 뒤, 깨끗한 소스 작업 트리에서 버전 태그와 Godot 실행 파일을 지정해 빌드한다.

```powershell
.\scripts\release\build.ps1 -Version v0.2.0 -Godot "C:\Tools\Godot\Godot_v4.4.1-stable_win64_console.exe"
```

`build\releases\`에 Web ZIP과 Windows x86_64 휴대용 ZIP, 버전·소스 커밋·ZIP SHA-256을 기록한 `manifest.json`이 생성된다. 게시 시 이 정보와 현재 커밋을 비교해 다른 버전의 빌드를 잘못 배포하지 않도록 한다. Windows ZIP은 압축을 풀고 `PaperWarrior.exe`를 실행하는 방식이며 설치 마법사와 코드 서명은 없다.

소스를 커밋·푸시한 뒤 GitHub CLI로 인증된 배포 권한 계정에서 게시한다. 다음 명령은 **배포 저장소 main에 커밋·푸시하고 공개 사전 릴리즈를 생성**한다.

```powershell
.\scripts\release\publish.ps1 -Version v0.2.0
```

`build\release-repo\`에 배포 저장소를 별도로 복제한다. 빌드 산출물·글꼴 라이선스·Pages workflow·원본 커밋 추적용 `version.json`만 게시하며 소스 저장소 origin은 변경하지 않는다. 사용한 버전은 재사용하지 않는다. 최초 게시 시 배포 저장소 **Settings → Pages → Source: GitHub Actions**를 설정한다. 배포 저장소에 포함되는 workflow 원본은 `deployment\pages.yml`이다. 교차 저장소 PAT를 소스나 빌드 파일에 넣지 않는다.

## 테스트

프로젝트 루트에서 GUI 입력을 처리할 수 있는 창 모드로 실행한다. `--headless`는 SceneRunner의 마우스/키보드 입력을 전달하지 못하므로 사용하지 않는다.

```powershell
godot --path . -s res://addons/gdUnit4/bin/GdUnitCmdTool.gd -a res://tests
node --test tests\web\loader.test.mjs
```

GdUnit4 v5.1.1의 SceneRunner로 시작 화면의 글꼴·일러스트, 실제 게임 리소스 준비 후 Title 전환, 시작 버튼과 초기 HUD, 대기 애니메이션, 세 메뉴 안내의 열기·닫기와 Escape를 확인한다. Node 테스트는 웹 로더의 다운로드 진행률·성공·미지원 브라우저·실패 처리를 검증한다. Web/Windows 빌드는 패키지에서 리소스 캐시 없는 전체 시작 흐름을 실행한 뒤 게임 HUD/리소스/화면 경계를 검사한다. GitHub Actions의 `.github/workflows/test.yml`에 GUI·웹 로더 테스트 작업을 구성했다.

## 프로젝트 문서

- [종합 게임 기획서](docs/GAME_DESIGN.md)
- [아트 가이드](docs/ART_GUIDE.md)
- [기술 설계](docs/TECHNICAL_DESIGN.md)
- [개발 로드맵](docs/TASKS.md)
- [초기 기반 설계](docs/superpowers/specs/2026-11-11-paper-warrior-foundation-design.md)
- [구현 계획](docs/superpowers/plans/2026-11-11-paper-warrior-foundation.md)
