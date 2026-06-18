# Session 03 — kickoff

## Что читать первым

1. `PROGRESS.md` — frontmatter (head/tests/status/next_actions/links) + секция **Roadmap / отложенное**.
2. Этот файл — фокус сессии 03.
3. `docs/sessions/progress-report-session01.md` — итог сессии 01 (ядро/публикация).
4. Спеки конкурент-фич — в Google Drive, папка **SecureTrash**
   (`securetrash-spec-leak-audit.md`, `securetrash-spec-backup-snapshot-detection.md`).

## Состояние на старте

- Проект **securetrash** · ветка `main` · HEAD **`a44be04`** · теги v0.1.0/v0.2.0/**v0.3.0**.
- Тесты: **bats 29/29 + Pester 35/35**, shellcheck clean. CI зелёный (macOS + windows-latest).
- Опубликовано: репо + Homebrew tap. **Release v0.3.0** (latest, с changelog).
- **Лендинг live:** https://olma777.github.io/securetrash/ (homepage репо выставлен,
  self-hosted шрифты, без сторонних CDN).
- Weekly-intel routine `trig_01RMdr8wqi1CqHCBEVH92Zgx` (пн 06:00 UTC → отчёт в Drive).

## Что сделано в сессии 02 (раскрутка + hardening)

- Release v0.3.0 + changelog.
- Драфты Show HN + Reddit (`docs/promo/session02-launch-posts.md`) — постит Mr. Di.
- Блог «SSD myth» EN+RU (`docs/blog/`), Codex-fact-checked (NIST SP 800-88r2, FAST'11).
- Awesome-list PR-kit (`docs/promo/session02-awesome-list-prs.md`) — слать после >20★.
- CONTRIBUTING + issue-forms (вкл. Windows hardware test) + SECURITY.md.
- GitHub Pages лендинг.
- **Code review pack** (Codex adversarial): `vault status`, open-guard, dev-node detach,
  shred-blacklist (canonicalize + nocasematch + symlink/slash), destroy валидирует bundle.
- **CyberGuard audit fixes:** F-1 (mountpoint pin + dev-node), F-5 (self-host шрифтов), threat-FAQ.
- Спеки Leak Audit + snapshot-detection → Google Drive.
- Roadmap-секция в PROGRESS.

## Фокус сессии 03 — выбрать из Roadmap

Рекомендуемый порядок (детали в `PROGRESS.md` → Roadmap):

1. **F-2 supply-chain + релиз v0.4.0** (приоритет «до GA»): curl тянет тег (не `main`),
   `SHA256SUMS`+проверка хеша, README verify-then-run, Homebrew как основной путь.
   Делать пакетом с bump VERSION → v0.4.0 (накопились фичи: `vault status` + hardening).
2. **Конкурент-фичи** (УТП «честность», спеки в Drive): Leak Audit `vault audit` (#1) +
   snapshot-detection при `destroy` (#3) — максимум impact / минимум кода.
3. **Vault #6 `create [path]` + реестр**, затем #8 `list` (фундамент под спеки A/B).
4. Хвост: F-3 (Windows mounted), F-4 (подпись кода).

Зона Mr. Di (решить в начале 03): порядок выше + развилки по #6 (позиционный arg vs реестр).

## Открытые решения, ждут Mr. Di

- Доставка weekly-intel отчёта (почта/адрес/формат) — см. память `securetrash-weekly-intel-delivery`.
- Релиз v0.4.0: когда резать (с F-2 или раньше).
- Постинг Show HN / Reddit / awesome-PR — ручной, после набора звёзд, драфты готовы.

## Инструменты на машине (локально, не синкаются)

`bats-core`, `shellcheck`, `pwsh`+Pester, `gh`(auth), `codex`, `gemini`, `ffmpeg`/`vhs` (для GIF).
