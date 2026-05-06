# build.ps1 - Zeiterfassung Build Script
#
# Baut APK und/oder Windows-EXE (ZIP) und kopiert sie nach builds\
#
# Usage (von beliebigem Verzeichnis):
#   C:\Users\wolfg\zeiterfassung\build.ps1
#   .\build.ps1                 - APK + Windows (wenn Platform vorhanden)
#   .\build.ps1 -Clean          - flutter clean vor dem Build
#   .\build.ps1 -ApkOnly        - nur APK
#   .\build.ps1 -WindowsOnly    - nur Windows
#   .\build.ps1 -NoPull         - git pull ueberspringen
#
# Ausgabe: zeiterfassung\builds\zeiterfassung-YYYY-MM-DD.apk
#          zeiterfassung\builds\zeiterfassung-YYYY-MM-DD-windows.zip

param(
    [switch]$Clean,
    [switch]$ApkOnly,
    [switch]$WindowsOnly,
    [switch]$NoPull
)

$ErrorActionPreference = "Stop"
$projectRoot = $PSScriptRoot
$appDir      = Join-Path $projectRoot "app"
$buildsDir   = Join-Path $projectRoot "builds"
$date        = Get-Date -Format "yyyy-MM-dd"

$buildApk     = -not $WindowsOnly
$buildWindows = -not $ApkOnly

function Write-Step($msg) { Write-Host ">> $msg" -ForegroundColor Cyan }
function Write-Ok($msg)   { Write-Host "OK $msg" -ForegroundColor Green }
function Write-Warn($msg) { Write-Host "!! $msg" -ForegroundColor Yellow }
function Write-Fail($msg) { Write-Host "XX $msg" -ForegroundColor Red }

# -- Vorbereitung --------------------------------------------------------------
if (-not (Test-Path $buildsDir)) {
    New-Item -ItemType Directory -Path $buildsDir | Out-Null
}

# Immer im Projekt-Root arbeiten - egal von wo das Script gestartet wurde.
Set-Location $projectRoot
Write-Step "Projekt-Root: $projectRoot"

# -- Git Pull ------------------------------------------------------------------
if (-not $NoPull) {
    if (Test-Path (Join-Path $projectRoot ".git")) {
        Write-Step "git pull"
        try {
            $branch = (git rev-parse --abbrev-ref HEAD).Trim()
            git pull origin $branch
            if ($LASTEXITCODE -ne 0) {
                Write-Warn "git pull fehlgeschlagen - baue trotzdem mit lokalem Stand"
            }
        } catch {
            Write-Warn "git pull konnte nicht ausgefuehrt werden: $_"
        }
    } else {
        Write-Warn "Kein git-Repository - pull uebersprungen"
    }
}

Set-Location $appDir

if ($Clean) {
    Write-Step "flutter clean"
    flutter clean
}

Write-Step "flutter pub get"
flutter pub get

# -- APK -----------------------------------------------------------------------
if ($buildApk) {
    Write-Step "flutter build apk --release"
    flutter build apk --release

    $apkSrc = Join-Path $appDir "build\app\outputs\flutter-apk\app-release.apk"
    if (Test-Path $apkSrc) {
        $apkDst = Join-Path $buildsDir "zeiterfassung-$date.apk"
        Copy-Item $apkSrc $apkDst -Force
        $size = [math]::Round((Get-Item $apkDst).Length / 1MB, 1)
        Write-Ok "APK -> builds\zeiterfassung-$date.apk  ($size MB)"
    } else {
        Write-Fail "APK nicht gefunden: $apkSrc"
    }
}

# -- Windows EXE ---------------------------------------------------------------
if ($buildWindows) {
    $winPlatformDir = Join-Path $appDir "windows"
    if (-not (Test-Path $winPlatformDir)) {
        Write-Warn "Windows-Platform fehlt - zuerst ausfuehren:"
        Write-Warn "  cd app; flutter create --platforms=windows ."
    } else {
        Write-Step "flutter build windows --release"
        flutter build windows --release

        $releaseSrc = Join-Path $appDir "build\windows\x64\runner\Release"
        if (Test-Path $releaseSrc) {
            $zipDst = Join-Path $buildsDir "zeiterfassung-$date-windows.zip"
            if (Test-Path $zipDst) { Remove-Item $zipDst -Force }
            Compress-Archive -Path "$releaseSrc\*" -DestinationPath $zipDst
            $size = [math]::Round((Get-Item $zipDst).Length / 1MB, 1)
            Write-Ok "EXE -> builds\zeiterfassung-$date-windows.zip  ($size MB)"
        } else {
            Write-Fail "Release-Ordner nicht gefunden: $releaseSrc"
        }
    }
}

# -- Fertig --------------------------------------------------------------------
Write-Host ""
Write-Ok "Fertig. Ausgabe: $buildsDir"
Set-Location $projectRoot
