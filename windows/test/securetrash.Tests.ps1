# Pester 5 тесты для securetrash.ps1 (Windows-порт, BETA).
# Все Windows-specific cmdlet/exe замоканы — проверяется только диспетчер,
# i18n и ветвление. Реальное поведение BitLocker/VHDX/VeraCrypt НЕ верифицируется.

BeforeAll {
    $env:ST_NO_MAIN = '1'   # отключить диспетчер при dot-source
    $script:ScriptPath = Join-Path $PSScriptRoot '..\securetrash.ps1'
    . $script:ScriptPath
}

AfterAll {
    Remove-Item Env:\ST_NO_MAIN -ErrorAction SilentlyContinue
}

Describe 'dispatcher' {

    BeforeEach {
        $env:ST_ASSUME_YES = '1'
        Remove-Item Env:\ST_LANG -ErrorAction SilentlyContinue
        $script:ST_LOCALE = 'en'
    }

    It 'no-arg shows usage and exits non-zero' {
        # Invoke-Main с пустыми аргументами должен показать usage и завершиться кодом 1.
        $code = & pwsh -NoProfile -Command "`$env:ST_NO_MAIN='1'; . '$script:ScriptPath'; Invoke-Main -Argv @()"
        $LASTEXITCODE | Should -Be 1
        ($code -join "`n") | Should -Match 'Usage:'
    }

    It 'unknown command exits non-zero with message' {
        $out = & pwsh -NoProfile -Command "`$env:ST_NO_MAIN='1'; . '$script:ScriptPath'; Invoke-Main -Argv @('bogus')"
        $LASTEXITCODE | Should -Be 1
        ($out -join "`n") | Should -Match 'Unknown command'
    }

    It 'version prints beta label' {
        $out = Invoke-StVersion 6>&1
        ($out -join "`n") | Should -Match 'Windows, beta'
        ($out -join "`n") | Should -Match '0\.2\.0'
    }
}

Describe 'check' {

    BeforeEach {
        Remove-Item Env:\ST_LANG -ErrorAction SilentlyContinue
        $script:ST_LOCALE = 'en'
    }

    It 'SSD + BitLocker ON -> honest SSD line + native vault availability (EN)' {
        Mock Get-StIsSsd { $true }
        Mock Get-StBitLockerOn { $true }
        Mock Get-StBitLockerCapable { $true }
        Mock Get-StVeraCryptPath { $null }

        $out = (Invoke-StCheck 6>&1) -join "`n"
        $out | Should -Match 'BitLocker: ON'
        $out | Should -Match 'NO guarantees'
        $out | Should -Match 'native BitLocker VHDX available'
    }

    It 'BitLocker OFF -> loud English warning' {
        Mock Get-StIsSsd { $true }
        Mock Get-StBitLockerOn { $false }
        Mock Get-StBitLockerCapable { $true }
        Mock Get-StVeraCryptPath { $null }

        $out = (Invoke-StCheck 6>&1) -join "`n"
        $out | Should -Match 'BitLocker is OFF'
        $out | Should -Match 'main protection is missing'
    }

    It 'i18n: ST_LANG=ru -> Russian substring' {
        $env:ST_LANG = 'ru'
        $script:ST_LOCALE = Get-StLocale
        Mock Get-StIsSsd { $true }
        Mock Get-StBitLockerOn { $true }
        Mock Get-StBitLockerCapable { $true }
        Mock Get-StVeraCryptPath { $null }

        $out = (Invoke-StCheck 6>&1) -join "`n"
        $out | Should -Match 'ВКЛЮЧЕН'
        Remove-Item Env:\ST_LANG -ErrorAction SilentlyContinue
        $script:ST_LOCALE = 'en'
    }
}

Describe 'vault create branching' {

    BeforeEach {
        $env:ST_ASSUME_YES = '1'
        $env:ST_VAULT_PASS = 'testpass123'
        $script:ST_LOCALE = 'en'
        Mock Test-Path { $false } -ParameterFilter { $Path -like '*SecureVault.vhdx' }
    }

    AfterEach {
        Remove-Item Env:\ST_VAULT_PASS -ErrorAction SilentlyContinue
    }

    It 'BitLocker capable -> native VHDX path invoked' {
        Mock Get-StBitLockerCapable { $true }
        Mock Get-StVeraCryptPath { $null }
        Mock New-StBitLockerVault { }
        Mock New-StVeraCryptVault { }

        Invoke-StVault -VaultArgs @('create') 6>&1 | Out-Null
        Should -Invoke New-StBitLockerVault -Times 1 -Exactly
        Should -Invoke New-StVeraCryptVault -Times 0 -Exactly
    }

    It 'no BitLocker + VeraCrypt -> VeraCrypt path invoked' {
        Mock Get-StBitLockerCapable { $false }
        Mock Get-StVeraCryptPath { 'C:\Program Files\VeraCrypt\VeraCrypt.exe' }
        Mock New-StBitLockerVault { }
        Mock New-StVeraCryptVault { }

        Invoke-StVault -VaultArgs @('create') 6>&1 | Out-Null
        Should -Invoke New-StVeraCryptVault -Times 1 -Exactly
        Should -Invoke New-StBitLockerVault -Times 0 -Exactly
    }

    It 'neither -> honest failure (StExit thrown, message shown)' {
        Mock Get-StBitLockerCapable { $false }
        Mock Get-StVeraCryptPath { $null }
        Mock New-StBitLockerVault { }
        Mock New-StVeraCryptVault { }

        # Честный отказ = StExit + НИ одной попытки шифрования (нет fake-encryption).
        { Invoke-StVault -VaultArgs @('create') 6>$null } | Should -Throw
        Should -Invoke New-StBitLockerVault -Times 0 -Exactly
        Should -Invoke New-StVeraCryptVault -Times 0 -Exactly
    }

    It 'neither -> non-zero exit + honest message through dispatcher (subprocess)' {
        $out = & pwsh -NoProfile -Command @"
`$env:ST_NO_MAIN='1'; `$env:ST_LANG='en'; `$env:ST_VAULT_PASS='x'; . '$script:ScriptPath'
function Get-StBitLockerCapable { `$false }
function Get-StVeraCryptPath { `$null }
function Get-StVaultPath { '/tmp/st_nonexistent_vault.vhdx' }
Invoke-Main -Argv @('vault','create')
"@ 2>&1
        $LASTEXITCODE | Should -Be 1
        ($out -join "`n") | Should -Match 'unavailable'
    }
}

Describe 'vault destroy' {

    It 'honors ST_ASSUME_YES and calls remove-container mock' {
        $env:ST_ASSUME_YES = '1'
        $script:ST_LOCALE = 'en'
        Mock Test-Path { $true } -ParameterFilter { $Path -like '*SecureVault.vhdx' }
        Mock Dismount-StVault { }
        Mock Remove-StVaultContainer { }

        Invoke-StVault -VaultArgs @('destroy') 6>&1 | Out-Null
        Should -Invoke Remove-StVaultContainer -Times 1 -Exactly
    }
}

Describe 'setup' {

    It 'creates the trash dir and is idempotent' {
        $tmp = Join-Path ([System.IO.Path]::GetTempPath()) ("st_test_" + [Guid]::NewGuid().ToString('N'))
        $oldProfile = $env:USERPROFILE
        $env:USERPROFILE = $tmp
        New-Item -ItemType Directory -Path $tmp -Force | Out-Null
        try {
            Mock Get-StBitLockerOn { $true }
            $script:ST_LOCALE = 'en'

            Invoke-StSetup 6>&1 | Out-Null
            $trash = Join-Path $tmp 'SecureTrash'
            Test-Path $trash | Should -BeTrue

            # второй вызов не падает (идемпотентность)
            { Invoke-StSetup 6>&1 | Out-Null } | Should -Not -Throw
            Test-Path $trash | Should -BeTrue
        } finally {
            $env:USERPROFILE = $oldProfile
            Remove-Item -Path $tmp -Recurse -Force -ErrorAction SilentlyContinue
        }
    }
}
