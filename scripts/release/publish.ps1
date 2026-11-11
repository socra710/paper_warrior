param([Parameter(Mandatory)][string]$Version)

$ErrorActionPreference = 'Stop'
if ($Version -notmatch '^v\d+\.\d+\.\d+(?:-[0-9A-Za-z.-]+)?$') {
    throw 'Version must use a release tag such as v0.1.0.'
}
$root = Split-Path (Split-Path $PSScriptRoot -Parent) -Parent
$repository = 'socra710/paper_warrior_releases'
$remote = "https://github.com/$repository.git"
$destination = Join-Path $root 'build\release-repo'
$windowsZip = Join-Path $root "build\releases\paper-warrior-windows-x86_64-$Version.zip"
$webZip = Join-Path $root "build\releases\paper-warrior-web-$Version.zip"
$manifestPath = Join-Path $root 'build\releases\manifest.json'
foreach ($required in @($manifestPath, $windowsZip, $webZip)) {
    if (!(Test-Path -LiteralPath $required -PathType Leaf)) { throw "Build output missing: $required" }
}
$sourceCommit = & git -C $root rev-parse --verify HEAD
if ($LASTEXITCODE -ne 0) { throw 'Commit and push the verified source before publishing.' }
$sourceChanges = & git -C $root status --porcelain
if ($LASTEXITCODE -ne 0 -or $sourceChanges) { throw 'Source worktree must be clean before publishing.' }
$manifest = Get-Content -LiteralPath $manifestPath -Raw | ConvertFrom-Json
if ($manifest.version -ne $Version -or $manifest.source_commit -ne $sourceCommit) {
    throw 'Build artifacts do not match this version and source commit. Rebuild the release.'
}
if ((Get-FileHash -LiteralPath $windowsZip -Algorithm SHA256).Hash -ne $manifest.windows_sha256 -or
    (Get-FileHash -LiteralPath $webZip -Algorithm SHA256).Hash -ne $manifest.web_sha256) {
    throw 'Release archive checksums changed. Rebuild the release.'
}
$author = & git -C $root config user.name
$email = & git -C $root config user.email
if (!$author -or !$email) { throw 'Configure Git user.name and user.email in the source checkout.' }
& gh api "repos/socra710/paper_warrior/commits/$sourceCommit" --silent
if ($LASTEXITCODE -ne 0) { throw 'Push the source commit to paper_warrior before publishing.' }
& gh release view $Version --repo $repository *> $null
if ($LASTEXITCODE -eq 0) { throw "Release $Version already exists. Use a new version." }

if (!(Test-Path -LiteralPath $destination)) {
    & gh repo clone $repository $destination
    if ($LASTEXITCODE -ne 0) { throw 'Unable to clone the deployment repository.' }
}
$actualRemote = & git -C $destination remote get-url origin
if ($LASTEXITCODE -ne 0 -or $actualRemote -ne $remote) { throw 'Unexpected deployment origin.' }
$changes = & git -C $destination status --porcelain
if ($LASTEXITCODE -ne 0 -or $changes) { throw 'Deployment worktree must be clean before publishing.' }
& git -C $destination config credential.helper '!gh auth git-credential'
& git -C $destination rev-parse --verify HEAD *> $null
if ($LASTEXITCODE -ne 0) {
    & git -C $destination symbolic-ref HEAD refs/heads/main
} else {
    $branch = & git -C $destination branch --show-current
    if ($branch -ne 'main') { throw 'Deployment checkout must be on main.' }
    & git -C $destination pull --ff-only origin main
    if ($LASTEXITCODE -ne 0) { throw 'Unable to update deployment main.' }
}

$web = Join-Path $root "build\publish-web-$([guid]::NewGuid().ToString('N'))"
Expand-Archive -LiteralPath $webZip -DestinationPath $web
Get-ChildItem -LiteralPath $web -File -Recurse -Force | ForEach-Object {
    $relative = [System.IO.Path]::GetRelativePath($web, $_.FullName)
    $target = Join-Path $destination $relative
    New-Item -ItemType Directory -Force (Split-Path $target -Parent) | Out-Null
    Copy-Item -LiteralPath $_.FullName -Destination $target
}
$workflowDirectory = Join-Path $destination '.github\workflows'
New-Item -ItemType Directory -Force $workflowDirectory | Out-Null
Copy-Item -LiteralPath (Join-Path $root 'deployment\pages.yml') -Destination (Join-Path $workflowDirectory 'pages.yml')
Copy-Item -LiteralPath (Join-Path $root 'deployment\README.md') -Destination (Join-Path $destination 'README.md')
@{ version = $Version; source_repository = 'socra710/paper_warrior'; source_commit = $sourceCommit } |
    ConvertTo-Json | Set-Content -LiteralPath (Join-Path $destination 'version.json') -Encoding utf8

& git -C $destination add --all
if ($LASTEXITCODE -ne 0) { throw 'Unable to stage deployment output.' }
& git -C $destination diff --cached --quiet
$stagedChanges = $LASTEXITCODE
if ($stagedChanges -eq 1) {
    & git -C $destination -c "user.name=$author" -c "user.email=$email" commit -m "release: publish Paper Warrior $Version" -m 'Co-authored-by: Copilot <223556219+Copilot@users.noreply.github.com>'
    if ($LASTEXITCODE -ne 0) { throw 'Unable to commit deployment output.' }
} elseif ($stagedChanges -ne 0) {
    throw 'Unable to inspect staged deployment output.'
}
& git -C $destination push -u origin main
if ($LASTEXITCODE -ne 0) { throw 'Unable to push deployment output.' }

$notes = @"
## 새롭게 선보이는 모습

- 원래 컨셉을 참고해 전사의 얼굴과 몸통·다리 연결을 다듬고 대기·걷기·달리기 애니메이션을 추가했습니다.
- 발밑 그림자와 또렷한 픽셀 외곽선, 천천히 움직이는 구름과 수목, 물빛·풍차·나비를 더했습니다.
- 종이 숲 배경과 프로필, 스테이지 리본, 다섯 개의 메뉴를 새롭게 구성했습니다.

## 시작 화면과 편의 개선

- 스플래시·로딩·타이틀 화면을 구분하고 종이접기 연출과 읽기 편한 문구를 적용했습니다.
- 리소스 로딩 상태와 오류·재시도를 구분하고 화면 전환 안정성을 보완했습니다.
- 세로와 가로 화면에서 메뉴를 재배치하며 기존 화면 상태를 유지합니다.

## 현재 이용 가능한 범위

게임 화면에서 전사의 산책 연출과 초기 레벨·골드·스테이지를 볼 수 있습니다. 성장·장비·꾸미기·상점·이벤트·미션·설정은 준비 중 안내만 제공하며, 실제 전투·성장·보상·저장은 아직 구현되지 않았습니다.
저장 기능이나 기존 저장 데이터 형식 변경은 없습니다.

웹 게임: https://socra710.github.io/paper_warrior_releases/play.html
소스: https://github.com/socra710/paper_warrior/commit/$sourceCommit

Windows x86_64: 압축을 푼 뒤 PaperWarrior.exe를 실행합니다. 설치 프로그램이나 코드 서명이 없는 휴대용 빌드입니다.
Web ZIP: 정적 웹사이트와 Godot 웹 빌드이며 HTTP(S) 서버가 필요합니다.
"@
& gh release create $Version $windowsZip $webZip --repo $repository --target main --title "종이전사 $Version · 첫 번째 접힘" --notes $notes --prerelease
if ($LASTEXITCODE -ne 0) { throw 'Website pushed, but release asset upload failed.' }
Write-Output "Published $Version to $repository. Check its Pages workflow before sharing the public URL."
