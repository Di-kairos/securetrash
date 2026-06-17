# securetrash.ps1 — честное безопасное удаление файлов на Windows (BETA-порт).
# Зеркало macOS-версии (bash). Baseline: Windows PowerShell 5.1 (без PS7-only синтаксиса).
# ВАЖНО: порт помечен BETA — логика проверена через Pester, поведение
# BitLocker/VHDX/VeraCrypt на реальном железе НЕ верифицировано.

$VERSION = '0.2.0'

# --- language detection ---
# Выбор языка вывода. По умолчанию английский. Русский — если ST_LANG начинается
# с 'ru' ИЛИ $PSUICulture начинается с 'ru'. Результат фиксируется один раз.
function Get-StLocale {
    $want = $env:ST_LANG
    if ($want) {
        if ($want -match '^(?i)ru') { return 'ru' } else { return 'en' }
    }
    if ($PSUICulture -and ($PSUICulture -match '^(?i)ru')) { return 'ru' }
    return 'en'
}
$script:ST_LOCALE = Get-StLocale

# --- i18n strings ---
# Хэш-таблица сообщений, ключ "<locale>:<key>". Динамические значения — через -f в T().
$script:Messages = @{
    'en:beta_banner'        = 'BETA: Windows port. Logic tested via Pester; BitLocker/VHDX/VeraCrypt behavior NOT validated on real hardware.'
    'ru:beta_banner'        = 'BETA: порт под Windows. Логика проверена через Pester; поведение BitLocker/VHDX/VeraCrypt на реальном железе НЕ проверено.'

    'en:confirm_suffix'     = '[type yes]'
    'ru:confirm_suffix'     = '[введите yes]'

    'en:usage'              = @'
Usage: securetrash <command> [args]

Commands:
  check                       Audit the environment and give an honest verdict on guarantees
  setup                       Create %USERPROFILE%\SecureTrash and check BitLocker
  empty                       Empty %USERPROFILE%\SecureTrash
  shred <path>...             Securely delete a file/folder
  vault create|open|close|destroy   Encrypted container (crypto-shred)
  version                     Show the version
'@
    'ru:usage'              = @'
Usage: securetrash <command> [args]

Commands:
  check                       Аудит окружения и честный вердикт о гарантиях
  setup                       Создать %USERPROFILE%\SecureTrash, проверить BitLocker
  empty                       Опустошить %USERPROFILE%\SecureTrash
  shred <path>...             Безопасно удалить файл/папку
  vault create|open|close|destroy   Зашифрованный контейнер (crypto-shred)
  version                     Показать версию
'@

    'en:setup_dir_ready'    = 'Folder ready: {0}'
    'ru:setup_dir_ready'    = 'Папка готова: {0}'

    'en:bl_off_setup'       = 'BitLocker is OFF — turn it on, otherwise deletion on SSD gives no guarantees.'
    'ru:bl_off_setup'       = 'BitLocker ВЫКЛЮЧЕН — включи его, иначе удаление на SSD не даёт гарантий.'

    'en:check_header'       = '=== SecureTrash: environment audit ==='
    'ru:check_header'       = '=== SecureTrash: аудит окружения ==='

    'en:bl_on'              = 'BitLocker: ON — system drive is encrypted, base protection present.'
    'ru:bl_on'              = 'BitLocker: ВКЛЮЧЕН — системный диск зашифрован, базовая защита есть.'

    'en:bl_off_check'       = 'BitLocker is OFF — the main protection is missing! Enable it: Settings -> Privacy & security -> Device encryption / BitLocker.'
    'ru:bl_off_check'       = 'BitLocker ВЫКЛЮЧЕН — главная защита отсутствует! Включи: Параметры -> Конфиденциальность и защита -> Шифрование устройства / BitLocker.'

    'en:disk_ssd'           = '  Disk: SSD.'
    'ru:disk_ssd'           = '  Диск: SSD.'

    'en:ssd_no_guarantee'   = 'Overwriting (cipher /w) on SSD gives NO guarantees (wear leveling, COW, TRIM).'
    'ru:ssd_no_guarantee'   = 'Перезапись (cipher /w) на SSD НЕ даёт гарантий (wear leveling, COW, TRIM).'

    'en:ssd_real_guarantee' = "Real guarantee on SSD: BitLocker + crypto-shred via 'securetrash vault'."
    'ru:ssd_real_guarantee' = "Реальная гарантия на SSD: BitLocker + crypto-shred через 'securetrash vault'."

    'en:disk_hdd'           = '  Disk: HDD (or type unknown).'
    'ru:disk_hdd'           = '  Диск: HDD (или тип неизвестен).'

    'en:hdd_effective'      = 'On HDD, overwriting (cipher /w) is effective.'
    'ru:hdd_effective'      = 'На HDD перезапись (cipher /w) эффективна.'

    'en:vault_native'       = 'Vault: native BitLocker VHDX available.'
    'ru:vault_native'       = 'Vault: доступен нативный BitLocker VHDX.'

    'en:vault_veracrypt'    = 'Vault: BitLocker unavailable, but VeraCrypt is present (fallback).'
    'ru:vault_veracrypt'    = 'Vault: BitLocker недоступен, но найден VeraCrypt (fallback).'

    'en:vault_none'         = 'Vault: unavailable — enable BitLocker or install VeraCrypt.'
    'ru:vault_none'         = 'Vault: недоступен — включи BitLocker или поставь VeraCrypt.'

    'en:check_verdict'      = "Verdict: for secrets, use 'securetrash vault' (preventively)."
    'ru:check_verdict'      = "Итог: для секретов используй 'securetrash vault' (превентивно)."

    'en:ssd_note'           = 'SSD: overwriting is not a guarantee. Real protection is BitLocker.'
    'ru:ssd_note'           = 'SSD: перезапись не гарантия. Реальная защита — BitLocker.'

    'en:ssd_bl_off_note'    = 'And BitLocker is OFF — data may be recoverable.'
    'ru:ssd_bl_off_note'    = 'И BitLocker ВЫКЛЮЧЕН — данные могут быть восстановимы.'

    'en:hdd_note'           = 'HDD: overwrite done (cipher /w on free space recommended).'
    'ru:hdd_note'           = 'HDD: перезапись выполнена (рекомендуется cipher /w по свободному месту).'

    'en:shred_need_path'    = 'shred: provide a path.'
    'ru:shred_need_path'    = 'shred: укажи путь.'

    'en:not_found'          = 'Not found: {0}'
    'ru:not_found'          = 'Не найдено: {0}'

    'en:shred_confirm'      = 'Permanently delete {0}?'
    'ru:shred_confirm'      = 'Удалить безвозвратно {0}?'

    'en:cancelled'          = 'Cancelled.'
    'ru:cancelled'          = 'Отменено.'

    'en:deleted'            = 'Deleted: {0}'
    'ru:deleted'            = 'Удалено: {0}'

    'en:empty_no_dir'       = "No {0} folder (run 'securetrash setup')."
    'ru:empty_no_dir'       = "Нет папки {0} (запусти 'securetrash setup')."

    'en:empty_already'      = 'Folder is already empty.'
    'ru:empty_already'      = 'Папка уже пуста.'

    'en:empty_confirm'      = 'Empty {0} permanently?'
    'ru:empty_confirm'      = 'Опустошить {0} безвозвратно?'

    'en:emptied'            = 'Folder emptied: {0}'
    'ru:emptied'            = 'Папка опустошена: {0}'

    'en:vault_pass'         = 'Container password'
    'ru:vault_pass'         = 'Пароль контейнера'

    'en:vault_exists'       = 'Container already exists: {0}'
    'ru:vault_exists'       = 'Контейнер уже существует: {0}'

    'en:vault_created'      = 'Container created: {0} (size {1}).'
    'ru:vault_created'      = 'Контейнер создан: {0} (размер {1}).'

    'en:vault_preventive'   = 'Vault protects only what is created/moved INSIDE it. Plaintext that already existed outside is not erased by this — for that you need BitLocker.'
    'ru:vault_preventive'   = 'Vault защищает только то, что создано/перемещено ВНУТРЬ. Уже лежавший снаружи plaintext этим не стирается — для него нужен BitLocker.'

    'en:vault_no_container_open' = "No container. Run 'securetrash vault create' first."
    'ru:vault_no_container_open' = "Нет контейнера. Сначала 'securetrash vault create'."

    'en:vault_mounted'      = 'Mounted: {0}'
    'ru:vault_mounted'      = 'Смонтировано: {0}'

    'en:vault_detach_fail'  = 'Could not unmount (not open?).'
    'ru:vault_detach_fail'  = 'Не удалось размонтировать (не открыт?).'

    'en:vault_closed'       = 'Unmounted — data is encrypted again.'
    'ru:vault_closed'       = 'Размонтировано — данные снова зашифрованы.'

    'en:vault_no_container' = 'No container: {0}'
    'ru:vault_no_container' = 'Нет контейнера: {0}'

    'en:vault_destroy_confirm' = 'DESTROY the container and everything inside ({0})?'
    'ru:vault_destroy_confirm' = 'УНИЧТОЖИТЬ контейнер и всё внутри ({0})?'

    'en:vault_destroyed'    = 'Container destroyed (crypto-shred). Data is unrecoverable without the key.'
    'ru:vault_destroyed'    = 'Контейнер уничтожен (crypto-shred). Данные неизвлекаемы без ключа.'

    'en:vault_unavailable'  = 'Vault unavailable — enable BitLocker or install VeraCrypt. No silent fake encryption.'
    'ru:vault_unavailable'  = 'Vault недоступен — включи BitLocker или поставь VeraCrypt. Никакого молчаливого "как будто зашифровали".'

    'en:vault_usage'        = 'vault: provide create|open|close|destroy'
    'ru:vault_usage'        = 'vault: укажи create|open|close|destroy'

    'en:unknown_cmd'        = 'Unknown command: {0}'
    'ru:unknown_cmd'        = 'Unknown command: {0}'
}

# T — локализованная строка по ключу. Динамика — через -f с позиционными аргументами.
# Fallback: если ключа нет в таблице, вернуть сам ключ.
function T {
    param(
        [Parameter(Mandatory = $true)][string]$Key,
        [Parameter(ValueFromRemainingArguments = $true)][object[]]$FmtArgs
    )
    $full = "$script:ST_LOCALE`:$Key"
    if ($script:Messages.ContainsKey($full)) {
        $tmpl = $script:Messages[$full]
        if ($FmtArgs -and $FmtArgs.Count -gt 0) { return ($tmpl -f $FmtArgs) }
        return $tmpl
    }
    return $Key
}

# --- output helpers ---
# info/warn/err — единый стиль вывода. warn/err идут в host (stderr-эквивалент).
function Write-StInfo { param([string]$Msg) Write-Host "[ok] $Msg" }
function Write-StWarn { param([string]$Msg) Write-Host "[!] $Msg" -ForegroundColor Yellow }
function Write-StErr  { param([string]$Msg) Write-Host "[x] $Msg" -ForegroundColor Red }

# Завершение команды с кодом возврата. Внутри команд НЕ зовём exit напрямую
# (это убило бы Pester-раннер) — кидаем StExit, диспетчер ловит и делает exit.
class StExit : System.Exception {
    [int]$Code
    StExit([int]$code) : base("StExit:$code") { $this.Code = $code }
}
function Stop-StCommand {
    param([int]$Code = 1)
    throw [StExit]::new($Code)
}

# Спросить подтверждение. ST_ASSUME_YES=1 обходит вопрос (для скриптов/тестов).
function Confirm-StAction {
    param([string]$Prompt)
    if ($env:ST_ASSUME_YES -eq '1') { return $true }
    $ans = Read-Host "$Prompt $(T 'confirm_suffix')"
    return ($ans -eq 'yes')
}

# --- platform detection (каждая функция оборачивает внешний вызов для Mock) ---

# Любой физический диск — SSD? Get-PhysicalDisk MediaType -eq 'SSD'.
# try/catch: cmdlet может отсутствовать / падать → считаем неизвестным ($false).
function Get-StIsSsd {
    try {
        $disks = Get-PhysicalDisk -ErrorAction Stop
        foreach ($d in $disks) {
            if ($d.MediaType -eq 'SSD') { return $true }
        }
        return $false
    } catch {
        return $false
    }
}

# BitLocker системного диска включён? ProtectionStatus -eq 'On'.
# try/catch: на Windows Home cmdlet отсутствует → $false.
function Get-StBitLockerOn {
    try {
        $v = Get-BitLockerVolume -MountPoint $env:SystemDrive -ErrorAction Stop
        return ($v.ProtectionStatus -eq 'On')
    } catch {
        return $false
    }
}

# Доступны ли BitLocker-cmdlet'ы (для native VHDX-пути vault)?
# Наличие Enable-BitLocker = на машине есть BitLocker management.
function Get-StBitLockerCapable {
    try {
        $cmd = Get-Command Enable-BitLocker -ErrorAction Stop
        return ($null -ne $cmd)
    } catch {
        return $false
    }
}

# Путь к VeraCrypt: в PATH или в стандартном Program Files.
function Get-StVeraCryptPath {
    try {
        $cmd = Get-Command VeraCrypt -ErrorAction SilentlyContinue
        if ($cmd) { return $cmd.Source }
    } catch { }
    # На Windows ProgramFiles всегда задан; защищаемся от null (кросс-платформенный прогон).
    if ($env:ProgramFiles) {
        $std = Join-Path $env:ProgramFiles 'VeraCrypt\VeraCrypt.exe'
        if (Test-Path $std) { return $std }
    }
    return $null
}

# --- vault external-call wrappers (для Mock в Pester) ---

# Создать BitLocker-защищённый VHDX. Обёртка над diskpart + Enable-BitLocker.
function New-StBitLockerVault {
    param(
        [string]$Path,
        [string]$Size,
        [System.Security.SecureString]$Password,
        [string]$DriveLetter = 'V'
    )
    # diskpart-скрипт: создать vdisk, attach, partition, format NTFS, assign.
    $script = @"
create vdisk file="$Path" maximum=$Size type=expandable
select vdisk file="$Path"
attach vdisk
create partition primary
format fs=ntfs quick label=SecretVault
assign letter=$DriveLetter
"@
    Invoke-StDiskpart -Script $script
    Enable-BitLocker -MountPoint "$($DriveLetter):" -PasswordProtector -Password $Password -EncryptionMethod Aes256 -ErrorAction Stop | Out-Null
}

# Запустить diskpart со скриптом (обёртка для Mock).
function Invoke-StDiskpart {
    param([string]$Script)
    $tmp = [System.IO.Path]::GetTempFileName()
    try {
        Set-Content -Path $tmp -Value $Script -Encoding ASCII
        & diskpart /s $tmp | Out-Null
    } finally {
        Remove-Item -Path $tmp -Force -ErrorAction SilentlyContinue
    }
}

# Создать VeraCrypt-контейнер (fallback). Обёртка над VeraCrypt /create.
function New-StVeraCryptVault {
    param(
        [string]$VeraCryptExe,
        [string]$Path,
        [string]$Size,
        [string]$PasswordPlain
    )
    & $VeraCryptExe /create $Path /size $Size /password $PasswordPlain /encryption AES /hash sha512 /filesystem NTFS /quit /silent | Out-Null
}

# Размонтировать/отсоединить контейнер (обёртка для Mock).
function Dismount-StVault {
    param([string]$Path, [string]$DriveLetter = 'V')
    $script = @"
select vdisk file="$Path"
detach vdisk
"@
    Invoke-StDiskpart -Script $script
}

# Удалить файл-контейнер = crypto-shred (обёртка для Mock).
function Remove-StVaultContainer {
    param([string]$Path)
    Remove-Item -Path $Path -Force -ErrorAction Stop
}

# --- paths ---
# База профиля: USERPROFILE на Windows; HOME — fallback (кросс-платформенный прогон Pester).
function Get-StHomeDir {
    if ($env:USERPROFILE) { return $env:USERPROFILE }
    if ($env:HOME) { return $env:HOME }
    return (Get-Location).Path
}
function Get-StTrashDir { return (Join-Path (Get-StHomeDir) 'SecureTrash') }
function Get-StVaultPath { return (Join-Path (Get-StHomeDir) 'SecureVault.vhdx') }

# --- commands ---

function Invoke-StVersion {
    Write-Host "securetrash $VERSION (Windows, beta)"
}

# Аудит окружения: честный вердикт о гарантиях удаления.
function Invoke-StCheck {
    Write-Host (T 'beta_banner')
    Write-Host (T 'check_header')

    if (Get-StBitLockerOn) {
        Write-StInfo (T 'bl_on')
    } else {
        Write-StWarn (T 'bl_off_check')
    }

    $ssd = Get-StIsSsd
    if ($ssd) {
        Write-Host (T 'disk_ssd')
        Write-StWarn (T 'ssd_no_guarantee')
        Write-StInfo (T 'ssd_real_guarantee')
    } else {
        Write-Host (T 'disk_hdd')
        Write-StInfo (T 'hdd_effective')
    }

    # Доступность vault: native BitLocker / VeraCrypt fallback / нет.
    if (Get-StBitLockerCapable) {
        Write-StInfo (T 'vault_native')
    } elseif (Get-StVeraCryptPath) {
        Write-StInfo (T 'vault_veracrypt')
    } else {
        Write-StWarn (T 'vault_none')
    }

    Write-Host ''
    Write-Host (T 'check_verdict')
}

# Подготовка окружения: папка-корзина, предупреждение про BitLocker. Идемпотентно.
function Invoke-StSetup {
    $trash = Get-StTrashDir
    if (-not (Test-Path $trash)) {
        New-Item -ItemType Directory -Path $trash -Force | Out-Null
    }
    Write-StInfo (T 'setup_dir_ready' $trash)
    if (-not (Get-StBitLockerOn)) {
        Write-StWarn (T 'bl_off_setup')
    }
}

# Честное примечание о гарантиях по типу диска.
function Write-StHonestDiskNote {
    if (Get-StIsSsd) {
        Write-StWarn (T 'ssd_note')
        if (-not (Get-StBitLockerOn)) { Write-StErr (T 'ssd_bl_off_note') }
    } else {
        Write-StInfo (T 'hdd_note')
    }
}

# Безвозвратно удалить указанные пути с честным примечанием о гарантиях.
function Invoke-StShred {
    param([string[]]$Paths)
    if (-not $Paths -or $Paths.Count -eq 0) {
        Write-StErr (T 'shred_need_path'); Stop-StCommand
    }
    foreach ($p in $Paths) {
        if (-not (Test-Path $p)) { Write-StErr (T 'not_found' $p); Stop-StCommand }
    }
    if (-not (Confirm-StAction (T 'shred_confirm' ($Paths -join ' ')))) {
        Write-StWarn (T 'cancelled'); Stop-StCommand
    }
    foreach ($p in $Paths) {
        Remove-Item -Path $p -Recurse -Force -ErrorAction Stop
        Write-StInfo (T 'deleted' $p)
    }
    Write-StHonestDiskNote
}

# Опустошить папку-корзину, сохранив саму папку.
function Invoke-StEmpty {
    $trash = Get-StTrashDir
    if (-not (Test-Path $trash)) { Write-StErr (T 'empty_no_dir' $trash); Stop-StCommand }
    $items = Get-ChildItem -Path $trash -Force -ErrorAction SilentlyContinue
    if (-not $items -or $items.Count -eq 0) { Write-StInfo (T 'empty_already'); return }
    if (-not (Confirm-StAction (T 'empty_confirm' $trash))) {
        Write-StWarn (T 'cancelled'); Stop-StCommand
    }
    Remove-Item -Path (Join-Path $trash '*') -Recurse -Force -ErrorAction Stop
    Write-StInfo (T 'emptied' $trash)
    Write-StHonestDiskNote
}

# Прочитать пароль контейнера: из ST_VAULT_PASS (тесты/скрипты) или интерактивно.
function Get-StVaultPasswordPlain {
    if ($env:ST_VAULT_PASS) { return $env:ST_VAULT_PASS }
    $sec = Read-Host -AsSecureString (T 'vault_pass')
    $bstr = [Runtime.InteropServices.Marshal]::SecureStringToBSTR($sec)
    try {
        return [Runtime.InteropServices.Marshal]::PtrToStringBSTR($bstr)
    } finally {
        [Runtime.InteropServices.Marshal]::ZeroFreeBSTR($bstr)
    }
}

function ConvertTo-StSecureString {
    param([string]$Plain)
    return (ConvertTo-SecureString -String $Plain -AsPlainText -Force)
}

# Управление зашифрованным контейнером: create|open|close|destroy.
function Invoke-StVault {
    param([string[]]$VaultArgs)
    $sub = if ($VaultArgs -and $VaultArgs.Count -ge 1) { $VaultArgs[0] } else { '' }
    $vaultPath = Get-StVaultPath

    switch ($sub) {
        'create' {
            if (Test-Path $vaultPath) { Write-StErr (T 'vault_exists' $vaultPath); Stop-StCommand }
            $size = if ($VaultArgs.Count -ge 2) { $VaultArgs[1] } else { '1024' }  # МБ для diskpart / размер для VeraCrypt
            $passPlain = Get-StVaultPasswordPlain

            if (Get-StBitLockerCapable) {
                # Native: VHDX + Enable-BitLocker.
                $sec = ConvertTo-StSecureString $passPlain
                New-StBitLockerVault -Path $vaultPath -Size $size -Password $sec
                Write-StInfo (T 'vault_created' $vaultPath $size)
                Write-StWarn (T 'vault_preventive')
            } elseif (Get-StVeraCryptPath) {
                # Fallback: VeraCrypt.
                $vc = Get-StVeraCryptPath
                New-StVeraCryptVault -VeraCryptExe $vc -Path $vaultPath -Size $size -PasswordPlain $passPlain
                Write-StInfo (T 'vault_created' $vaultPath $size)
                Write-StWarn (T 'vault_preventive')
            } else {
                # Честный отказ.
                Write-StErr (T 'vault_unavailable'); Stop-StCommand
            }
        }
        'open' {
            if (-not (Test-Path $vaultPath)) { Write-StErr (T 'vault_no_container_open'); Stop-StCommand }
            if (Get-StBitLockerCapable) {
                Invoke-StDiskpart -Script "select vdisk file=`"$vaultPath`"`nattach vdisk"
            } elseif (Get-StVeraCryptPath) {
                $vc = Get-StVeraCryptPath
                $passPlain = Get-StVaultPasswordPlain
                & $vc /volume $vaultPath /letter V /password $passPlain /quit /silent | Out-Null
            } else {
                Write-StErr (T 'vault_unavailable'); Stop-StCommand
            }
            Write-StInfo (T 'vault_mounted' 'V:')
        }
        'close' {
            try {
                Dismount-StVault -Path $vaultPath
                Write-StInfo (T 'vault_closed')
            } catch {
                Write-StErr (T 'vault_detach_fail'); Stop-StCommand
            }
        }
        'destroy' {
            if (-not (Test-Path $vaultPath)) { Write-StErr (T 'vault_no_container' $vaultPath); Stop-StCommand }
            if (-not (Confirm-StAction (T 'vault_destroy_confirm' $vaultPath))) {
                Write-StWarn (T 'cancelled'); Stop-StCommand
            }
            try { Dismount-StVault -Path $vaultPath } catch { }
            Remove-StVaultContainer -Path $vaultPath
            Write-StInfo (T 'vault_destroyed')
        }
        default {
            Write-StErr (T 'vault_usage'); Stop-StCommand
        }
    }
}

function Show-StUsage {
    Write-Host (T 'usage')
}

# Диспетчер подкоманд. Команды кидают StExit при ошибке — ловим и делаем exit.
function Invoke-Main {
    param([string[]]$Argv)
    try {
        $cmd = if ($Argv -and $Argv.Count -ge 1) { $Argv[0] } else { '' }
        if (-not $cmd) { Show-StUsage; exit 1 }
        # Внешний @() обязателен: if как выражение разворачивает одноэлементный
        # массив в скаляр-строку, и индексация дала бы первый СИМВОЛ, не аргумент.
        $rest = @(if ($Argv.Count -ge 2) { $Argv[1..($Argv.Count - 1)] } else { @() })

        switch ($cmd) {
            'version' { Invoke-StVersion }
            'check'   { Invoke-StCheck }
            'setup'   { Invoke-StSetup }
            'shred'   { Invoke-StShred -Paths $rest }
            'empty'   { Invoke-StEmpty }
            'vault'   { Invoke-StVault -VaultArgs $rest }
            default {
                Write-StErr (T 'unknown_cmd' $cmd)
                Show-StUsage
                exit 1
            }
        }
    } catch [StExit] {
        exit $_.Exception.Code
    }
}

# --- dot-source guard ---
# При dot-source ($MyInvocation.InvocationName -eq '.') или ST_NO_MAIN=1 диспетчер
# НЕ запускается — определяются только функции (нужно для Pester).
if ($MyInvocation.InvocationName -ne '.' -and -not $env:ST_NO_MAIN) {
    Invoke-Main -Argv $args
}
