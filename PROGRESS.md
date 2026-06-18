---
project: securetrash
head: 1e9470d
tests: bats 31/31 + Pester 35/35, shellcheck clean
status: v0.3.0 (security-hardened, macOS + Windows beta) — Release + landing live; review+audit applied; destroy now fail-closed (never deletes while mounted/unknown)
last_session: "2026-06-18"
next_actions:
  - "PRE-LAUNCH (цель Show HN Вт 2026-06-23): F-2 checksum-install — curl→тег + SHA256SUMS + проверка хеша + README verify-then-run (главный HN-триггер)"
  - "Решить: резать F-2 пакетом с релизом v0.4.0 (bump VERSION) или на текущей версии"
  - "Вычитка блога 'SSD myth' + написать Show HN текст (вести историей, секция 'что НЕ делает')"
  - "(опц.) verify self-test команда; pre-flight нетехн: social-preview картинка, dev.to блог, email-verify аккаунта"
  - "Развилка post-launch: Leak Audit как vault audit ИЛИ в check (ждёт ОК Mr. Di) → переписать спек"
  - "Полный backlog (фичи #1-#8, F-3/F-4, конкурент-фичи) — секция Roadmap ниже"
launch_plan: "docs/promo/launch-plan.md"
routines:
  warmup_hn: "trig_01VBoWsx57CkFXd7daVNMAYm (ОТКЛЮЧЕНА — карма-фарм отвергнут)"
  weekly_intel: "trig_01RMdr8wqi1CqHCBEVH92Zgx (активна, пн→Drive)"
links:
  repo: "https://github.com/Di-kairos/securetrash"
  site: "https://olma777.github.io/securetrash/"
  release: "https://github.com/Di-kairos/securetrash/releases/tag/v0.3.0"
  drive_specs: "Google Drive → папка SecureTrash (Leak Audit + snapshot-detection специ)"
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

### Pre-launch focus (до Show HN, цель Вт 2026-06-23)

Стратегия (по фидбэку Mr. Di): греть **продукт + честную историю**, не карму аккаунта.
HN-аудитория за 10 мин найдёт то же, что аудит — назвать слабости первым = сила, не слабость.
Warm-up routine отключена (карма-фарм заготовками = против анти-спама, палится).

- [x] **F-1 fail-closed destroy** — никогда не удаляет при mounted/unknown (commit 1e9470d).
- [ ] **F-2 checksum-install** (см. ниже) — главный HN-триггер «curl|bash без проверки».
- [ ] Вычитка блога «SSD myth» (уже Codex-fact-checked) — это топливо для front page.
- [ ] Show HN текст: вести историей (SSD-миф), не `brew install`; секция «что НЕ делает».
- [ ] (опц.) `verify` self-test — усилил бы доверие на запуске.
- Pre-flight (нетехн.): social-preview картинка репо, dev.to блог, email-verify аккаунта.

### Безопасность / аудит (CyberGuard 2026-06-18)

- [ ] **F-2 (Medium) supply-chain.** `install.sh`/`install.ps1` тянут `main` и исполняют без
  проверки целостности. Фикс: curl тянет релизный **тег** (не `main`); `SHA256SUMS` (+подпись)
  к каждому Release, проверка хеша до `chmod +x`; README — «verify-then-run» + Homebrew как
  основной путь. Делать пакетом с релизом (bump VERSION). Приоритет «до GA».
- [ ] **F-3 (Low-Med) Windows.** После `vault create` том остаётся примонтирован/разблокирован;
  `Enable-BitLocker` асинхронный. Фикс: авто-`close` или явное уведомление; опц. дождаться
  `EncryptionPercentage=100`. Делать при снятии Windows-beta.
- [ ] **F-4 (Low) подпись кода.** macOS notarization + Windows Authenticode для публичного релиза.
- Закрыто в этой сессии: **F-1 fail-closed** (dev-node detach + tri-state mount + postcondition;
  destroy НЕ удаляет при mounted/unknown — commit 1e9470d), `-mountpoint -nobrowse`,
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
- [ ] **Энтропия пароля на `create`** — мерить силу парольной фразы, предупреждать о слабой
  (diceware-подсказка). Логично: crypto-shred стоек ровно настолько, насколько стоек пароль.
- [ ] **Авто-dismount** по idle (N мин) + на sleep/lock — сужает главное окно экспозиции
  (открытый контейнер). Близко к ephemeral `--ttl`, другой триггер.
- [ ] **`verify` self-test** — round-trip create→open→write→close→reopen + проверка, что после
  `destroy` band-файлы реально исчезли. Доверие через проверяемость.
- **Принцип (Mr. Di):** углублять тезис, не раздувать поверхность. НЕ добавлять: GUI, cloud,
  «35-pass», бэкап-менеджер, телеметрию (противоречат тезису или сами = канал утечки).
- **Приоритет фич (по убыванию):** #1 Leak Audit → #3 snapshot-aware destroy → mdutil-exclusion
  при mount → авто-dismount+entropy → `verify` → git-aware shred. Если одно — **#1**.
- **Развилка по #1 (ждёт ОК Mr. Di):** Leak Audit как отдельная `vault audit` (текущий спек) ИЛИ
  встроить в `check`/`doctor` (выше discoverability — юзер уже запускает `check`). Предложение:
  `check` += секция «vault leak channels», когда контейнер есть/открыт. По ОК — переписать спек.
- **Widen (отдельная сессия):** Linux-порт на LUKS2 (detached header + crypto-shred key-slot).

### Сервис / автоматизация

- [ ] **Доставка weekly-intel отчёта** — routine `trig_01RMdr8wqi1CqHCBEVH92Zgx` сейчас кладёт
  отчёт только в Drive (пассивно). Проработать доставку (почта/другой адрес/«как для юзера»).
  Решение Mr. Di по адресу/формату ожидается. (см. память `securetrash-weekly-intel-delivery`)
