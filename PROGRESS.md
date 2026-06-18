---
project: securetrash
head: 6837a02
tests: bats 29/29 + Pester 35/35, shellcheck clean
status: v0.3.0 (security-hardened, macOS + Windows beta) — Release + landing live; code review + CyberGuard audit applied (vault status, shred/destroy hardening, pinned mountpoint, self-host fonts)
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

## Roadmap / отложенное (backlog)

Собрано из code review + аудита CyberGuard + конкурент-анализа. Порядок = грубый приоритет.

### Безопасность / аудит (CyberGuard 2026-06-18)

- [ ] **F-2 (Medium) supply-chain.** `install.sh`/`install.ps1` тянут `main` и исполняют без
  проверки целостности. Фикс: curl тянет релизный **тег** (не `main`); `SHA256SUMS` (+подпись)
  к каждому Release, проверка хеша до `chmod +x`; README — «verify-then-run» + Homebrew как
  основной путь. Делать пакетом с релизом (bump VERSION). Приоритет «до GA».
- [ ] **F-3 (Low-Med) Windows.** После `vault create` том остаётся примонтирован/разблокирован;
  `Enable-BitLocker` асинхронный. Фикс: авто-`close` или явное уведомление; опц. дождаться
  `EncryptionPercentage=100`. Делать при снятии Windows-beta.
- [ ] **F-4 (Low) подпись кода.** macOS notarization + Windows Authenticode для публичного релиза.
- Закрыто в этой сессии: F-1 (mountpoint/detach/destroy → dev-node + `-mountpoint -nobrowse`),
  F-5 (self-host шрифтов), threat-model FAQ.

### Фичи vault (code review #6/#8)

- [ ] **#6 `vault create [path] [size]`** — произвольный путь/имя (рабочий + личный vault).
  Каскадит на `open/close/destroy/status` (тоже принимают путь) + реальную точку монтирования
  читать из `hdiutil -plist`, volname из имени файла. Развилки (зона Mr. Di): позиционный arg
  vs реестр; дефолт сохранить `~/SecureVault.sparsebundle`.
- [ ] **#8 `vault list`** — инвентаризация. Зависит от #6. Рекомендуется реестр
  `~/.securetrash/vaults` (а не скан диска) — заодно «источник списка» для спеков A/B ниже.
- Порядок: #6 + реестр сначала, `list` следом почти бесплатно. По приоритету Mr. Di — после
  первой волны трафика (звёзд пока 0).

### Конкурент-фичи (уникальная ниша «честность»)

Полные спеки A/B уже в Google Drive (папка SecureTrash):
- [ ] **Leak Audit `vault audit`** (#1) — Spotlight/TM/cloud/swap/QuickLook/open-handles.
  Spec: `securetrash-spec-leak-audit.md` (Drive).
- [ ] **Backup-snapshot detection при `destroy`** (#3) — `tmutil`/APFS snapshots, TM exclusion,
  remote-dest, receipt. Spec: `securetrash-spec-backup-snapshot-detection.md` (Drive).
- [ ] **Ephemeral vault** `vault create --ttl 24h` — самоуничтожение через launchd/cron.
- [ ] **`vault destroy --paranoia`** — pre-flight (unmount→TM-exclude→cloud→snapshots→clear/block)
  + cryptographic receipt (SHA-256 манифеста + timestamp). Частично описан в snapshot-спеке.
- [ ] **`vault close --scrub`** — обнуление памяти/swap процессов, обращавшихся к vault (macOS).
- [ ] **`shred --git-aware`** — предупреждать, если файл в git-репо/закоммичен/в `.git/objects`
  (dev-аудитория, пустая ниша).
- [ ] **`vault note "..."`** — ephemeral in-vault заметка, без shell-history (HISTIGNORE).
- Стратегический приоритет (минимум кода / максимум impact): snapshot-detection (#3) + Leak
  Audit (#1) — прямое развитие УТП; git-aware shred (#6-feat) — органический рост через dev.

### Сервис / автоматизация

- [ ] **Доставка weekly-intel отчёта** — routine `trig_01RMdr8wqi1CqHCBEVH92Zgx` сейчас кладёт
  отчёт только в Drive (пассивно). Проработать доставку (почта/другой адрес/«как для юзера»).
  Решение Mr. Di по адресу/формату ожидается. (см. память `securetrash-weekly-intel-delivery`)
