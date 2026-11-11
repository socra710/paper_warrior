# 종이전사 배포

이 저장소는 종이전사의 랜딩페이지, Web 빌드 및 배포 릴리즈를 관리한다.
Godot 소스, 테스트 및 개발 문서는 [소스 저장소](https://github.com/socra710/paper_warrior)에서 관리한다.

- 랜딩페이지: <https://socra710.github.io/paper_warrior_releases/>
- 웹 게임: <https://socra710.github.io/paper_warrior_releases/play.html>
- Windows 다운로드: <https://github.com/socra710/paper_warrior_releases/releases>

현재 프로토타입은 로고/전사 Splash → 실제 리소스 Loading → Title → 첫 게임 화면으로 이어진다.
종이 숲에서 전사 대기 연출, 초기 레벨·골드와 스테이지/전투 대기 영역을 확인할 수 있다.
성장·장비·꾸미기 메뉴는 준비 중 안내만 제공하며 전투·성장·보상·저장은 진행되지 않는다.

Windows 배포물은 압축을 풀고 `PaperWarrior.exe`를 실행하는 **휴대용 ZIP**이다.
설치 마법사와 코드 서명은 포함하지 않는다. 서명되지 않은 초기 개발 빌드이므로 Windows에서 보안 경고가 표시될 수 있다.

`main` 브랜치의 정적 파일은 GitHub Actions로 Pages에 배포한다.
게임 로직은 이 저장소에서 수정하지 않고 소스 저장소에서 수정·검증한 뒤 빌드를 갱신한다.
