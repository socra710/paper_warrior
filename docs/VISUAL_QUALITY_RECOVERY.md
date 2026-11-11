# 화면 및 캐릭터 품질 복구 조사·작업 기록

## 1. 수정 전 조사와 원인

조사 기준은 `socra710`의 `9fdf5c1` / 공개 v0.3.0이다. Godot 4.4.1 Compatibility, GDScript, GdUnit4 v5.1.1과 기존 Web/Windows 빌드·별도 배포 저장소 구조를 유지한다.

`project.godot`의 실제 시작 씬은 `scenes/main/splash.tscn`이다. `splash.gd`가 1.2초 뒤 Loading으로 이동하고 `loading.gd`가 실제 Title/Game 요청을 준비한다. Title은 준비된 Game을 사용하며 중복 시작 방지, 오류 후 재시도/재실행 기능은 유지 대상이다.

### 화면 구분

- Splash와 Title이 `scenes/ui/start_screen.tscn`을 함께 상속한다. 이름/구도가 거의 같고 Splash는 같은 전사를 서서히 표시한다.
- Godot Loading은 별도 씬이며 실제 `ResourceLoader` 준비 상태를 읽는다. 같은 씬을 재사용하는 것은 아니다.
- 하지만 **Godot 실행 전 웹 다운로드 오버레이**도 큰 게임 제목과 같은 전사를 사용한다. 사용자가 먼저 보는 다운로드 화면이 Splash/Title과 비슷한 것이 실제 혼동 원인이다.
- Loading은 빈 progress 배열도 0%처럼 표시하고, 진행 중 요청이 1.0을 보고하면 완료되지 않아도 합계 100%가 될 수 있다. 불확정 상태와 최종 완료를 분리해야 한다.
- 각 씬의 세로 480×640 / 가로 960×540 렌더를 저장했다. 로딩의 빠른 통과를 디자인이 구분된다는 근거로 사용하지 않는다.

### 캐릭터 회귀

`warrior_key_art.svg`는 `2753978`(v0.2.0)과 현재 사이에 변경이 없다. 정상 참조를 그대로 보유하고 있다.

`319f0d0`에서 새 `warrior_parts.svg`/PNG 시트를 추가하면서 도형을 재해석했다. 원본의 기울어진 접힌 머리, 삼각 종이 몸통, 비스듬한 검, 오각 별 방패가 사각 머리·분절 몸통·수직 검·십자 장식으로 바뀌었다. 이는 파일 형식 전환 문제가 아니라 **외형 재작성과 팔레트 교체**다. 48px의 큰 상대 이동과 눈 감기 변형도 외형 변화 인상을 강화한다.

동일 배경/192×192 표시 영역에서 원본 도형, 원본의 48px/96px PNG 후보, v0.3 PNG를 비교했다. 48px 원본 변환은 눈·접힘·별이 손상됐다. 96px 후보는 원본 비율과 장비 형태를 더 잘 유지한다.

![같은 표시 크기의 실제 Godot 비교](images/quality-v040/character-investigation.png)

## 2. 복구 지점과 원본 보호

- 작업 전 복구 태그: `quality-before-v0.4.0` → `9fdf5c1`.
- 정상 참조 태그: `character-reference-v0.2.0` → `2753978`.
- `warrior_key_art.svg`의 도형/색상/그라데이션을 직접 수정하지 않는다.
- 캐릭터 변경과 화면 변경은 별도 커밋으로 분리한다. 게임 시스템은 추가/제거하지 않는다.
- 기존 v0.3 외형은 복구 태그에 보존한다. 새 후보가 원본 충실도를 개선하지 못하면 정상 참조 방식을 유지한다.

## 3. 비교한 접근과 수정 계획

1. **원본 SVG 직접 복원:** 외형 보존이 가장 확실하지만 걷기 프레임과 PNG 기본 제작 흐름이 후퇴한다.
2. **원본 도형 그대로 PNG 생성 — 선택:** 공통 부품의 도형/선/색을 정상 SVG와 일치시키고 작은 위치 이동만 데이터로 관리한다. 확대 비교에서 더 충실한 **96×96 예외**를 사용하되 실제 표시 크기는 기존과 동일하게 줄인다. 48px 기본 규격을 무조건 적용해 외형을 훼손하지 않는다.
3. **새 픽셀 캐릭터 재디자인:** 이번 요청에 어긋나므로 제외한다.

### 캐릭터 변경 단위

- 공통 부품 SVG에 정상 원본의 경로를 그대로 분리하고 원본과의 대응을 기록한다.
- 생성기/동작 JSON은 96×96, 고정 중심/발 기준선, Idle 4 / Walk 6을 사용한다.
- 얼굴/머리/장비의 프레임별 재해석, 눈·입 교체와 신체 스케일 변형을 제거한다. 대기는 미세한 평행 이동만 사용한다.
- 맵은 총 72px 프레임, Title 미리보기는 총 144px로 유지한다. 파일 해상도와 화면 표시 크기를 혼동하지 않는다.
- 투명 PNG와 Nearest는 유지한다. 정상 원본의 색을 v0.3의 다른 7색으로 재매핑하지 않는다.

### 화면 변경 단위

- **웹 다운로드:** 전사/대형 로고를 제거한 파일 준비 패널. 실제 바이트 또는 불확정 상태와 오류/재시도만 표시한다.
- **Splash:** 독립 Control 씬. 종이 접힘 배경과 실제 로고, 짧은 인트로. 진행률/로딩 재시도 UI는 두지 않는다. 전환 실패 시 로고 화면에 오류를 남긴다.
- **Loading:** 독립 리소스 준비 화면. 종이 UI 애니메이션과 작업 상태를 중심으로 배치한다. 알 수 없는 진행률은 불확정, 준비 중은 최대 99%, 모든 요청이 완료된 때만 100%다.
- **Title:** 로고·기준 캐릭터·모험 시작 버튼. 기존 준비된 Game 소비, 오류 복구와 키보드 접근성을 유지한다.
- **Game:** 기존 HUD/메뉴/작은 맵 이동은 유지한다. 전투·성장·보상·저장을 새로 구현하지 않는다.
- 버튼/글꼴/테두리는 공통 테마로 관리하고 화면 전체를 재사용해 구도가 같아지지 않게 한다.

### 예정 파일과 실행·검증

캐릭터: `assets/characters/warrior/warrior_parts.svg`, `data/presentation/warrior_animation.json`, `scripts/art/build_warrior_sprites.gd`, 생성 시트/씬, `scenes/ui/warrior_idle.tscn`.

화면: `scenes/main/splash.tscn`, `scripts/main/splash.gd`, Loading 씬/스크립트, Title 전용 레이아웃, 공통 버튼 테마, `web/play.html`, 로더 CSS/JS 및 `scripts/web/build.mjs`.

회귀 검사: 기존 GdUnit/Node/export 검사를 유지하고 화면 독립성, Splash 실패/중복 방지, 알 수 없는 진행률, 미완료 100% 방지, 캐시 버전 구분을 추가한다.

```powershell
godot --headless --path . --script res://scripts/art/build_warrior_sprites.gd
godot --headless --editor --path . --import
godot --path . -s res://addons/gdUnit4/bin/GdUnitCmdTool.gd -a res://tests
node --test tests\web\*.test.mjs
node scripts\web\build.mjs "C:\Tools\Godot\Godot_v4.4.1-stable_win64_console.exe"
```

수정 전후 씬 사진은 같은 480×640 / 960×540 창에서 저장한다. 로딩 UI 사진은 통제된 백엔드의 미리보기이며 실제 콜드 시작과 실패/재시도는 별도로 실행한다. 웹은 엔진/PCK 실패, 반복 부팅, 방향 변경, 콘솔/게임 로그와 이전 배포 캐시를 확인한 후 새 버전으로 게시한다. 수행 전 검사를 통과로 기록하지 않는다.

## 4. 실제 결과

이 절은 구현·실행 후 관찰한 결과만 추가한다. 현재 단계에서는 수정 전 조사와 비교 렌더만 수행했다.
