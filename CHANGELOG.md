# Changelog

Все заметные изменения securetrash. Формат — [Keep a Changelog](https://keepachangelog.com/ru/1.1.0/),
версионирование — [SemVer](https://semver.org/lang/ru/).

## [Unreleased]

## [0.4.0] — 2026-06-18

### Added
- **Checksum-verified `install.sh`** (F-2): бинарь и `SHA256SUMS` тянутся с релизного
  тега, хеш проверяется ДО установки — закрывает supply-chain риск «curl|bash из main».

### Changed
- **`vault destroy` — fail-closed:** никогда не удаляет, пока контейнер смонтирован или
  состояние неизвестно (защита от случайного уничтожения живого vault).
- Hardening: закреплён mountpoint vault, самохостинг шрифтов в доках, FAQ про угрозу
  открытого vault.

## [0.3.0] — 2026-06-17

### Added
- **PowerShell-порт под Windows (beta)** с Pester-тестами и CI.

### Fixed
- Security-hardening: честные формулировки гарантий, `--` guard'ы на путях, проверка
  целевого тома, права `0700`, флаг `--yes`.
- Windows: пароли не через argv, валидация diskpart, `-LiteralPath`, разблокировка
  BitLocker, отслеживание backend.
- Де-пиннинг version-теста.

## [0.2.0] — 2026-06-17

### Added
- **i18n:** вывод по умолчанию на английском, русский — через `ST_LANG=ru`.
- Демо-gif и английский README/guide как основной (русский — вторичный).

## [0.1.0] — 2026-06-17

Первый публичный срез: безопасное удаление + шифрованный vault (crypto-shred) для macOS.

### Added
- **`check`** — честный аудит окружения (FileVault, тип диска SSD/HDD) и вердикт, какие
  гарантии реальны на данном железе.
- **`vault create|open|close|destroy|status`** — шифрованный контейнер; «уничтожение» =
  крипто-шреддинг (удаление ключа), что реально на SSD в отличие от перезаписи.
- **`shred`**, **`setup`**, **`empty`** — удаление файлов/папок, инициализация `~/SecureTrash`.
- README, LICENSE, гайд.

### Honest limitations
- На SSD перезапись (`rm -P`) гарантий НЕ даёт (wear leveling, COW, TRIM) — для секретов
  использовать `vault` превентивно. Подробности — `README.md` «Scope & limitations».

[Unreleased]: https://github.com/Di-kairos/securetrash/compare/v0.4.0...HEAD
[0.4.0]: https://github.com/Di-kairos/securetrash/releases/tag/v0.4.0
[0.3.0]: https://github.com/Di-kairos/securetrash/releases/tag/v0.3.0
[0.2.0]: https://github.com/Di-kairos/securetrash/releases/tag/v0.2.0
[0.1.0]: https://github.com/Di-kairos/securetrash/releases/tag/v0.1.0
