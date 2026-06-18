# Pester 5 тесты целостности install.ps1: ставит securetrash.ps1 только при
# совпадении SHA256 и fail-closed отказывается при подмене/отсутствии суммы.

BeforeAll {
    $script:Installer = Join-Path $PSScriptRoot '..\install.ps1'
}

Describe 'install.ps1 integrity' {

    BeforeEach {
        $script:Work = Join-Path ([System.IO.Path]::GetTempPath()) ("st_inst_" + [Guid]::NewGuid().ToString('N'))
        $script:Release = Join-Path $script:Work 'release'
        $script:Dest    = Join-Path $script:Work 'install'
        New-Item -ItemType Directory -Path $script:Release -Force | Out-Null
        # Полезная нагрузка-заглушка + корректный SHA256SUMS.
        $payload = "Write-Host 'payload-ok'`n"
        $scriptFile = Join-Path $script:Release 'securetrash.ps1'
        Set-Content -Path $scriptFile -Value $payload -NoNewline
        $hash = (Get-FileHash -Path $scriptFile -Algorithm SHA256).Hash.ToLower()
        Set-Content -Path (Join-Path $script:Release 'SHA256SUMS') -Value "$hash  securetrash.ps1"
    }

    AfterEach {
        Remove-Item -Path $script:Work -Recurse -Force -ErrorAction SilentlyContinue
    }

    It 'installs the script when checksum matches' {
        $env:ST_BASE_URL = $script:Release
        $env:ST_INSTALL_DIR = $script:Dest
        $env:ST_SKIP_PATH = '1'
        & pwsh -NoProfile -File $script:Installer 2>&1 | Out-Null
        $LASTEXITCODE | Should -Be 0
        Test-Path (Join-Path $script:Dest 'securetrash.ps1') | Should -BeTrue
        Remove-Item Env:\ST_BASE_URL, Env:\ST_INSTALL_DIR, Env:\ST_SKIP_PATH -ErrorAction SilentlyContinue
    }

    It 'fails closed on checksum mismatch' {
        # Подменяем нагрузку ПОСЛЕ генерации SHA256SUMS — хеш не сходится.
        Set-Content -Path (Join-Path $script:Release 'securetrash.ps1') -Value "Write-Host 'TAMPERED'`n" -NoNewline
        $env:ST_BASE_URL = $script:Release
        $env:ST_INSTALL_DIR = $script:Dest
        $env:ST_SKIP_PATH = '1'
        & pwsh -NoProfile -File $script:Installer 2>&1 | Out-Null
        $LASTEXITCODE | Should -Not -Be 0
        Test-Path (Join-Path $script:Dest 'securetrash.ps1') | Should -BeFalse
        Remove-Item Env:\ST_BASE_URL, Env:\ST_INSTALL_DIR, Env:\ST_SKIP_PATH -ErrorAction SilentlyContinue
    }

    It 'fails closed when SHA256SUMS lacks the entry' {
        Set-Content -Path (Join-Path $script:Release 'SHA256SUMS') -Value "deadbeef  something-else"
        $env:ST_BASE_URL = $script:Release
        $env:ST_INSTALL_DIR = $script:Dest
        $env:ST_SKIP_PATH = '1'
        & pwsh -NoProfile -File $script:Installer 2>&1 | Out-Null
        $LASTEXITCODE | Should -Not -Be 0
        Test-Path (Join-Path $script:Dest 'securetrash.ps1') | Should -BeFalse
        Remove-Item Env:\ST_BASE_URL, Env:\ST_INSTALL_DIR, Env:\ST_SKIP_PATH -ErrorAction SilentlyContinue
    }
}
