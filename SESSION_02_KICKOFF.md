# Session 02 — kickoff

## Что читать первым

1. `PROGRESS.md` (frontmatter: head, tests, status, next_actions).
2. `progress-report-session01.md` (полный итог сессии 01).
3. `DECISIONS.md` — нет (решения пока в progress-report; завести при росте).

## Состояние на старте

- Проект: **securetrash** · ветка `main` · HEAD `dbef755` · теги v0.1.0/v0.2.0/**v0.3.0**.
- Тесты: bats 19/19 + Pester 35/35, shellcheck clean. CI зелёный (macOS + windows-latest).
- Опубликовано: https://github.com/Di-kairos/securetrash + tap https://github.com/Di-kairos/homebrew-tap.
- `brew install Di-kairos/tap/securetrash` → 0.3.0 (проверено вживую).

## Фокус сессии 02 — РАСКРУТКА

Порядок (рекомендация):
1. **GitHub Release v0.3.0** с changelog — `gh release create v0.3.0` (Claude готовит notes).
2. **Черновики постов:** Show HN (заголовок про SSD-миф) + Reddit (r/privacy / r/macapps / r/commandline, разный тон). Claude пишет → **Mr. Di постит сам**.
3. **Блог-пост** «Why overwriting files doesn't work on SSDs» (EN+RU) → ссылка на репо.
4. **Awesome-list PR'ы** (awesome-macos, awesome-cli-apps, awesome-privacy, awesome-security).
5. `CONTRIBUTING.md` + issue-templates (вкл. «Windows hardware tester wanted» — закроет beta-гэп).
6. **GitHub Pages лендинг** — поднять `ui-ux-pro-max` + MCP `magic`, собрать страницу (хук: SSD-миф, демо-GIF, install one-liner, ссылки), задеплоить на Pages, вписать URL в поле **website** репо (`gh repo edit --homepage`).

Нарратив-хук: продавать разоблачение мифа («`rm -P` врёт про SSD»), не «ещё один шреддер».
Предупреждение: outward-facing постинг — только Mr. Di; не накручивать звёзды/не спамить.

## Технические v2-деферы (если зайдёт раскрутка / появится Windows-машина)

- Снять Windows BETA: валидация BitLocker/VHDX на реальном железе.
- `New-VHD` вместо diskpart; `hdiutil -plist` device-tracking; отдельный data-key crypto-shred.

## Инструменты на машине (ставятся локально, не синкаются)

- `bats-core`, `shellcheck`, `pwsh`+Pester, `vhs`(+ttyd/ffmpeg), `gh`(auth: repo+workflow), `codex`, `gemini`.
