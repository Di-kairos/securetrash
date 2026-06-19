# Progress report — session 04 (2026-06-19)

## Главный итог
Сессия 04 закрыла vaultwatch полностью и довела panic до релиза, плюс заложила
ghostdraft. **Два новых инструмента экосистемы released и PUBLIC**, оба с проверенной
end-to-end дистрибуцией. Третий (ghostdraft) — scaffold готов, private WIP.

| Инструмент | Репо | HEAD | Тег | Статус | Тесты |
|---|---|---|---|---|---|
| securetrash | Di-kairos/securetrash | `ebb2ae2` (код) | v0.4.0 | released | bats 55/55 + Pester 38/38 |
| vaultwatch | Di-kairos/vaultwatch **public** | `1c27e51` | v0.1.0 (на `76cb076`) | released | bats 46/46 |
| panic | Di-kairos/panic **public** | `df1d64a` | v0.1.0 | released | bats 20/20 |
| ghostdraft | Di-kairos/ghostdraft (private) | `2997acc` | — | scaffold | bats 9/9 |
| umbrella | Di-kairos/paranoid-tools | `b000fb6` | — | — | — |

CI зелёный во всех репо. Vendoring пиннут к securetrash `2e3d2dd` + SHA256 везде.

## Сделано

### vaultwatch — доведён до v0.1.0 RELEASED (public)
- **Pack 3b** (`start`/`stop` ядро): запоминает прежнее состояние Spotlight → `mdutil -i off`;
  `tmutil addexclusion` только если ещё не исключён; эвристический cloud-detect
  (Dropbox/OneDrive/iCloud/Google Drive — процесс + inside/outside синк-папки);
  per-mount session-state. `stop` восстанавливает РОВНО изменённое + session report
  (duration/Spotlight/TM/cloud/local snapshots/честный swap).
- **Pack 3c** (`--ttl`): парсер длительности s/m/h/d; авто-detach по истечении
  (`lsof`-чек → `hdiutil detach`; busy → честный warn; `--force` с confirm).
- **Pack 3d** (launchd): `--ttl` через LaunchAgent (RunAtLoad+sleep one-shot → `_ttl_fire`),
  виден в `launchctl list`, `stop`/`_ttl_fire` делают bootout+rm plist. plist plutil-clean.
- **Release**: install.sh (checksum-verified) + release.yml + CHANGELOG; репо public; тег v0.1.0.
- **Real-device smoke** (macOS): start/stop/--ttl на живом sparsebundle, launchd
  bootstrap/bootout цикл, install.sh из живого релиза → checksum OK → бинарь работает.
- **Lint-фикс** `1c27e51`: SC2015 (`A && B || C` → if-form) — CI-shellcheck (apt, старее)
  ловил, локальный 0.11 пропускал. NB: тег v0.1.0 на `76cb076` (до фикса) — поведение
  идентично; lint уедет в v0.1.1.

### panic — с нуля до v0.1.0 RELEASED (public)
- **Pack 1 scaffold**, **Pack 2 `now`** (detach всех `/Volumes` disk image'ов через
  `hdiutil detach -force`; mountpoints TAB-парсятся из `hdiutil info`, пробелы-safe;
  system-образы вне /Volumes не трогаются → `pbcopy </dev/null` → `CGSession -suspend` lock,
  override `PANIC_CGSESSION`). Без confirm (явный verb `now` = защита).
- **Pack 3 `--hard`**: `pkill -x` cloud-демонов + clear глобальных Recent items
  (shared file lists в `PANIC_SFL_DIR`). Честно: per-app recents не покрываются.
- **Release**: install.sh/release.yml/CHANGELOG; public; тег v0.1.0; end-to-end install проверен.
- Real-device smoke: `now` распарсил живой `hdiutil info` + detach тест-образа.

### ghostdraft — Pack 1 scaffold
- Новый репо (private), single-file + вендоренный common, dispatcher version/help +
  new/pipe deferred(exit2). Честная рамка в header/README (no «zero traces»).

## Ключевые решения
- **PATH-стабы для macOS-тулзов** (uname→Darwin, hdiutil/tmutil/mdutil/pgrep/lsof/
  launchctl/pbcopy/pkill) → тесты гоняются на Linux-CI без реальных команд.
- **Explicit verbs для опасных действий**: `panic now` (не bare `panic`) — анти-случайный триггер.
- **launchd one-shot** = RunAtLoad+sleep (без calendar-математики, портируемо для тестов).
- **Публикация репо — только по явному go пользователя** (auto-mode classifier
  заблокировал авто-flip panic; подтвердил «go panic release»).
- **Находка vaultwatch**: disk-image тома macOS по дефолту TM-excluded + Spotlight off →
  `addexclusion`/`mdutil -i off` часто no-op для sparsebundle-vault. vaultwatch честно репортит.

## Открыто / блокеры
- Блокеров НЕТ. Все CI зелёные.
- vaultwatch v0.1.1 pending: lint-фикс (`1c27e51`) + Homebrew tap; опц. re-cut тега.
- panic: Homebrew tap formula pending.

## Дальше — ghostdraft Pack 2 (ядро new/pipe)
См. PROGRESS.md next_actions[0] + SESSION_05_KICKOFF.md. Самый деликатный по честности
пак: RAM-диск (`hdiutil ram://`) vs APFS-tmp, editor-следы (vim .swp/.un~/viminfo,
nano, VSCode), `--clipboard` off-by-default. swap/scrollback не покрываем — честно.
