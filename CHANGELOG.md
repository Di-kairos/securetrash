# Changelog

Все заметные изменения securetrash. Формат — [Keep a Changelog](https://keepachangelog.com/ru/1.1.0/),
версионирование — [SemVer](https://semver.org/lang/ru/).

## [Unreleased]

## [0.4.2] — 2026-06-23

### Fixed
- **`shred` — mount-root guard:** refused to shred `/Volumes/<name>` (direct children of
  `/Volumes`) — protects external drives and the vault's own mountpoint from accidental
  recursive deletion. Previously only `/Volumes` itself was guarded.
- **`install.sh` — release signing pubkey:** v0.4.1 assets were cut before the pubkey was
  embedded; `RELEASE_SIGNING_PUBKEY` was empty and auto-verify was silently skipped. v0.4.2
  release assets contain the correct pubkey so installer signature verification runs.

## [0.4.1] — 2026-06-22

### Added
- **Подпись релизов (Ed25519, опциональная):** CI подписывает `SHA256SUMS`, `install.sh`
  авто-проверяет подпись поверх контрольной суммы. Мягкая деградация — нет ключа/подписи
  не ломает установку. Pubkey опубликован в `SECURITY.md`.
- Флаги-алиасы `-v`/`--version` и `-h`/`--help`.
- Канонический `lib/common.sh` — источник вендоринга для экосистемы Paranoid Tools.
- Хуки `vault open/close` (`post-open`/`post-close`) — точка интеграции vaultwatch/panic.

### Fixed
- **Windows `vault destroy` — fail-closed (tri-state):** не удаляет backing-файл, пока том
  смонтирован или состояние не определено; mounted → размонтировать и перепроверить.
- **Windows `shred` — protected-path guard:** отказ для корней дисков и системных деревьев
  (Windows, Program Files, ProgramData, корень Users, профиль).

### Changed
- **Windows: честный tri-state детект диска** (ssd/hdd/unknown) — неизвестный тип больше не
  выдаётся за HDD с обнадёживающим «перезапись помогает».
- Честная формулировка crypto-shred в `windows/README`; landing-install тянется с релизного
  тега (а не с подвижной `main`) с проверкой.

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
