---
project: securetrash
head: bff9600
tests: bats 19/19 + Pester 35/35, shellcheck clean
status: v0.3.0 (security-hardened, macOS + Windows beta) — Release published + landing live
last_session: "2026-06-18"
next_actions:
  - "[DRAFTED] Show HN + Reddit (docs/promo/session02-launch-posts.md) — постит Mr. Di"
  - "[DONE] Блог 'SSD myth' EN+RU (docs/blog/, Codex-fact-checked)"
  - "[PREPPED] awesome-list PR-kit (docs/promo/session02-awesome-list-prs.md) — слать после >20★ (Pages уже live)"
  - "[DONE] CONTRIBUTING.md + issue forms (вкл. Windows hardware test report)"
  - "[DONE] GitHub Pages лендинг → https://olma777.github.io/securetrash/ (homepage репо выставлен)"
  - "v2-деферы: снять Windows BETA (валидация на железе), New-VHD, hdiutil -plist, отдельный data-key"
links:
  repo: "https://github.com/Di-kairos/securetrash"
  site: "https://olma777.github.io/securetrash/"
  release: "https://github.com/Di-kairos/securetrash/releases/tag/v0.3.0"
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
