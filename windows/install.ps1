# install.ps1 — установщик securetrash для Windows (BETA) с проверкой целостности.
#
# Тянет securetrash.ps1 и SHA256SUMS из РЕЛИЗНОГО тега (не из ветки main) и
# сверяет SHA256 ДО установки. Закрывает supply-chain риск «irm|iex из main без
# проверки»: содержимое релизного тега неизменно (в отличие от подвижной main),
# хеш ловит повреждение, частичную/кэш-подмену и рассинхрон с публикацией.
# ЧЕСТНО: сумма и скрипт приходят по одному каналу — от подмены САМОГО релиза
# (переписаны оба) это не защищает; для подлинности нужна подпись (F-4) / Homebrew.
#
# Использование (рекомендуется verify-then-run, см. windows/README.md):
#   irm https://github.com/Di-kairos/securetrash/releases/latest/download/install.ps1 -OutFile install.ps1
#   irm https://github.com/Di-kairos/securetrash/releases/latest/download/SHA256SUMS  -OutFile SHA256SUMS
#   # сверить хеш install.ps1 вручную, прочитать скрипт, затем:
#   pwsh -File install.ps1
#
# Переменные окружения:
#   ST_VERSION      — конкретный тег (напр. 0.4.0). По умолчанию latest.
#   ST_BASE_URL     — источник целиком: http(s) URL ИЛИ локальный каталог (тесты/форки).
#   ST_INSTALL_DIR  — каталог установки. По умолчанию %LOCALAPPDATA%\Programs\securetrash.
#   ST_SKIP_PATH    — '1' пропускает правку PATH (для тестов).
#
# ВНИМАНИЕ: BETA-порт. Логика проверена через Pester, поведение
# BitLocker/VHDX/VeraCrypt на реальном железе НЕ валидировано.

$ErrorActionPreference = 'Stop'

$Repo = 'Di-kairos/securetrash'

# Источник: явный ST_BASE_URL → конкретный тег ST_VERSION → latest-релиз.
if ($env:ST_BASE_URL) {
    $BaseUrl = $env:ST_BASE_URL
} elseif ($env:ST_VERSION) {
    $BaseUrl = "https://github.com/$Repo/releases/download/v$($env:ST_VERSION)"
} else {
    $BaseUrl = "https://github.com/$Repo/releases/latest/download"
}

$InstallDir = if ($env:ST_INSTALL_DIR) { $env:ST_INSTALL_DIR } else {
    Join-Path $env:LOCALAPPDATA 'Programs\securetrash'
}
$ScriptPath = Join-Path $InstallDir 'securetrash.ps1'
$ShimPath   = Join-Path $InstallDir 'securetrash.cmd'

Write-Host 'SecureTrash (Windows, BETA) installer'
Write-Host '------------------------------------'

# Скачать файл из релиза: http(s) → Invoke-RestMethod; локальный каталог → копия.
# Локальный путь поддержан, чтобы тесты гоняли проверку хеша без сети.
function Get-ReleaseFile {
    param([string]$Name, [string]$OutFile)
    if ($BaseUrl -match '^https?://') {
        Invoke-RestMethod -Uri "$BaseUrl/$Name" -OutFile $OutFile
    } else {
        Copy-Item -Path (Join-Path $BaseUrl $Name) -Destination $OutFile -Force
    }
}

# Временный каталог под загрузку; чистим в любом случае.
$Tmp = Join-Path ([System.IO.Path]::GetTempPath()) ("securetrash-" + [System.Guid]::NewGuid().ToString('N'))
New-Item -ItemType Directory -Path $Tmp -Force | Out-Null
try {
    $tmpScript = Join-Path $Tmp 'securetrash.ps1'
    $tmpSums   = Join-Path $Tmp 'SHA256SUMS'

    Write-Host "Downloading securetrash.ps1 + SHA256SUMS from release..."
    Get-ReleaseFile -Name 'securetrash.ps1' -OutFile $tmpScript
    Get-ReleaseFile -Name 'SHA256SUMS'      -OutFile $tmpSums

    # Ожидаемый хеш для securetrash.ps1 из SHA256SUMS (формат: '<hash>  имя').
    $expected = $null
    foreach ($line in Get-Content -Path $tmpSums) {
        $parts = $line -split '\s+', 2
        if ($parts.Count -eq 2) {
            $fname = $parts[1].Trim().TrimStart('*')
            if ($fname -eq 'securetrash.ps1') { $expected = $parts[0].Trim().ToLower() }
        }
    }
    if (-not $expected) {
        Write-Error 'SHA256SUMS не содержит записи для securetrash.ps1 — установка прервана.'
        exit 1
    }

    $actual = (Get-FileHash -Path $tmpScript -Algorithm SHA256).Hash.ToLower()
    if ($actual -ne $expected) {
        Write-Error "Контрольная сумма НЕ совпала (возможна подмена) — установка прервана.`nexpected: $expected`nactual:   $actual"
        exit 1
    }
    Write-Host 'Checksum OK.'

    # Хеш верный → устанавливаем.
    if (-not (Test-Path $InstallDir)) {
        New-Item -ItemType Directory -Path $InstallDir -Force | Out-Null
    }
    Copy-Item -Path $tmpScript -Destination $ScriptPath -Force
    Write-Host "Installed: $ScriptPath"
}
finally {
    Remove-Item -Path $Tmp -Recurse -Force -ErrorAction SilentlyContinue
}

# .cmd-шим, чтобы вызывать просто `securetrash <command>` из cmd/PowerShell.
$shim = @"
@echo off
pwsh -NoProfile -File "%~dp0securetrash.ps1" %*
if errorlevel 1 exit /b %errorlevel%
"@
Set-Content -Path $ShimPath -Value $shim -Encoding ASCII
Write-Host "Shim created: $ShimPath"

# Добавить каталог в пользовательский PATH (idempotent). ST_SKIP_PATH=1 — пропустить.
if ($env:ST_SKIP_PATH -ne '1') {
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
}

Write-Host ''
Write-Host 'Done. NEXT STEPS:'
Write-Host '  1) Open a NEW terminal (so PATH refreshes).'
Write-Host '  2) Run:  securetrash check'
Write-Host '  3) Then: securetrash setup'
Write-Host ''
Write-Host 'NOTE: BETA port. Verify behavior on a test container before trusting it with real secrets.'
