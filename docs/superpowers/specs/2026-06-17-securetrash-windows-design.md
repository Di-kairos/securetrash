# SecureTrash Windows port — дизайн (beta)

Дата: 2026-06-17
Статус: design approved (user delegated), build via subagents

## Контекст

macOS-версия (`securetrash`, bash) опубликована (v0.2.0). Windows-пользователям нужен
порт с той же философией: **честность про SSD** + реальный crypto-shred. Стек на Windows
другой — FileVault→BitLocker, hdiutil sparsebundle→BitLocker-VHDX / VeraCrypt.

## Принцип честности (тот же)

Перезапись (`cipher /w`, SDelete) на SSD НЕ даёт гарантий (wear leveling, TRIM, COW у
ReFS). Реальная защита: (1) BitLocker (шифрование диска), (2) crypto-shred через
зашифрованный контейнер → уничтожить контейнер+ключ.

## Архитектура

`windows/securetrash.ps1` — PowerShell (baseline Windows PowerShell 5.1, совместим с
PowerShell 7). Диспетчер подкоманд, зеркало macOS: `check`, `setup`, `empty`,
`shred <path>`, `vault {create,open,close,destroy}`, `version`.

i18n: английский по умолчанию, `ST_LANG=ru` (или `$PSUICulture` ru-*) → русский.
Хэш-таблица сообщений `"$locale:$key"`.

### check
- SSD/HDD: `(Get-PhysicalDisk).MediaType`.
- BitLocker системного диска: `Get-BitLockerVolume` (try/catch — на Home cmdlet может
  отсутствовать) → ON/OFF/недоступен.
- VeraCrypt: наличие в PATH / стандартном пути.
- Честный вердикт: что реально достижимо.

### vault — crypto-shred (native + fallback)
- **Native (BitLocker доступен):** создать VHDX (`diskpart` create vdisk + attach, без
  зависимости от Hyper-V), форматировать NTFS, `Enable-BitLocker -PasswordProtector`.
- **Fallback (Home / нет BitLocker, есть VeraCrypt):** `VeraCrypt /create ... /password`.
- `open/close`: монтирование/размонтирование (manage-bde unlock + diskpart attach /
  VeraCrypt /volume).
- `destroy`: размонтировать + удалить контейнер = crypto-shred.
- Превентивная оговорка в выводе `create` (как на macOS).
- Если ни BitLocker, ни VeraCrypt — `vault` честно сообщает, что недоступен, и предлагает
  включить BitLocker или поставить VeraCrypt. Без молчаливого «как будто зашифровали».

### empty / shred
Best-effort overwrite (`cipher /w` по папке-цели или просто удаление) + честная заметка по
типу диска (SSD: «не гарантия, нужен BitLocker/vault»).

## Тестирование и ограничение (ВАЖНО)

- `windows/test/securetrash.Tests.ps1` — Pester 5, **все** Windows-specific cmdlets/exe
  замоканы (`Get-PhysicalDisk`, `Get-BitLockerVolume`, `diskpart`, `manage-bde`,
  `VeraCrypt`). Проверяется диспетчер, i18n, ветвления, honest-вывод. Запускается на
  `pwsh` (в т.ч. macOS) — логика верифицируется кросс-платформенно.
- **Ограничение честности:** реальное поведение BitLocker/VHDX/VeraCrypt на железе НЕ
  проверено (нет Windows-машины у разработчика). Порт помечается **BETA** в README и
  выводе. GitHub Actions `windows-latest` гоняет Pester (логика); реальный crypto-shred
  smoke на железе — открытая задача (нужен валидатор на Windows).

## Файлы

```
windows/securetrash.ps1            # порт
windows/install.ps1                # irm | iex инсталлятор
windows/test/securetrash.Tests.ps1 # Pester
windows/README.md                  # Windows-специфичные заметки + BETA-дисклеймер
```
CI: добавить job `windows-latest` (Invoke-Pester) в `.github/workflows/ci.yml`.

## Критерии успеха

1. `Invoke-Pester windows/test` зелёный на pwsh.
2. `check` корректно классифицирует (мок SSD+BitLocker) и честно проговаривает SSD.
3. `vault` ветвится: BitLocker → native, иначе VeraCrypt, иначе честный отказ.
4. BETA-дисклеймер виден в README и в выводе `version`/`check`.
5. EN по умолчанию, `ST_LANG=ru` переключает.
