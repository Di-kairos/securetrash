# Session 03 — kickoff

## Что читать первым

1. `PROGRESS.md` — frontmatter (head/tests/status/next_actions/routines/links) + секции
   **Pre-launch focus** и **Roadmap**.
2. `docs/sessions/progress-report-session02.md` — полный итог сессии 02.
3. `docs/promo/launch-plan.md` — календарь/тайминги запуска.
4. Спеки конкурент-фич — Google Drive, папка **SecureTrash** (Leak Audit + snapshot-detection).
5. Этот файл — фокус сессии 03.

## Состояние на старте

- Проект **securetrash** · `main` · HEAD `9ee7e18` (последний код-коммит **`1e9470d`**) · теги v0.1.0/0.2.0/**0.3.0**.
- Тесты: **bats 31/31 + Pester 35/35**, shellcheck clean. CI зелёный (macOS + windows-latest).
- Release v0.3.0 (latest) · Homebrew tap · **лендинг live**: https://olma777.github.io/securetrash/
- `destroy` теперь **fail-closed** (не удаляет при mounted/unknown) — главный аудит-риск закрыт.
- Routines (cloud, машинно-независимы): weekly-intel `trig_01RMdr8wqi1CqHCBEVH92Zgx` активна;
  HN warm-up `trig_01VBoWsx57CkFXd7daVNMAYm` **отключена** (карма-фарм отвергнут).

## Стратегия запуска (важно — принято в конце сессии 02)

Греть **продукт + честную историю**, НЕ карму аккаунта. HN-аудитория за 10 мин найдёт слабости —
назвать их первым в Show HN = сила. Вести историей (SSD-миф), не `brew install`. Прогрев аккаунта —
только реальными комментами своим голосом, без заготовок.

## Фокус сессии 03 — PRE-LAUNCH (цель Show HN Вт 2026-06-23)

Порядок:
1. **F-2 checksum-install** — `install.sh`/`.ps1` тянут релизный **тег** (не `main`); `SHA256SUMS`
   (+подпись) к Release; проверка хеша до `chmod +x`; README «verify-then-run» + Homebrew основным.
   Это главный HN-триггер «curl|bash без проверки». **Решить:** пакетом с релизом **v0.4.0** (bump
   VERSION — накопились vault status/hardening) или без bump.
2. **Вычитка блога** «SSD myth» + написать **Show HN текст** (история + секция «что НЕ делает»).
3. (опц.) `verify` self-test команда — доверие через проверяемость.
4. Pre-flight нетехн.: social-preview картинка репо, dev.to публикация блога, email-verify аккаунта HN.

После запуска (по приоритету): **#1 Leak Audit** (спек в Drive) → #3 snapshot-aware destroy →
mdutil-exclusion → auto-dismount + password-entropy → git-aware shred. Полный backlog — Roadmap.

## Открытые решения (ждут Mr. Di)

- **F-2 + v0.4.0:** резать релиз вместе с checksum-фиксом или отдельно.
- **Развилка #1:** Leak Audit как отдельная `vault audit` (текущий спек) ИЛИ влить в `check`/`doctor`
  (выше discoverability). Предложение Claude — в `check`. По ОК переписать спек Leak Audit.
- **Доставка weekly-intel** (почта/адрес/формат) — Gmail API умеет только draft, не send.
- Постинг (Show HN/Reddit/awesome-PR) — ручной, по `launch-plan.md`, после прогрева аккаунта.

## Инструменты на машине (локально, не синкаются — проверить на домашнем)

`bats-core`, `shellcheck`, `pwsh`+Pester, `gh`(auth: repo+workflow), `codex`, `gemini`,
`ffmpeg`/`vhs` (GIF). Codex/Gemini нужны для ТриМозга-ревью (security-пути → обязательный Codex).
