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
Paper Warrior prototype: short logo/warrior Splash -> real resource Loading -> Title -> first game preview.
Includes a shared-parts-generated pixel PNG warrior with idle/walk map presentation, version labels, stage/combat waiting area, initial level/gold HUD, and clearly labeled upcoming growth/equipment/decoration menus.
Startup guards duplicate transitions, distinguishes loading failures/timeouts, and provides real retry. Portrait/landscape layout changes preserve the current scene and open menu.
No combat, progression, rewards, or saves yet. Preview counters do not increase.

Website: https://socra710.github.io/paper_warrior_releases/
Source: https://github.com/socra710/paper_warrior/commit/$sourceCommit

Windows x86_64: unzip and run PaperWarrior.exe. Portable build, not a setup installer; unsigned.
Web ZIP: static website and Godot Web build, requires an HTTP(S) server.
"@
& gh release create $Version $windowsZip $webZip --repo $repository --target main --title "종이전사 $Version · 첫 번째 접힘" --notes $notes --prerelease
if ($LASTEXITCODE -ne 0) { throw 'Website pushed, but release asset upload failed.' }
Write-Output "Published $Version to $repository. Check its Pages workflow before sharing the public URL."
