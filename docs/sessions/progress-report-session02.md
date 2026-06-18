# Session 02 — progress report

Дата: 2026-06-18 · ветка `main` · HEAD на момент закрытия `9ee7e18` (последний код-коммит `1e9470d`).
Тесты: **bats 31/31 + Pester 35/35**, shellcheck clean. Тема сессии: раскрутка + hardening.

## Сделано

### Раскрутка / контент
- **GitHub Release v0.3.0** (latest, с changelog ~2.5k симв).
- **Лендинг GitHub Pages** live: https://olma777.github.io/securetrash/ — Dark OLED + JetBrains Mono
  (ui-ux-pro-max), SSD-myth хук, myth-vs-reality git-diff, crypto-shred шаги, demo-GIF, install,
  copy-кнопки. homepage репо выставлен. Шрифты **self-hosted** (F-5).
- **Блог EN+RU** «Why overwriting files doesn't work on SSDs» (`docs/blog/`), **Codex-fact-checked**
  (NIST SP 800-88r2, UCSD FAST'11): поправлены ATA Sanitize vs Secure Erase, TRIM-имена (DRAT/RZAT),
  crypto-shred условия, over-provisioning, page/erase sizes.
- **Драфты постов** (`docs/promo/session02-launch-posts.md`): Show HN + r/commandline + r/privacy + r/macapps.
- **Awesome-list PR-kit** (`docs/promo/session02-awesome-list-prs.md`): слать после >20★.
- **Детальный план запуска** (`docs/promo/launch-plan.md`): календарь, тайминги, правила площадок.
- CONTRIBUTING.md + issue-forms (вкл. **Windows hardware test report**) + config + PR-template + **SECURITY.md**.
- Перенёс session/handoff-файлы из корня в `docs/sessions/` (чистота публичного репо; остаются tracked).

### Hardening (code review + аудиты, всё Codex-reviewed)
- `vault status`; `vault open` guard от двойного attach + `-mountpoint -nobrowse` (нет volname-коллизии).
- **dev-node detach** (close/destroy/status) вместо угадывания по точке монтирования.
- **shred-blacklist**: canonicalize финального компонента (ловит `/etc/hosts`→`/private/etc`,
  symlink+trailing-slash), case-insensitive (APFS), user-temp + `/usr/local` разрешены.
- destroy валидирует sparsebundle перед rm.
- **F-1 fail-closed (финал, commit 1e9470d):** `_vault_state` tri-state (mounted/unmounted/unknown);
  destroy НЕ удаляет при mounted (detach или abort) и при unknown (fail-closed); postcondition
  re-check перед rm (detach-verify + TOCTOU). Это закрыло killer-сценарий для HN-аудита.
- Codex поймал: CRITICAL `/etc/*` bypass, HIGH symlink/slash, HIGH fail-open detection — всё закрыто тестами.

### Инфра / планирование
- Спеки в Google Drive (папка SecureTrash): **Leak Audit** + **backup-snapshot-detection**.
- Routine **weekly-intel** (`trig_01RMdr8wqi1CqHCBEVH92Zgx`, пн→Drive) — активна.
- Routine **HN warm-up** (`trig_01VBoWsx57CkFXd7daVNMAYm`) — создана и **отключена** (карма-фарм отвергнут).
- Roadmap-секция в PROGRESS (backlog + приоритеты фич + pre-launch focus).

## В процессе / решено по стратегии
- **Разворот стратегии запуска:** греть продукт+честную историю, не карму аккаунта (фидбэк Mr. Di).
  Назвать слабости первым в Show HN = сила. Warm-up routine выключена.
- **Принцип фич:** углублять тезис, не раздувать. НЕ: GUI/cloud/35-pass/бэкап-менеджер/телеметрия.

## Осталось (детали — Roadmap в PROGRESS.md)
- **Pre-launch:** F-2 checksum-install (главный HN-триггер) → вычитка блога → Show HN текст → опц. `verify`.
- Решить: F-2 пакетом с релизом v0.4.0 или без bump.
- Развилка #1: Leak Audit как `vault audit` vs влить в `check` (ждёт ОК Mr. Di).
- F-3 (Windows mounted), F-4 (подпись), vault #6/#8, конкурент-фичи (#1 Leak Audit и т.д.),
  password-entropy, auto-dismount, Linux LUKS2 (widen).
- Ручное (Mr. Di): постинг по календарю после прогрева аккаунта (своим голосом); awesome-PR после >20★;
  доставка weekly-intel (адрес/формат).

## Ключевые решения сессии
- dev-node/tri-state детекция vault вместо mountpoint-угадывания (надёжность + fail-closed).
- destroy fail-closed: безопаснее оставить контейнер, чем удалить при неясном/смонтированном состоянии.
- Лендинг из `/docs` на `main` (не отдельная ветка) + `.nojekyll`.
- Карма-прогрев отвергнут в пользу продуктовой готовности.
