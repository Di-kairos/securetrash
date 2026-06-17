# install.ps1 — установщик securetrash для Windows (BETA).
# Использование (одной строкой):
#   irm https://raw.githubusercontent.com/Di-kairos/securetrash/main/windows/install.ps1 | iex
#
# ВНИМАНИЕ: это BETA-порт. Логика проверена через Pester, но поведение
# BitLocker/VHDX/VeraCrypt на реальном железе НЕ валидировано. Используйте осознанно.

$ErrorActionPreference = 'Stop'

$Repo      = 'Di-kairos/securetrash'
$Branch    = 'main'
$ScriptUrl = "https://raw.githubusercontent.com/$Repo/$Branch/windows/securetrash.ps1"

# Каталог установки в пользовательском профиле (без прав админа).
$InstallDir = Join-Path $env:LOCALAPPDATA 'Programs\securetrash'
$ScriptPath = Join-Path $InstallDir 'securetrash.ps1'
$ShimPath   = Join-Path $InstallDir 'securetrash.cmd'

Write-Host 'SecureTrash (Windows, BETA) installer'
Write-Host '------------------------------------'

# 1) Каталог.
if (-not (Test-Path $InstallDir)) {
    New-Item -ItemType Directory -Path $InstallDir -Force | Out-Null
}

# 2) Скачать основной скрипт.
Write-Host "Downloading securetrash.ps1 from $ScriptUrl ..."
Invoke-RestMethod -Uri $ScriptUrl -OutFile $ScriptPath
Write-Host "Saved: $ScriptPath"

# 3) .cmd-шим, чтобы вызывать просто `securetrash <command>` из cmd/PowerShell.
$shim = @"
@echo off
pwsh -NoProfile -File "%~dp0securetrash.ps1" %*
if errorlevel 1 exit /b %errorlevel%
"@
Set-Content -Path $ShimPath -Value $shim -Encoding ASCII
Write-Host "Shim created: $ShimPath"

# 4) Добавить каталог в пользовательский PATH (idempotent).
$userPath = [Environment]::GetEnvironmentVariable('Path', 'User')
if (-not $userPath) { $userPath = '' }
$paths = $userPath.Split(';') | Where-Object { $_ -ne '' }
if ($paths -notcontains $InstallDir) {
    $newPath = (($paths + $InstallDir) -join ';')
    [Environment]::SetEnvironmentVariable('Path', $newPath, 'User')
    Write-Host "Added to user PATH: $InstallDir"
} else {
    Write-Host 'Already on user PATH.'
}

Write-Host ''
Write-Host 'Done. NEXT STEPS:'
Write-Host '  1) Open a NEW terminal (so PATH refreshes).'
Write-Host '  2) Run:  securetrash check'
Write-Host '  3) Then: securetrash setup'
Write-Host ''
Write-Host 'NOTE: BETA port. Verify behavior on a test container before trusting it with real secrets.'
