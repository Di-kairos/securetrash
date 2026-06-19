# Session 04 — kickoff

## Что читать первым
1. `ECOSYSTEM.md` — north-star (цель: 5 честных утилит вокруг жизни секрета).
2. `PROGRESS.md` — frontmatter (head/tests/status/next_actions).
3. `docs/sessions/progress-report-session03.md` — полный итог сессии 03.
4. `CLAUDE.md` (проектный) — vendoring + vault-hooks контракты.
5. Память X10: `ecosystem-north-star`, `three-brain-mandatory`.

## Состояние на старте
- **Новый корень: `/Volumes/X10 Pro/projects/paranoid-tools/`** (umbrella).
  Запускать Claude Code ИЗ `paranoid-tools/securetrash` (слаг памяти от этого пути).
- **securetrash** · Di-kairos/securetrash · HEAD `ebb2ae2` · v0.4.0 RELEASED.
  bats 55/55 + Pester 38/38, shellcheck clean.
- **vaultwatch** · Di-kairos/vaultwatch (private) · HEAD `1c9b4c6` · Pack 3a готов.
  bats 14/14, shellcheck clean. vendoring пиннут к securetrash `2e3d2dd` + SHA256.
- **umbrella** · Di-kairos/paranoid-tools (private) · HEAD `fe3c1d8`.
- Cross-repo граф: `paranoid-tools/graphify-out/merged-graph.json` (414n/512e).

## Фокус сессии 04 — vaultwatch Pack 3b (ядро сторожа)
`start <mnt>` / `stop`:
- `mdutil -i off <mnt>` при start → `mdutil -i on` при stop (Spotlight).
- `tmutil addexclusion <mnt>` при start → `removeexclusion` при stop (Time Machine).
- Проверить `tmutil listlocalsnapshots /` — честно сообщить про уже снятые снапшоты.
- Состояние сессии в state-файле (для restore при stop). TDD + моки mdutil/tmutil.
- **Три-мозга обязательно** (Codex+Gemini) до коммита.
Дальше: 3c cloud-detect+session report → 3d --ttl/launchd → 3e README+checksum-install+release.yml.

## Блокеры — НЕТ (всё решено 2026-06-19)
- Биллинг РЕШЁН: аккаунт апгрейднут до **GitHub Pro** → Actions разблокированы.
  **Оба CI зелёные** (securetrash 6003e35-контекст, vaultwatch 6003e35). Поправлен
  portability-баг (install-hooks убрал require_macos → работает на ubuntu CI).
- CI: securetrash lint→ubuntu(free)+test→macos; vaultwatch→ubuntu(free). vaultwatch HEAD `6003e35`.

## Инструменты (локально, не синкаются — проверить на домашней машине)
`bats-core`, `shellcheck`, `pwsh`+Pester, `gh`, `codex`, `gemini`, `graphify`.
Codex+Gemini нужны для обязательного три-мозга-ревью.
