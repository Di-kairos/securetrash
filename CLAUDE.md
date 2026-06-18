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
