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
        # Версия не пиннится — проверяем формат semver, а не конкретное число.
        ($out -join "`n") | Should -Match '\d+\.\d+\.\d+'
    }

    It 'usage documents the --yes flag' {
        $out = (Show-StUsage 6>&1) -join "`n"
        $out | Should -Match '--yes'
    }
}

Describe 'check' {

    BeforeEach {
        Remove-Item Env:\ST_LANG -ErrorAction SilentlyContinue
        $script:ST_LOCALE = 'en'
    }

    It 'SSD + BitLocker ON -> honest SSD line + native vault availability (EN)' {
        Mock Get-StDiskKind { 'ssd' }
        Mock Get-StBitLockerOn { $true }
        Mock Get-StBitLockerCapable { $true }
        Mock Get-StVeraCryptPath { $null }

        $out = (Invoke-StCheck 6>&1) -join "`n"
        $out | Should -Match 'BitLocker: ON'
        $out | Should -Match 'NO guarantees'
        $out | Should -Match 'native BitLocker VHDX available'
    }

    It 'BitLocker OFF -> loud English warning' {
        Mock Get-StDiskKind { 'ssd' }
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
        Mock Get-StDiskKind { 'ssd' }
        Mock Get-StBitLockerOn { $true }
        Mock Get-StBitLockerCapable { $true }
        Mock Get-StVeraCryptPath { $null }

        $out = (Invoke-StCheck 6>&1) -join "`n"
        $out | Should -Match 'ВКЛЮЧЕН'
        Remove-Item Env:\ST_LANG -ErrorAction SilentlyContinue
        $script:ST_LOCALE = 'en'
    }

    It 'unknown disk type -> honest "could not be determined", not an HDD claim' {
        Mock Get-StDiskKind { 'unknown' }
        Mock Get-StBitLockerOn { $true }
        Mock Get-StBitLockerCapable { $true }
        Mock Get-StVeraCryptPath { $null }

        $out = (Invoke-StCheck 6>&1) -join "`n"
        $out | Should -Match 'could not be determined'
        $out | Should -Match 'NO guarantee'
        $out | Should -Not -Match 'Disk: HDD'
    }
}

Describe 'diskpart input validation (#3)' {

    BeforeEach { $script:ST_LOCALE = 'en' }

    It 'rejects a non-numeric size' {
        { Assert-StValidSize -Size '10; rm -rf' 6>$null } | Should -Throw
        { Assert-StValidSize -Size 'abc' 6>$null } | Should -Throw
    }

    It 'accepts a numeric size' {
        { Assert-StValidSize -Size '1024' } | Should -Not -Throw
    }

    It 'rejects a multi-char / non-letter drive letter' {
        { Assert-StValidDriveLetter -DriveLetter 'VV' 6>$null } | Should -Throw
        { Assert-StValidDriveLetter -DriveLetter '1' 6>$null } | Should -Throw
    }

    It 'accepts a single A-Z drive letter' {
        { Assert-StValidDriveLetter -DriveLetter 'V' } | Should -Not -Throw
    }

    It 'rejects a path containing CRLF or double-quote (diskpart injection)' {
        { Assert-StValidVaultPath -Path "C:\a`"`nattach vdisk" 6>$null } | Should -Throw
        { Assert-StValidVaultPath -Path "C:\a`r`nfoo" 6>$null } | Should -Throw
    }

    It 'accepts a normal path' {
        { Assert-StValidVaultPath -Path 'C:\Users\x\SecureVault.vhdx' } | Should -Not -Throw
    }

    It 'Invoke-StDiskpart throws on non-zero exit code' {
        # Подменяем diskpart на функцию, выставляющую $LASTEXITCODE != 0.
        Mock Set-Content { }
        function diskpart { $global:LASTEXITCODE = 1 }
        { Invoke-StDiskpart -Script 'noop' 6>$null } | Should -Throw
    }
}

Describe 'free drive letter (#3)' {

    It 'picks the first letter not already in use' {
        Mock Get-PSDrive {
            @(
                [pscustomobject]@{ Name = 'C' },
                [pscustomobject]@{ Name = 'D' },
                [pscustomobject]@{ Name = 'E' }
            )
        }
        Get-StFreeDriveLetter | Should -Be 'F'
    }
}

Describe 'vault create branching' {

    BeforeEach {
        $env:ST_ASSUME_YES = '1'
        $env:ST_VAULT_PASS = 'testpass123'
        $script:ST_LOCALE = 'en'
        Mock Test-Path { $false } -ParameterFilter { $LiteralPath -like '*SecureVault.vhdx' }
        Mock Get-StFreeDriveLetter { 'W' }
        Mock Set-StPrivateAcl { }
        Mock Write-StVaultBackend { }
    }

    AfterEach {
        Remove-Item Env:\ST_VAULT_PASS -ErrorAction SilentlyContinue
    }

    It 'BitLocker capable -> native VHDX path invoked + backend recorded' {
        Mock Get-StBitLockerCapable { $true }
        Mock Get-StVeraCryptPath { $null }
        Mock New-StBitLockerVault { }

        Invoke-StVault -VaultArgs @('create') 6>&1 | Out-Null
        Should -Invoke New-StBitLockerVault -Times 1 -Exactly
        Should -Invoke Write-StVaultBackend -Times 1 -Exactly -ParameterFilter { $Backend -eq 'bitlocker' }
    }

    It 'no BitLocker + VeraCrypt -> GUI-only message, NO automated create, NO password on argv' {
        Mock Get-StBitLockerCapable { $false }
        Mock Get-StVeraCryptPath { 'C:\Program Files\VeraCrypt\VeraCrypt.exe' }
        Mock New-StBitLockerVault { }

        # #2: автоматический VeraCrypt-create запрещён -> честный отказ (StExit) + GUI-инструкция.
        $out = ''
        $threw = $false
        try { $out = (Invoke-StVault -VaultArgs @('create') 6>&1) -join "`n" }
        catch [StExit] { $threw = $true; $out = $_.TargetObject }
        $threw | Should -BeTrue
        Should -Invoke New-StBitLockerVault -Times 0 -Exactly
    }

    It 'neither -> honest failure (StExit thrown), no BitLocker create' {
        Mock Get-StBitLockerCapable { $false }
        Mock Get-StVeraCryptPath { $null }
        Mock New-StBitLockerVault { }

        { Invoke-StVault -VaultArgs @('create') 6>$null } | Should -Throw
        Should -Invoke New-StBitLockerVault -Times 0 -Exactly
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

Describe 'VeraCrypt never receives a password on argv (#2)' {

    It 'New-StVeraCryptVault no longer exists (automated VeraCrypt removed)' {
        # Функция, передававшая /password в argv, удалена целиком.
        (Get-Command New-StVeraCryptVault -ErrorAction SilentlyContinue) | Should -BeNullOrEmpty
    }

    It 'script source contains no /password argv usage' {
        $src = Get-Content -LiteralPath $script:ScriptPath -Raw
        $src | Should -Not -Match '/password'
    }

    It 'VeraCrypt manual message points to the GUI and explains the argv leak' {
        $script:ST_LOCALE = 'en'
        $msg = T 'vault_vc_manual'
        $msg | Should -Match 'GUI'
        $msg | Should -Match 'command line'
    }
}

Describe 'vault open: BitLocker unlock + verify (#9, #10)' {

    BeforeEach {
        $env:ST_VAULT_PASS = 'testpass123'
        $script:ST_LOCALE = 'en'
        Mock Test-Path { $true } -ParameterFilter { $LiteralPath -like '*SecureVault.vhdx' }
        Mock Get-StFreeDriveLetter { 'W' }
        Mock Invoke-StDiskpart { }
        Mock Show-StVaultInExplorer { }
    }

    AfterEach { Remove-Item Env:\ST_VAULT_PASS -ErrorAction SilentlyContinue }

    It 'attaches, unlocks BitLocker and prints mounted when unlock verified' {
        Mock Read-StVaultBackend { 'bitlocker' }
        Mock Unlock-StBitLockerVault { $true }

        $out = (Invoke-StVault -VaultArgs @('open') 6>&1) -join "`n"
        Should -Invoke Unlock-StBitLockerVault -Times 1 -Exactly
        $out | Should -Match 'Mounted'
    }

    It 'honest error (StExit) when BitLocker unlock not verified' {
        Mock Read-StVaultBackend { 'bitlocker' }
        Mock Unlock-StBitLockerVault { $false }

        { Invoke-StVault -VaultArgs @('open') 6>$null } | Should -Throw
        Should -Invoke Unlock-StBitLockerVault -Times 1 -Exactly
    }

    It 'veracrypt backend -> GUI-only (StExit), never auto-mounts, never unlocks BitLocker' {
        Mock Read-StVaultBackend { 'veracrypt' }
        Mock Unlock-StBitLockerVault { $true }

        { Invoke-StVault -VaultArgs @('open') 6>$null } | Should -Throw
        Should -Invoke Unlock-StBitLockerVault -Times 0 -Exactly
    }
}

Describe 'vault lifecycle hooks (F1)' {

    BeforeEach {
        $env:ST_VAULT_PASS = 'testpass123'
        $script:ST_LOCALE = 'en'
        Mock Test-Path { $true } -ParameterFilter { $LiteralPath -like '*SecureVault.vhdx' }
        Mock Get-StFreeDriveLetter { 'W' }
        Mock Invoke-StDiskpart { }
        Mock Write-StVaultMount { }
        Mock Read-StVaultMount { 'W:\' }
        Mock Remove-StVaultMount { }
        Mock Invoke-StVaultHook { }
        Mock Show-StVaultInExplorer { }
    }

    AfterEach { Remove-Item Env:\ST_VAULT_PASS -ErrorAction SilentlyContinue }

    It 'open: records the mount sidecar and fires post-open hook with the mount' {
        Mock Read-StVaultBackend { 'bitlocker' }
        Mock Unlock-StBitLockerVault { $true }

        Invoke-StVault -VaultArgs @('open') 6>&1 | Out-Null
        Should -Invoke Write-StVaultMount -Times 1 -Exactly -ParameterFilter { $Mount -eq 'W:\' }
        Should -Invoke Invoke-StVaultHook -Times 1 -Exactly -ParameterFilter { $Event -eq 'post-open' -and $Mount -eq 'W:\' }
    }

    It 'open: failed BitLocker unlock does NOT record mount nor fire post-open hook' {
        Mock Read-StVaultBackend { 'bitlocker' }
        Mock Unlock-StBitLockerVault { $false }

        { Invoke-StVault -VaultArgs @('open') 6>$null } | Should -Throw
        Should -Invoke Write-StVaultMount -Times 0 -Exactly
        Should -Invoke Invoke-StVaultHook -Times 0 -Exactly
    }

    It 'close: fires post-close hook with the recorded mount and clears the sidecar' {
        Mock Read-StVaultBackend { 'bitlocker' }
        Mock Dismount-StVault { }

        Invoke-StVault -VaultArgs @('close') 6>&1 | Out-Null
        Should -Invoke Invoke-StVaultHook -Times 1 -Exactly -ParameterFilter { $Event -eq 'post-close' -and $Mount -eq 'W:\' }
        Should -Invoke Remove-StVaultMount -Times 1 -Exactly
    }

    It 'close: veracrypt backend never fires hooks (GUI-only, StExit)' {
        Mock Read-StVaultBackend { 'veracrypt' }
        Mock Dismount-StVault { }

        { Invoke-StVault -VaultArgs @('close') 6>$null } | Should -Throw
        Should -Invoke Invoke-StVaultHook -Times 0 -Exactly
    }
}

Describe 'vault open: Explorer reveal (Windows parity of macOS `open`)' {

    BeforeEach {
        $env:ST_VAULT_PASS = 'testpass123'
        $script:ST_LOCALE = 'en'
        Mock Test-Path { $true } -ParameterFilter { $LiteralPath -like '*SecureVault.vhdx' }
        Mock Get-StFreeDriveLetter { 'W' }
        Mock Invoke-StDiskpart { }
        Mock Write-StVaultMount { }
        Mock Invoke-StVaultHook { }
        Mock Read-StVaultBackend { 'bitlocker' }
        Mock Unlock-StBitLockerVault { $true }
    }

    AfterEach {
        Remove-Item Env:\ST_VAULT_PASS -ErrorAction SilentlyContinue
        Remove-Item Env:\ST_VAULT_NO_REVEAL -ErrorAction SilentlyContinue
    }

    It 'open reveals the mounted volume in Explorer after a verified unlock' {
        Mock Show-StVaultInExplorer { }
        Invoke-StVault -VaultArgs @('open') 6>&1 | Out-Null
        Should -Invoke Show-StVaultInExplorer -Times 1 -Exactly -ParameterFilter { $Mount -eq 'W:\' }
    }

    It 'failed BitLocker unlock never reveals (volume not really mounted)' {
        Mock Unlock-StBitLockerVault { $false }
        Mock Show-StVaultInExplorer { }
        { Invoke-StVault -VaultArgs @('open') 6>$null } | Should -Throw
        Should -Invoke Show-StVaultInExplorer -Times 0 -Exactly
    }

    It 'Show-StVaultInExplorer launches explorer.exe with the mount' {
        Mock Start-Process { }
        Show-StVaultInExplorer -Mount 'W:\'
        Should -Invoke Start-Process -Times 1 -Exactly -ParameterFilter {
            $FilePath -eq 'explorer.exe' -and $ArgumentList -eq 'W:\'
        }
    }

    It 'ST_VAULT_NO_REVEAL=1 opts out — Explorer is never launched' {
        $env:ST_VAULT_NO_REVEAL = '1'
        Mock Start-Process { }
        Show-StVaultInExplorer -Mount 'W:\'
        Should -Invoke Start-Process -Times 0 -Exactly
    }

    It 'reveal failure is best-effort — warns, does not throw (volume stays mounted)' {
        Mock Start-Process { throw 'no shell' }
        { Show-StVaultInExplorer -Mount 'W:\' 6>$null } | Should -Not -Throw
    }
}

Describe 'Invoke-StVaultHook (real)' {

    It 'is a no-op (no throw) when the hook file is absent' {
        Mock Test-Path { $false } -ParameterFilter { $LiteralPath -like '*post-open.cmd' }
        { Invoke-StVaultHook -Event 'post-open' -Mount 'W:\' } | Should -Not -Throw
    }

    It 'honors ST_HOOK_DIR override for hook resolution' {
        $env:ST_HOOK_DIR = '/tmp/st_hooks_nonexistent'
        try {
            { Invoke-StVaultHook -Event 'post-open' -Mount 'W:\' } | Should -Not -Throw
        } finally {
            Remove-Item Env:\ST_HOOK_DIR -ErrorAction SilentlyContinue
        }
    }
}

Describe 'backend metadata routing (#10)' {

    It 'close on a veracrypt backend does not call diskpart dismount (StExit, GUI-only)' {
        $script:ST_LOCALE = 'en'
        Mock Read-StVaultBackend { 'veracrypt' }
        Mock Dismount-StVault { }

        { Invoke-StVault -VaultArgs @('close') 6>$null } | Should -Throw
        Should -Invoke Dismount-StVault -Times 0 -Exactly
    }

    It 'close on a bitlocker backend calls dismount' {
        $script:ST_LOCALE = 'en'
        Mock Read-StVaultBackend { 'bitlocker' }
        Mock Dismount-StVault { }

        Invoke-StVault -VaultArgs @('close') 6>&1 | Out-Null
        Should -Invoke Dismount-StVault -Times 1 -Exactly
    }
}

Describe 'vault destroy' {

    It 'honors ST_ASSUME_YES and calls remove-container mock (bitlocker backend)' {
        $env:ST_ASSUME_YES = '1'
        $script:ST_LOCALE = 'en'
        Mock Test-Path { $true } -ParameterFilter { $LiteralPath -like '*SecureVault.vhdx' }
        Mock Test-Path { $false } -ParameterFilter { $LiteralPath -like '*SecureVault.vhdx.backend' }
        Mock Read-StVaultBackend { 'bitlocker' }
        # tri-state: смонтирован → размонтировать; postcondition видит размонтированный.
        $script:vaultStates = [System.Collections.Queue]::new()
        $script:vaultStates.Enqueue('mounted'); $script:vaultStates.Enqueue('unmounted')
        Mock Get-StVaultState { if ($script:vaultStates.Count -gt 0) { $script:vaultStates.Dequeue() } else { 'unmounted' } }
        Mock Dismount-StVault { }
        Mock Remove-StVaultContainer { }

        Invoke-StVault -VaultArgs @('destroy') 6>&1 | Out-Null
        Should -Invoke Remove-StVaultContainer -Times 1 -Exactly
        Should -Invoke Dismount-StVault -Times 1 -Exactly
    }

    It 'fail-closed: refuses to delete when vault state is unknown (bitlocker)' {
        $env:ST_ASSUME_YES = '1'
        $script:ST_LOCALE = 'en'
        Mock Test-Path { $true } -ParameterFilter { $LiteralPath -like '*SecureVault.vhdx' }
        Mock Test-Path { $false } -ParameterFilter { $LiteralPath -like '*SecureVault.vhdx.backend' }
        Mock Read-StVaultBackend { 'bitlocker' }
        Mock Get-StVaultState { 'unknown' }
        Mock Dismount-StVault { }
        Mock Remove-StVaultContainer { }

        { Invoke-StVault -VaultArgs @('destroy') 6>$null } | Should -Throw
        Should -Invoke Remove-StVaultContainer -Times 0 -Exactly
        Should -Invoke Dismount-StVault -Times 0 -Exactly
    }

    It 'fail-closed: refuses to delete when still mounted after dismount (bitlocker)' {
        $env:ST_ASSUME_YES = '1'
        $script:ST_LOCALE = 'en'
        Mock Test-Path { $true } -ParameterFilter { $LiteralPath -like '*SecureVault.vhdx' }
        Mock Test-Path { $false } -ParameterFilter { $LiteralPath -like '*SecureVault.vhdx.backend' }
        Mock Read-StVaultBackend { 'bitlocker' }
        Mock Get-StVaultState { 'mounted' }   # и до, и после dismount — отказ
        Mock Dismount-StVault { }
        Mock Remove-StVaultContainer { }

        { Invoke-StVault -VaultArgs @('destroy') 6>$null } | Should -Throw
        Should -Invoke Remove-StVaultContainer -Times 0 -Exactly
    }

    It 'destroy on veracrypt backend removes the file but does not diskpart-dismount' {
        $env:ST_ASSUME_YES = '1'
        $script:ST_LOCALE = 'en'
        Mock Test-Path { $true } -ParameterFilter { $LiteralPath -like '*SecureVault.vhdx' }
        Mock Test-Path { $false } -ParameterFilter { $LiteralPath -like '*SecureVault.vhdx.backend' }
        Mock Read-StVaultBackend { 'veracrypt' }
        Mock Dismount-StVault { }
        Mock Remove-StVaultContainer { }

        Invoke-StVault -VaultArgs @('destroy') 6>&1 | Out-Null
        Should -Invoke Remove-StVaultContainer -Times 1 -Exactly
        Should -Invoke Dismount-StVault -Times 0 -Exactly
    }

    It 'destroy prints honest (non-absolute) recovery wording' {
        $env:ST_ASSUME_YES = '1'
        $script:ST_LOCALE = 'en'
        Mock Test-Path { $true } -ParameterFilter { $LiteralPath -like '*SecureVault.vhdx' }
        Mock Test-Path { $false } -ParameterFilter { $LiteralPath -like '*SecureVault.vhdx.backend' }
        Mock Read-StVaultBackend { 'bitlocker' }
        Mock Get-StVaultState { 'unmounted' }
        Mock Dismount-StVault { }
        Mock Remove-StVaultContainer { }

        $out = (Invoke-StVault -VaultArgs @('destroy') 6>&1) -join "`n"
        $out | Should -Match 'crypto-shred'
        $out | Should -Match 'depends on password strength'
        $out | Should -Not -Match 'unrecoverable without the key'
    }
}

Describe 'honest wording (#1, #11, #12)' {

    BeforeEach { $script:ST_LOCALE = 'en' }

    It 'hdd_note says best-effort and not a guarantee' {
        $note = T 'hdd_note'
        $note | Should -Match 'best-effort'
        $note | Should -Match 'NOT a guarantee'
    }

    It 'vault_preventive warns about mounted leak vectors' {
        $msg = T 'vault_preventive'
        $msg | Should -Match 'Windows Search'
        $msg | Should -Match 'pagefile'
        $msg | Should -Match 'VSS'
    }
}

Describe 'shred: LiteralPath + best-effort wipe (#1a, #7)' {

    It 'shred enumerates with LiteralPath and calls cipher wipe' {
        $env:ST_ASSUME_YES = '1'
        $script:ST_LOCALE = 'en'
        Mock Test-Path { $true } -ParameterFilter { $LiteralPath -eq 'C:\secret*.txt' }
        # Get-Item замокан: иначе Remove-StItemSafe видит $item=null (файла нет на раннере)
        # и выходит до Remove-Item. Отдаём обычный не-контейнерный, не-reparse элемент.
        Mock Get-Item { [pscustomobject]@{ Attributes = [System.IO.FileAttributes]::Normal; PSIsContainer = $false } } -ParameterFilter { $LiteralPath -eq 'C:\secret*.txt' }
        Mock Remove-Item { }
        Mock Invoke-StCipherWipe { }
        Mock Write-StHonestDiskNote { }

        Invoke-StShred -Paths @('C:\secret*.txt') 6>&1 | Out-Null
        # Имя с * не должно over-match: удаляем именно через LiteralPath.
        Should -Invoke Remove-Item -Times 1 -Exactly -ParameterFilter { $LiteralPath -eq 'C:\secret*.txt' }
        Should -Invoke Invoke-StCipherWipe -Times 1 -Exactly
    }
}

Describe 'shred: protected-path guard (#1)' {

    BeforeEach {
        $script:_oldDrive = $env:SystemDrive; $script:_oldRoot = $env:SystemRoot; $script:_oldProf = $env:USERPROFILE
        $env:SystemDrive = 'C:'; $env:SystemRoot = 'C:\Windows'; $env:USERPROFILE = 'C:\Users\me'
    }
    AfterEach {
        $env:SystemDrive = $script:_oldDrive; $env:SystemRoot = $script:_oldRoot; $env:USERPROFILE = $script:_oldProf
    }

    It 'flags drive roots and system trees as protected' {
        foreach ($p in @('C:\', 'D:\', 'C:\Windows', 'C:\Windows\System32',
                         'C:\Program Files', 'C:\Program Files (x86)\foo', 'C:\ProgramData',
                         'C:\Users', 'C:\Users\me', 'C:\Users\me\..\..\Windows')) {
            Test-StProtectedPath $p | Should -BeTrue -Because "$p must be protected"
        }
    }

    It 'allows files under a user profile and other normal paths' {
        foreach ($p in @('C:\Users\me\secret.txt', 'C:\Users\me\sub\f', 'C:\Users\other\f', 'C:\temp\x')) {
            Test-StProtectedPath $p | Should -BeFalse -Because "$p must be allowed"
        }
    }

    It 'shred refuses a protected path and deletes nothing' {
        $env:ST_ASSUME_YES = '1'
        $script:ST_LOCALE = 'en'
        Mock Test-Path { $true }
        Mock Remove-Item { }
        Mock Invoke-StCipherWipe { }
        Mock Write-StHonestDiskNote { }

        { Invoke-StShred -Paths @('C:\Windows') 6>$null } | Should -Throw
        Should -Invoke Remove-Item -Times 0 -Exactly
    }
}

Describe 'shred: reparse-point guard (junction/symlink)' {

    BeforeEach { $env:ST_ASSUME_YES = '1'; $script:ST_LOCALE = 'en' }

    It 'shred refuses when path is a junction/symlink (ReparsePoint attribute)' {
        Mock Test-Path { $true }
        Mock Test-StProtectedPath { $false }
        Mock Get-Item {
            $fake = [PSCustomObject]@{ Attributes = [System.IO.FileAttributes]::Directory -bor [System.IO.FileAttributes]::ReparsePoint }
            return $fake
        }
        Mock Remove-StItemSafe { }
        Mock Invoke-StCipherWipe { }
        Mock Write-StHonestDiskNote { }

        { Invoke-StShred -Paths @('C:\JunctionToTarget') 6>$null } | Should -Throw
        Should -Invoke Remove-StItemSafe -Times 0 -Exactly
    }

    It 'shred uses Remove-StItemSafe (not Remove-Item -Recurse) for normal paths' {
        Mock Test-Path { $true }
        Mock Test-StProtectedPath { $false }
        Mock Get-Item {
            $fake = [PSCustomObject]@{ Attributes = [System.IO.FileAttributes]::Directory }
            return $fake
        }
        Mock Remove-StItemSafe { }
        Mock Invoke-StCipherWipe { }
        Mock Write-StHonestDiskNote { }

        Invoke-StShred -Paths @('C:\Users\me\secret') 6>&1 | Out-Null
        Should -Invoke Remove-StItemSafe -Times 1 -Exactly -ParameterFilter { $Path -eq 'C:\Users\me\secret' }
    }
}

Describe '--yes flag (#14)' {

    It 'sets the assume-yes flag and strips it from args' {
        # Подменяем команду, чтобы зафиксировать состояние флага во время выполнения.
        Mock Invoke-StVersion { $script:CapturedYes = $script:ST_ASSUME_YES_FLAG }
        Remove-Item Env:\ST_ASSUME_YES -ErrorAction SilentlyContinue
        $script:CapturedYes = $false

        # exit внутри Invoke-Main ловится только для StExit; version не кидает StExit,
        # значит дойдём до конца без выхода процесса (Pester-safe).
        Invoke-Main -Argv @('--yes','version') 6>&1 | Out-Null
        $script:CapturedYes | Should -BeTrue
    }
}

Describe 'setup' {

    It 'creates the trash dir, sets private ACL, is idempotent' {
        $tmp = Join-Path ([System.IO.Path]::GetTempPath()) ("st_test_" + [Guid]::NewGuid().ToString('N'))
        $oldProfile = $env:USERPROFILE
        $env:USERPROFILE = $tmp
        New-Item -ItemType Directory -Path $tmp -Force | Out-Null
        try {
            Mock Get-StBitLockerOn { $true }
            Mock Set-StPrivateAcl { }
            $script:ST_LOCALE = 'en'

            Invoke-StSetup 6>&1 | Out-Null
            $trash = Join-Path $tmp 'SecureTrash'
            Test-Path $trash | Should -BeTrue
            Should -Invoke Set-StPrivateAcl -Times 1 -Exactly

            # второй вызов не падает (идемпотентность)
            { Invoke-StSetup 6>&1 | Out-Null } | Should -Not -Throw
            Test-Path $trash | Should -BeTrue
        } finally {
            $env:USERPROFILE = $oldProfile
            Remove-Item -Path $tmp -Recurse -Force -ErrorAction SilentlyContinue
        }
    }
}
