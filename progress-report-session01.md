# Session 01 — progress report

Дата: 2026-06-17/18
Проект: securetrash · ветка main · HEAD `dbef755` · теги v0.1.0 / v0.2.0 / **v0.3.0**

## Что сделано

Полный цикл с нуля → публичный продукт:

- **macOS CLI** (`securetrash`, bash, ноль зависимостей): `check / setup / empty / shred / vault {create,open,close,destroy} / version`. i18n: English по умолчанию, `ST_LANG=ru`.
- **Windows-порт** (`windows/securetrash.ps1`, PowerShell, **BETA**): зеркало macOS, BitLocker-VHDX native + честный отказ/GUI для VeraCrypt.
- **Дистрибуция:** Homebrew tap `Di-kairos/homebrew-tap` (`brew install Di-kairos/tap/securetrash` — проверено), `install.sh` (curl), `windows/install.ps1` (irm).
- **CI:** GitHub Actions — macOS (shellcheck + bats + реальный hdiutil vault smoke) + windows-latest (Pester). Зелёный.
- **Доки:** EN-first `README.md` + `README.ru.md`, `docs/GUIDE.md(.ru)`, демо-GIF (VHS, реальный vault-цикл), LICENSE MIT.
- **About** на GitHub: description + 13 topics.

## Три мозга → security hardening (v0.3.0)

Codex (GPT-5.5, xhigh) adversarial review: 5 Critical / 7 High / 3 Medium. Исправлено:
- Убраны ложные гарантии (#1,#5,#11,#12): «unrecoverable»/«overwrite effective» → честно «зависит от пароля + отсутствия копий»; раздел Scope & limitations.
- Утечка пароля (#2): VeraCrypt-пароль убран из argv (GUI-промпт). macOS уже чист (`-stdinpass`).
- Деструктив-guards (#3,#6,#7): `rm/chmod --`, `-LiteralPath`, diskpart-валидация + exit-коды, free drive letter.
- Windows функц-баги (#9,#10): `open` → `Unlock-BitLocker` + verify; backend трекается через sidecar.
- Hardening (#13,#14,#15): SecureString end-to-end, флаг `--yes`, 0700/ACL.

Тесты: bats 16→**19/19**, Pester 12→**35/35**, shellcheck clean. Ревью-вывод: `tri-mozga-out/2026-06-17-securetrash/codex-review.md`.

## В процессе / решено по ходу

- CLI язык: English default + `ST_LANG=ru` (решение Mr. Di — «удобно любому юзеру»).
- Windows vault: native BitLocker + VeraCrypt fallback (решение Mr. Di).

## Что осталось (next session — раскрутка + v2-деферы)

**Раскрутка (фокус след. сессии):**
1. GitHub Release на v0.3.0 с changelog (`gh release create`).
2. Черновики Show HN + Reddit (r/privacy, r/macapps, r/commandline).
3. Блог-пост «SSD secure-delete myth» (EN+RU).
4. Awesome-list PR'ы (awesome-macos, awesome-cli-apps, awesome-privacy, awesome-security).
5. `CONTRIBUTING.md` + issue-templates (вкл. «Windows hardware tester wanted»).
   ВАЖНО: HN/Reddit/PR постит Mr. Di сам (outward-facing), Claude только черновики. Не спамить.

**Технические деферы (TODO в коде, v2):**
- Windows: валидация BitLocker/VHDX на реальном железе (снять BETA).
- `New-VHD`/`Mount-DiskImage` вместо diskpart (#3 long-term).
- macOS: `hdiutil -plist` device-tracking при detach (#8).
- Отдельный random data-key для crypto-shred (#12 глубокий вариант).
- Автоматический VeraCrypt без argv-пароля (#2).

## Ключевые решения

- Чистый Bash / PowerShell, ноль рантайм-зависимостей — security-инструмент должен читаться глазами.
- `vault destroy` через `rm -rf` (не `-P`): контейнер — шифрошум.
- Честность > маркетинг: формулировки намеренно не переобещают (это и есть УТП).
