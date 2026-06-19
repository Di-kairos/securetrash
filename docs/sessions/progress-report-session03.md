# Progress report — session 03 (2026-06-19)

## Главный итог
securetrash v0.4.0 **зарелижен**, стартовала **экосистема Paranoid Tools**.

## Сделано

### securetrash (репо Di-kairos/securetrash)
- **F-2 checksum-install** (`490f646`): install.sh/install.ps1 тянут бинарь+SHA256SUMS
  с релизного тега, проверка хеша до установки, fail-closed; `release.yml` на тег v*;
  README verify-then-run + Homebrew основным; bump **v0.4.0**.
- **Тег v0.4.0 запушен** → release.yml собрал ассеты; `latest/download` smoke OK;
  Homebrew tap обновлён (sha256 `0c526772`).
- **Pack #1 vault-хуки** (`d0cbf99`): `vault open/close` дёргают post-open/post-close
  из `~/.securetrash/hooks` — точка интеграции для vaultwatch. Хук-падение не роняет vault.
- **Pack #2 lib/common.sh** (`2e3d2dd`): канонический вендоринг-источник примитивов
  (locale/output/confirm/platform/_abspath), if-guard vendor-safe, 14 bats.
- Добавлены `ECOSYSTEM.md` (north-star) + проектный `CLAUDE.md` (стек/нав/skill-routing/
  vendoring/hooks).
- Тесты: **bats 55/55 + Pester 38/38, shellcheck clean.** HEAD `ebb2ae2`.

### Структура / экосистема
- Реорг: `projects/paranoid-tools/{securetrash, vaultwatch}` + umbrella git-репо
  (Di-kairos/paranoid-tools, private). README-карта + `bin/rebuild-graph.sh`.
- Память мигрирована на X10 + симлинк под новым слагом (§4 починен; раньше была
  не-синкаемая папка в ~/.claude).
- Граф: securetrash (403n/500e) + vaultwatch (11n/12e) → cross-repo merged
  **414n/512e** (`paranoid-tools/graphify-out/merged-graph.json`).

### vaultwatch (репо Di-kairos/vaultwatch, private) — Pack 3a (`1c9b4c6`)
- Scaffold + **verified vendoring**: пин = full SHA `2e3d2dd…` + **SHA256 content-hash**
  `fdfb0e3c…`; `tools/vendor-common.sh --check` ловит дрейф, отличает сетевой сбой (exit 3)
  от рассинхрона (exit 1).
- **install-hooks/uninstall-hooks**: не затирает чужие хуки, путь экранирован `printf %q`.
- start/stop отложены в 3b (exit 2, граница запинена тестом). **bats 14/14, shellcheck clean.**

## Правила (в памяти X10)
- Три-мозга (Claude+Codex+Gemini) обязательны для всех проверок экосистемы.
- North-star = ECOSYSTEM.md. SECURITY_AUDIT.md НЕ использовать.

## Открыто / блокеры
- **GitHub Actions CI заблокирован биллингом** (сломанный способ оплаты на файле; текущий
  счёт $0). Фикс — обновить карту в Settings → Billing → Payment information. Не код.
- vaultwatch CI не зеленел из-за этого (код проверен локально + три-мозга).

## Дальше — vaultwatch Pack 3b
Ядро сторожа: `start <mnt>`/`stop` + `mdutil -i off`/restore + `tmutil addexclusion`/remove +
проверка уже снятых снапшотов. TDD + три-мозга. Затем 3c (cloud-detect+report), 3d (--ttl/launchd),
3e (README Scope&limitations + checksum-install + release.yml).
