# Session 05 — kickoff

## Что читать первым
1. `ECOSYSTEM.md` — north-star (5 честных утилит вокруг жизни секрета). §6 = спека ghostdraft.
2. `PROGRESS.md` — frontmatter (head/status/next_actions).
3. `docs/sessions/progress-report-session04.md` — полный итог сессии 04.
4. `CLAUDE.md` (проектный) — vendoring + vault-hooks контракты.
5. Память X10: `ecosystem-north-star`, `three-brain-mandatory`.

## Состояние на старте (всё запушено, CI зелёный)
- Корень: `/Volumes/X10 Pro/projects/paranoid-tools/` (umbrella, HEAD `b000fb6`).
- **securetrash** · Di-kairos/securetrash · код HEAD `ebb2ae2` · v0.4.0 RELEASED · bats 55/55 + Pester 38/38.
- **vaultwatch** · Di-kairos/vaultwatch **PUBLIC** · HEAD `1c27e51` · тег v0.1.0 (на `76cb076`) · bats 46/46.
- **panic** · Di-kairos/panic **PUBLIC** · HEAD `df1d64a` · тег v0.1.0 · bats 20/20.
- **ghostdraft** · Di-kairos/ghostdraft (private) · HEAD `2997acc` · Pack 1 scaffold · bats 9/9.
- Vendoring везде пиннут к securetrash `2e3d2dd` + SHA256.

## Фокус сессии 05 — ghostdraft Pack 2 (ядро `new`/`pipe`)
Запускать Claude Code ИЗ `paranoid-tools/securetrash` (слаг памяти от пути) либо из
`paranoid-tools/ghostdraft` для работы над ним.
- **`pipe`** (лёгкий, первым): читать stdin → печатать в терминал, на диск НИЧЕГО.
  Тест: `printf seed | ghostdraft pipe` → вывод, без временных файлов.
- **`new`**: temp **в открытом vault** (предпочтительно) ИЛИ RAM-диск
  (`hdiutil attach -nomount ram://<sectors>` + `diskutil erasevolume`); открыть
  `$EDITOR`/nano; по выходу — shred файла + чистка editor-следов
  (vim `.swp`/`.un~`/`viminfo`, nano backup, VSCode workspace history).
- **`--clipboard`**: off-by-default + явный warn (Universal Clipboard синкает в iCloud).
- TDD + PATH-стабы (hdiutil/diskutil/pbcopy + fake `$EDITOR`). Честно: swap/scrollback
  НЕ покрываем — перечислить в README, не скрывать.
- Паттерн как panic/vaultwatch: Pack 2 ядро → release-prep → public+tag (по явному go).

## Релиз-паттерн (подтверждён сессией 04)
1. Код-паки TDD (bats + PATH-стабы), shellcheck, vendor --check.
2. **Проактивный SC2015-скан** (`grep -nE '&&.*\|\|'`): локальный shellcheck 0.11
   пропускает SC2015, CI-shellcheck (apt) ловит → проверять до пуша.
3. Real-device smoke на macOS (одноразовый ресурс, обратимо).
4. install.sh/release.yml/CHANGELOG (зеркало vaultwatch/panic).
5. **Публикация (public + tag) — ТОЛЬКО по явному go пользователя** (необратимо).
6. Push workflow-файлов: `gh repo create ... ` создаёт репо, но push делать ПРЯМЫМ
   `git push` (keychain credential имеет workflow-scope; gh OAuth-токен — нет).

## Блокеры — НЕТ. Инструменты (локально, не синкаются): bats, shellcheck, gh, codex, gemini, graphify.
