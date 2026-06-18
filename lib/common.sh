# shellcheck shell=bash
# common.sh — переиспользуемые примитивы экосистемы Paranoid Tools.
#
# Канонический источник: securetrash/lib/common.sh. Инструменты экосистемы
# (vaultwatch/panic/ghostdraft) вендорят его inline между маркерами
# (см. CLAUDE.md «Vendoring»). Файл sourceable и идемпотентен (двойной source/inline
# безопасны — guard через if-обёртку, без top-level return, поэтому корректен и когда
# блок вставлен в исполняемый скрипт).
#
# Даёт tool-агностичные примитивы: локаль (ST_LOCALE), цветной вывод (info/warn/err),
# подтверждение (confirm), детект платформы macOS (require_macos/is_ssd/_disk_kind/
# filevault_on), канонизацию пути (_abspath). Своя i18n-таблица — у каждого инструмента.
#
# ВЕНДОРИНГ — зарезервированные имена (не переопределять в host-скрипте): функции
# info warn err confirm require_macos is_ssd _disk_kind filevault_on _abspath
# _st_detect_locale; переменные ST_LOCALE C_RED C_GRN C_YEL C_RST _ST_COMMON_LOADED.

# Идемпотентность через if-обёртку (а не top-level return): безопасно при source,
# исполнении и inline-вставке. Определения функций внутри if регистрируются глобально.
if [[ -z "${_ST_COMMON_LOADED:-}" ]]; then
  _ST_COMMON_LOADED=1

  # --- locale ---
  # en по умолчанию; ru — если ST_LANG или системная локаль начинаются с 'ru'.
  _st_detect_locale() {
    local want="${ST_LANG:-}"
    if [[ -n "$want" ]]; then
      case "$want" in ru*) echo ru ;; *) echo en ;; esac
      return
    fi
    local sys="${LC_ALL:-${LANG:-}}"
    case "$sys" in ru*) echo ru ;; *) echo en ;; esac
  }
  # Уважаем заранее выставленный ST_LOCALE (host может переопределить).
  ST_LOCALE="${ST_LOCALE:-$(_st_detect_locale)}"

  # --- output ---
  # Цвет только в TTY (в пайпах/файлах — без ANSI).
  if [[ -t 1 ]]; then
    C_RED=$'\033[31m'; C_GRN=$'\033[32m'; C_YEL=$'\033[33m'; C_RST=$'\033[0m'
  else
    C_RED=""; C_GRN=""; C_YEL=""; C_RST=""
  fi
  info() { echo "${C_GRN}✓${C_RST} $*"; }
  warn() { echo "${C_YEL}!${C_RST} $*" >&2; }
  err()  { echo "${C_RED}✗${C_RST} $*" >&2; }

  # --- confirm ---
  # Подтверждение необратимой операции. ST_ASSUME_YES=1 обходит вопрос (скрипты/тесты).
  # Возвращает 0 только при точном вводе 'yes' (EOF/пусто → отказ, fail-closed).
  # Суффикс намеренно продублирован из i18n securetrash (lib без таблицы строк).
  confirm() {
    local prompt="$1" ans suffix
    [[ "${ST_ASSUME_YES:-0}" == "1" ]] && return 0
    case "$ST_LOCALE" in ru) suffix="[введите yes]" ;; *) suffix="[type yes]" ;; esac
    read -r -p "$prompt $suffix: " ans
    [[ "$ans" == "yes" ]]
  }

  # --- platform (macOS) ---
  require_macos() {
    if [[ "$(uname -s)" != "Darwin" ]]; then
      case "$ST_LOCALE" in
        ru) err "работает только на macOS." ;;
        *)  err "runs on macOS only." ;;
      esac
      exit 1
    fi
  }

  # Диск под путём — SSD? (diskutil info: "Solid State: Yes")
  is_ssd() {
    local path="${1:-/}"
    diskutil info "$path" 2>/dev/null | grep -qi "Solid State:.*Yes"
  }

  # Тип диска: ssd | hdd | unknown. Честность важнее догадок: неизвестный тип
  # НЕ приравниваем к hdd-эффективному (нет поля "Solid State" → unknown).
  _disk_kind() {
    local path="${1:-/}" out
    out="$(diskutil info "$path" 2>/dev/null)"
    if grep -qi "Solid State:.*Yes" <<<"$out"; then echo ssd
    elif grep -qi "Solid State:.*No" <<<"$out"; then echo hdd
    else echo unknown; fi
  }

  # FileVault включён? (fdesetup status: "FileVault is On.")
  filevault_on() {
    fdesetup status 2>/dev/null | grep -qi "FileVault is On"
  }

  # --- path ---
  # Физический канонический путь: режет trailing-slash, резолвит .. и симлинки,
  # ВКЛЮЧАЯ финальный компонент. Непустая строка или код !=0, если путь недоступен.
  _abspath() {
    local p="$1"
    while [[ "$p" == */ && "$p" != "/" ]]; do p="${p%/}"; done
    if [[ -d "$p" ]]; then
      ( cd -P -- "$p" 2>/dev/null && pwd -P ); return
    fi
    local d b
    d="$(cd -P -- "$(dirname -- "$p")" 2>/dev/null && pwd -P)" || return 1
    b="$(basename -- "$p")"
    printf '%s/%s' "${d%/}" "$b"
  }
fi
