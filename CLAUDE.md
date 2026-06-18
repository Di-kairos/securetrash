# securetrash — проектные правила

Дополняет глобальный `/Volumes/X10 Pro/projects/CLAUDE.md`. Здесь — стек, конвенции,
нав-карта. Универсальные правила (синхронизация, git-политика, сессии) — в глобальном.

## Что это

Честный CLI безопасного удаления на macOS (+ Windows beta). Тезис: не врать про SSD —
`rm -P` не гарантия на SSD/APFS; реальная защита = FileVault + crypto-shred через
зашифрованный `vault` (sparsebundle AES-256). v0.4.0 released.

**North-star:** проект — якорь экосистемы из 5 честных утилит вокруг жизненного цикла
секрета. Полное видение и архитектура — `ECOSYSTEM.md` (читать в начале каждой сессии).

## Стек и конвенции

- Чистый **Bash**, ноль рантайм-зависимостей. Нативные примитивы: `hdiutil`, `mdutil`,
  `tmutil`, `diskutil`, `fdesetup`, `launchd`. Windows-порт — PowerShell 5.1 baseline.
- `shellcheck`-clean обязательно. Тесты: **bats** (`test/`) + **Pester** (`windows/test/`).
- Вывод EN по умолчанию, `ST_LANG=ru` — русский. i18n через функцию `t()`.
- Необратимые операции требуют `yes` / `--yes` (`ST_ASSUME_YES=1` для тестов).
- Комментарии/docstrings — русский; идентификаторы/файлы/коммиты — английский.
- Conventional commits (`feat:`/`fix:`/`chore:`/`docs:`). Co-author trailer в коммитах.
- Дистрибуция: checksum-verified install с релизного тега (F-2), Homebrew tap основным.
  Релиз: push тега `v*` → `release.yml` собирает `SHA256SUMS` + ассеты.

## Vendoring (lib/common.sh)

`lib/common.sh` — **канонический источник** переиспользуемых примитивов экосистемы
(локаль, output `info/warn/err`, `confirm`, платформа `require_macos/is_ssd/_disk_kind/
filevault_on`, `_abspath`). Sourceable, идемпотентен, без tool-специфичных строк.

Инструменты экосистемы (vaultwatch/panic/...) — отдельные репо, single-file. Они
**вендорят** этот файл inline между маркерами:

```
# === BEGIN vendored common (pin: <securetrash git ref>) ===
<содержимое lib/common.sh>
# === END vendored common ===
```

Правила: вендорить с **пиннутого git-ref** securetrash (воспроизводимость); CI каждого
инструмента проверяет, что блок не дрейфит от пиннутой версии. securetrash сам common.sh
не потребляет (скрипт предшествует библиотеке; конвергенция — опциональна, не ломать релиз).

## Vault hooks (точка интеграции экосистемы)

`securetrash vault open/close` дёргают пользовательские хуки — через них утилиты
Paranoid Tools (vaultwatch/panic) цепляются к жизненному циклу контейнера, не правя ядро.

- Каталог: `${ST_HOOK_DIR:-~/.securetrash/hooks}`.
- `post-open <mountpoint>` — после успешного монтирования (НЕ срабатывает, если контейнер
  уже был открыт). `post-close <mountpoint>` — после успешного размонтирования.
- Хук запускается, только если файл существует и **исполняемый** (`chmod +x`).
- Падение хука **не роняет** vault-операцию (только `warn`) — интеграция необязательна.
- **Инвариант:** `vault open/close` выполняются от пользователя, не под `sudo`; хук
  наследует права пользователя. Не запускать vault под sudo.

## Нав-карта

- `ECOSYSTEM.md` — north-star экосистемы (цель проекта).
- `PROGRESS.md` — living-состояние: frontmatter (head/tests/status/next_actions), roadmap.
- `securetrash` — основной скрипт (single-file). `windows/securetrash.ps1` — порт.
- `install.sh` / `windows/install.ps1` — checksum-verified установщики.
- `test/` bats, `windows/test/` Pester. `.github/workflows/` ci + release.
- `docs/` — спеки/планы/промо. `Formula/securetrash.rb` — копия Homebrew-формулы (tap отдельно).

## Skill routing

When the user's request matches an available skill, invoke it via the Skill tool. When in doubt, invoke the skill.

Key routing rules:
- Product ideas/brainstorming → invoke /office-hours
- Strategy/scope → invoke /plan-ceo-review
- Architecture → invoke /plan-eng-review
- Design system/plan review → invoke /design-consultation or /plan-design-review
- Full review pipeline → invoke /autoplan
- Bugs/errors → invoke /investigate
- QA/testing site behavior → invoke /qa or /qa-only
- Code review/diff check → invoke /review
- Visual polish → invoke /design-review
- Ship/deploy/PR → invoke /ship or /land-and-deploy
- Save progress → invoke /context-save
- Resume context → invoke /context-restore
- Author a backlog-ready spec/issue → invoke /spec
