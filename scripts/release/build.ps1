param(
    [string]$Version = 'v0.1.0',
    [string]$Godot = $(if ($env:GODOT_BIN) { $env:GODOT_BIN } else { 'godot' })
)

$ErrorActionPreference = 'Stop'
if ($Version -notmatch '^v\d+\.\d+\.\d+(?:-[0-9A-Za-z.-]+)?$') {
    throw 'Version must use a release tag such as v0.1.0 or v0.1.0-preview.1.'
}
$root = Split-Path (Split-Path $PSScriptRoot -Parent) -Parent
$sourceCommit = & git -C $root rev-parse --verify HEAD
if ($LASTEXITCODE -ne 0) { throw 'Commit the source before building a release.' }
$changes = & git -C $root status --porcelain
if ($LASTEXITCODE -ne 0 -or $changes) { throw 'Release builds require a clean source worktree.' }
& node (Join-Path $root 'scripts\web\build.mjs') $Godot
if ($LASTEXITCODE -ne 0) { throw 'Web build failed.' }

$windows = Join-Path $root 'build\windows'
$releases = Join-Path $root 'build\releases'
New-Item -ItemType Directory -Force $windows, $releases | Out-Null
& $Godot --headless --path $root --export-release 'Windows Desktop' (Join-Path $windows 'PaperWarrior.exe')
if ($LASTEXITCODE -ne 0) { throw 'Windows export failed.' }
& $Godot --headless --path $root --main-pack (Join-Path $windows 'PaperWarrior.exe') --script (Join-Path $root 'tests\export\StartupLayoutCheck.gd')
if ($LASTEXITCODE -ne 0) { throw 'Windows exported startup layout is invalid.' }
Copy-Item -LiteralPath (Join-Path $root 'assets\fonts\LICENSE-Galmuri.txt') -Destination $windows
Copy-Item -LiteralPath (Join-Path $root 'assets\fonts\LICENSE-Pretendard.txt') -Destination $windows
$archive = Join-Path $releases "paper-warrior-windows-x86_64-$Version.zip"
Compress-Archive -LiteralPath (Join-Path $windows 'PaperWarrior.exe'), (Join-Path $windows 'LICENSE-Galmuri.txt'), (Join-Path $windows 'LICENSE-Pretendard.txt') -DestinationPath $archive -Force
$webArchive = Join-Path $releases "paper-warrior-web-$Version.zip"
Compress-Archive -Path (Join-Path $root 'build\web\*') -DestinationPath $webArchive -Force
@{
    version = $Version
    source_commit = $sourceCommit
    windows_sha256 = (Get-FileHash -LiteralPath $archive -Algorithm SHA256).Hash
    web_sha256 = (Get-FileHash -LiteralPath $webArchive -Algorithm SHA256).Hash
} | ConvertTo-Json | Set-Content -LiteralPath (Join-Path $releases 'manifest.json') -Encoding utf8
Write-Output "Web: $(Join-Path $root 'build\web')"
Write-Output "Windows portable ZIP: $archive"
Write-Output "Web ZIP: $webArchive"
