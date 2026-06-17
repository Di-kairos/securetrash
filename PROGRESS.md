---
project: securetrash
head: 90d0141
tests: bats 16/16 + Pester 12/12, shellcheck clean
status: v0.2.0 (macOS) + Windows port (beta)
last_session: "2026-06-17"
next_actions:
  - "Создать tap-репо Di-kairos/homebrew-tap для `brew install Di-kairos/tap/securetrash`"
  - "Дождаться зелёного CI на main; поправить, если упадёт на macos-latest"
  - "Демо-GIF/asciinema для README (vault workflow)"
links:
  repo: "https://github.com/Di-kairos/securetrash"
  spec: "docs/superpowers/specs/2026-06-17-securetrash-cli-design.md"
  plan: "docs/superpowers/plans/2026-06-17-securetrash-cli.md"
---

# SecureTrash — прогресс

## Что это

Честный CLI безопасного удаления файлов на macOS. Главная идея — не врать про SSD:
`rm -P` (перезапись) не даёт гарантий на SSD/APFS (wear leveling, COW, TRIM).
Реальная защита — FileVault + crypto-shred через зашифрованный `vault` (sparsebundle AES-256).

## Текущее состояние

v0.1.0 опубликован публично: https://github.com/Di-kairos/securetrash

Команды: `check`, `setup`, `empty`, `shred <path>`, `vault create|open|close|destroy`, `version`.

- Тесты: `bats test/securetrash.bats` — 16/16; `shellcheck securetrash install.sh` — clean.
- Реальный vault smoke (hdiutil) проверен локально end-to-end: create→open→write→close→destroy.
- Дистрибуция: `install.sh` (curl) рабочий; Homebrew-формула с sha256 на тег v0.1.0
  (нужен отдельный tap-репо, см. next_actions).
- CI: `.github/workflows/ci.yml` — shellcheck + bats + vault smoke на macos-latest.

## Фазы

- [x] v1: ядро CLI + vault + доки + дистрибуция + CI → опубликовано
- [ ] tap-репо для Homebrew
- [ ] демо-GIF, GitHub Pages лендинг (опц.)

## Решения

- Чистый Bash, ноль рантайм-зависимостей — security-инструмент должен читаться глазами.
- `vault destroy` через `rm -rf` (не `-P`): контейнер — шифрошум, перезапись не нужна.
- `vault` подаётся как **превентивный** crypto-shred (предупреждение в выводе `create` и `check`).
