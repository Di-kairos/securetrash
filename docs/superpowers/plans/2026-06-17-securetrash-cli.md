# SecureTrash CLI Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Build an honest, working macOS secure-deletion CLI (`securetrash`) that audits the environment, manages a SecureTrash drop-folder, best-effort shreds files, and provides a real crypto-shred via encrypted sparsebundle vaults.

**Architecture:** Single auditable Bash script with a subcommand dispatcher. Shared helpers (color output, confirmation, disk-type detection) live at the top; each subcommand is one function with a single responsibility. Logic that needs unit testing is split into small pure-ish helper functions so `bats` can call them with mocked `diskutil`/`fdesetup` on `PATH`.

**Tech Stack:** Bash (macOS 10.15+), native tools (`fdesetup`, `hdiutil`, `diskutil`, `rm`), `bats-core` + `shellcheck` for tests/lint, Homebrew formula + `curl|bash` installer for distribution.

---

## File Structure

```
securetrash                  # main executable script (subcommand dispatcher + helpers)
install.sh                   # curl | bash installer (copies script to /usr/local/bin)
Formula/securetrash.rb       # Homebrew formula
README.md                    # honest pitch, quickstart, command table, FAQ, badges
LICENSE                      # MIT
docs/GUIDE.md                # corrected version of the original SecureTrash guide
test/securetrash.bats        # bats tests (arg parsing, dispatch, check verdict, non-macOS)
test/mocks/                  # mock diskutil/fdesetup binaries for tests
.github/workflows/ci.yml     # shellcheck + bats on macos-latest
```

**Testability design:** The script defines functions then, at the very bottom, runs the
dispatcher **only when executed directly** (`[[ "${BASH_SOURCE[0]}" == "${0}" ]]`). When
`bats` does `source securetrash`, the dispatcher does NOT auto-run, so individual
functions can be tested in isolation. Disk/FileVault detection always calls external
binaries (`diskutil`, `fdesetup`) by bare name, so tests inject mocks via `PATH`.

---

### Task 1: Scaffold script skeleton + sourcing guard + dispatcher

**Files:**
- Create: `securetrash`
- Test: `test/securetrash.bats`

- [ ] **Step 1: Write the failing test**

```bash
# test/securetrash.bats
setup() {
  SCRIPT="${BATS_TEST_DIRNAME}/../securetrash"
}

@test "sourcing the script does not run the dispatcher" {
  run bash -c "source '$SCRIPT'; echo SOURCED_OK"
  [ "$status" -eq 0 ]
  [[ "$output" == *"SOURCED_OK"* ]]
  [[ "$output" != *"Usage:"* ]]
}

@test "no args prints usage and exits non-zero" {
  run bash "$SCRIPT"
  [ "$status" -ne 0 ]
  [[ "$output" == *"Usage:"* ]]
}

@test "unknown subcommand exits non-zero with error" {
  run bash "$SCRIPT" bogus
  [ "$status" -ne 0 ]
  [[ "$output" == *"Unknown command"* ]]
}
```

- [ ] **Step 2: Run test to verify it fails**

Run: `bats test/securetrash.bats -f "sourcing|usage|Unknown"`
Expected: FAIL — `securetrash` does not exist.

- [ ] **Step 3: Write minimal implementation**

```bash
#!/usr/bin/env bash
# securetrash — честное безопасное удаление файлов на macOS.
set -euo pipefail

VERSION="0.1.0"

usage() {
  cat <<'EOF'
Usage: securetrash <command> [args]

Commands:
  check                       Аудит окружения и честный вердикт о гарантиях
  setup                       Создать ~/SecureTrash, alias, проверить FileVault
  empty                       Опустошить ~/SecureTrash
  shred <path>...             Безопасно удалить файл/папку
  vault create|open|close|destroy   Зашифрованный контейнер (crypto-shred)
  version                     Показать версию
EOF
}

cmd_version() { echo "securetrash $VERSION"; }

main() {
  local cmd="${1:-}"
  if [[ -z "$cmd" ]]; then usage; exit 1; fi
  shift || true
  case "$cmd" in
    version) cmd_version "$@" ;;
    *) echo "Unknown command: $cmd" >&2; usage >&2; exit 1 ;;
  esac
}

if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
  main "$@"
fi
```

- [ ] **Step 4: Run test to verify it passes**

Run: `bats test/securetrash.bats -f "sourcing|usage|Unknown"`
Expected: PASS (3 tests).

- [ ] **Step 5: Commit**

```bash
chmod +x securetrash
git add securetrash test/securetrash.bats
git commit -m "feat: scaffold securetrash dispatcher with sourcing guard"
```

---

### Task 2: Shared helpers — output, confirmation, disk detection

**Files:**
- Modify: `securetrash` (add helpers after `VERSION=`)
- Modify: `test/securetrash.bats`
- Create: `test/mocks/diskutil`, `test/mocks/fdesetup`

- [ ] **Step 1: Write the failing test**

```bash
# append to test/securetrash.bats

@test "is_ssd returns true when diskutil reports SSD Yes" {
  run env PATH="${BATS_TEST_DIRNAME}/mocks:$PATH" \
    bash -c "source '$SCRIPT'; is_ssd / && echo SSD || echo NOTSSD"
  [ "$status" -eq 0 ]
  [[ "$output" == *"SSD"* ]]
}

@test "filevault_on returns true when fdesetup says On" {
  run env PATH="${BATS_TEST_DIRNAME}/mocks:$PATH" \
    bash -c "source '$SCRIPT'; filevault_on && echo FV_ON || echo FV_OFF"
  [[ "$output" == *"FV_ON"* ]]
}
```

Create mock `test/mocks/diskutil` (chmod +x):

```bash
#!/usr/bin/env bash
# mock: reports an SSD on APFS
echo "   Solid State:               Yes"
echo "   File System Personality:   APFS"
```

Create mock `test/mocks/fdesetup` (chmod +x):

```bash
#!/usr/bin/env bash
echo "FileVault is On."
```

- [ ] **Step 2: Run test to verify it fails**

Run: `bats test/securetrash.bats -f "is_ssd|filevault_on"`
Expected: FAIL — `is_ssd`/`filevault_on` not defined.

- [ ] **Step 3: Write minimal implementation**

Add after `VERSION="0.1.0"` in `securetrash`:

```bash
# --- output helpers ---
if [[ -t 1 ]]; then
  C_RED=$'\033[31m'; C_GRN=$'\033[32m'; C_YEL=$'\033[33m'; C_RST=$'\033[0m'
else
  C_RED=""; C_GRN=""; C_YEL=""; C_RST=""
fi
info()  { echo "${C_GRN}✓${C_RST} $*"; }
warn()  { echo "${C_YEL}!${C_RST} $*" >&2; }
err()   { echo "${C_RED}✗${C_RST} $*" >&2; }

# Спросить подтверждение. --yes в args обходит вопрос.
confirm() {
  local prompt="$1"
  if [[ "${ST_ASSUME_YES:-0}" == "1" ]]; then return 0; fi
  read -r -p "$prompt [введите yes]: " ans
  [[ "$ans" == "yes" ]]
}

# --- platform detection ---
# Диск под путём — SSD? (diskutil info: "Solid State: Yes")
is_ssd() {
  local path="${1:-/}"
  diskutil info "$path" 2>/dev/null | grep -qi "Solid State:.*Yes"
}

# FileVault включён? (fdesetup status: "FileVault is On.")
filevault_on() {
  fdesetup status 2>/dev/null | grep -qi "FileVault is On"
}

require_macos() {
  if [[ "$(uname -s)" != "Darwin" ]]; then
    err "securetrash работает только на macOS."
    exit 1
  fi
}
```

- [ ] **Step 4: Run test to verify it passes**

Run: `chmod +x test/mocks/* && bats test/securetrash.bats -f "is_ssd|filevault_on"`
Expected: PASS.

- [ ] **Step 5: Commit**

```bash
git add securetrash test/securetrash.bats test/mocks
git commit -m "feat: add output, confirm, and platform-detection helpers"
```

---

### Task 3: `check` — honest environment audit

**Files:**
- Modify: `securetrash` (add `cmd_check`, wire into dispatcher)
- Modify: `test/securetrash.bats`
- Create: `test/mocks/fdesetup_off`, `test/mocks/diskutil_hdd` (alt mocks)

- [ ] **Step 1: Write the failing test**

```bash
# append to test/securetrash.bats

@test "check on SSD + FileVault On gives crypto-shred verdict" {
  run env PATH="${BATS_TEST_DIRNAME}/mocks:$PATH" bash "$SCRIPT" check
  [ "$status" -eq 0 ]
  [[ "$output" == *"FileVault"* ]]
  [[ "$output" == *"SSD"* ]]
  [[ "$output" == *"vault"* ]]
}

@test "check warns loudly when FileVault is Off" {
  run env PATH="${BATS_TEST_DIRNAME}/mocks-fvoff:$PATH" bash "$SCRIPT" check
  [[ "$output" == *"FileVault ВЫКЛЮЧЕН"* ]] || [[ "$output" == *"FileVault is Off"* ]]
}
```

Create `test/mocks-fvoff/fdesetup` (chmod +x):

```bash
#!/usr/bin/env bash
echo "FileVault is Off."
```

Create `test/mocks-fvoff/diskutil` (chmod +x) — same SSD output as the SSD mock:

```bash
#!/usr/bin/env bash
echo "   Solid State:               Yes"
echo "   File System Personality:   APFS"
```

- [ ] **Step 2: Run test to verify it fails**

Run: `bats test/securetrash.bats -f "check"`
Expected: FAIL — `check` is an unknown command.

- [ ] **Step 3: Write minimal implementation**

Add `cmd_check` function:

```bash
cmd_check() {
  require_macos
  echo "=== SecureTrash: аудит окружения ==="

  if filevault_on; then
    info "FileVault: ВКЛЮЧЕН — диск зашифрован, базовая защита есть."
  else
    warn "FileVault ВЫКЛЮЧЕН — главная защита отсутствует! Включи: System Settings → Privacy & Security → FileVault."
  fi

  if is_ssd /; then
    echo "  Диск: SSD/APFS."
    warn "Перезапись (rm -P) на SSD НЕ даёт гарантий (wear leveling, COW, TRIM)."
    info "Реальная гарантия на SSD: FileVault + crypto-shred через 'securetrash vault'."
  else
    echo "  Диск: HDD."
    info "На HDD перезапись (shred/empty) эффективна."
  fi

  echo
  echo "Итог: для секретов используй 'securetrash vault' (превентивно)."
}
```

Wire into dispatcher `case`:

```bash
    check) cmd_check "$@" ;;
```

- [ ] **Step 4: Run test to verify it passes**

Run: `chmod +x test/mocks-fvoff/* && bats test/securetrash.bats -f "check"`
Expected: PASS.

- [ ] **Step 5: Commit**

```bash
git add securetrash test/securetrash.bats test/mocks-fvoff
git commit -m "feat: add check subcommand with honest disk/FileVault verdict"
```

---

### Task 4: `setup` — create folder, alias, FileVault warning

**Files:**
- Modify: `securetrash` (add `cmd_setup`, wire dispatcher)
- Modify: `test/securetrash.bats`

- [ ] **Step 1: Write the failing test**

```bash
# append to test/securetrash.bats

@test "setup creates the trash dir and is idempotent" {
  tmp="$(mktemp -d)"
  run env HOME="$tmp" PATH="${BATS_TEST_DIRNAME}/mocks:$PATH" \
    bash "$SCRIPT" setup
  [ "$status" -eq 0 ]
  [ -d "$tmp/SecureTrash" ]
  # second run must not fail
  run env HOME="$tmp" PATH="${BATS_TEST_DIRNAME}/mocks:$PATH" \
    bash "$SCRIPT" setup
  [ "$status" -eq 0 ]
  rm -rf "$tmp"
}

@test "setup appends sectrash alias to .zshrc exactly once" {
  tmp="$(mktemp -d)"; touch "$tmp/.zshrc"
  env HOME="$tmp" PATH="${BATS_TEST_DIRNAME}/mocks:$PATH" bash "$SCRIPT" setup
  env HOME="$tmp" PATH="${BATS_TEST_DIRNAME}/mocks:$PATH" bash "$SCRIPT" setup
  count="$(grep -c "alias sectrash=" "$tmp/.zshrc")"
  [ "$count" -eq 1 ]
  rm -rf "$tmp"
}
```

- [ ] **Step 2: Run test to verify it fails**

Run: `bats test/securetrash.bats -f "setup"`
Expected: FAIL — `setup` unknown.

- [ ] **Step 3: Write minimal implementation**

```bash
TRASH_DIR="${HOME}/SecureTrash"

cmd_setup() {
  require_macos
  mkdir -p "$TRASH_DIR"
  info "Папка готова: $TRASH_DIR"

  local zshrc="${HOME}/.zshrc"
  local alias_line="alias sectrash='securetrash empty'"
  if [[ -f "$zshrc" ]] && grep -q "alias sectrash=" "$zshrc"; then
    info "alias sectrash уже установлен."
  else
    echo "$alias_line" >> "$zshrc"
    info "alias sectrash добавлен в ~/.zshrc (перезапусти терминал)."
  fi

  if ! filevault_on; then
    warn "FileVault ВЫКЛЮЧЕН — включи его, иначе удаление на SSD не даёт гарантий."
  fi
}
```

Wire dispatcher: `setup) cmd_setup "$@" ;;`

Note: `TRASH_DIR` is computed at source time from `HOME`; tests override `HOME` per run
via `env HOME=...`, so each invocation re-reads it correctly (separate `bash` process).

- [ ] **Step 4: Run test to verify it passes**

Run: `bats test/securetrash.bats -f "setup"`
Expected: PASS.

- [ ] **Step 5: Commit**

```bash
git add securetrash test/securetrash.bats
git commit -m "feat: add idempotent setup subcommand"
```

---

### Task 5: `shred` + `empty` — best-effort delete with honest output

**Files:**
- Modify: `securetrash` (add `_shred_path`, `cmd_shred`, `cmd_empty`, wire dispatcher)
- Modify: `test/securetrash.bats`

- [ ] **Step 1: Write the failing test**

```bash
# append to test/securetrash.bats

@test "shred deletes a file and reports honestly on SSD" {
  tmp="$(mktemp -d)"; echo secret > "$tmp/f.txt"
  run env ST_ASSUME_YES=1 PATH="${BATS_TEST_DIRNAME}/mocks:$PATH" \
    bash "$SCRIPT" shred "$tmp/f.txt"
  [ "$status" -eq 0 ]
  [ ! -e "$tmp/f.txt" ]
  [[ "$output" == *"FileVault"* ]]
  rm -rf "$tmp"
}

@test "shred on missing path errors" {
  run env ST_ASSUME_YES=1 PATH="${BATS_TEST_DIRNAME}/mocks:$PATH" \
    bash "$SCRIPT" shred /no/such/path
  [ "$status" -ne 0 ]
}

@test "empty clears the trash dir contents but keeps the dir" {
  tmp="$(mktemp -d)"; mkdir -p "$tmp/SecureTrash"; echo x > "$tmp/SecureTrash/a"
  run env HOME="$tmp" ST_ASSUME_YES=1 PATH="${BATS_TEST_DIRNAME}/mocks:$PATH" \
    bash "$SCRIPT" empty
  [ "$status" -eq 0 ]
  [ -d "$tmp/SecureTrash" ]
  [ -z "$(ls -A "$tmp/SecureTrash")" ]
  rm -rf "$tmp"
}
```

- [ ] **Step 2: Run test to verify it fails**

Run: `bats test/securetrash.bats -f "shred|empty"`
Expected: FAIL — commands unknown.

- [ ] **Step 3: Write minimal implementation**

```bash
# Удалить один путь: снять write-protection, перезаписать (best-effort), удалить.
_shred_path() {
  local target="$1"
  chmod -R u+w "$target" 2>/dev/null || true
  # -P: на HDD три прохода перезаписи; на SSD безвреден, но не гарантия.
  rm -rfP "$target"
}

_honest_disk_note() {
  if is_ssd /; then
    warn "SSD: перезапись не гарантия. Реальная защита — FileVault."
    if ! filevault_on; then err "И FileVault ВЫКЛЮЧЕН — данные могут быть восстановимы."; fi
  else
    info "HDD: перезапись (3 прохода) выполнена."
  fi
}

cmd_shred() {
  require_macos
  if [[ $# -eq 0 ]]; then err "shred: укажи путь."; exit 1; fi
  for t in "$@"; do
    if [[ ! -e "$t" ]]; then err "Не найдено: $t"; exit 1; fi
  done
  if ! confirm "Удалить безвозвратно $*?"; then warn "Отменено."; exit 1; fi
  for t in "$@"; do _shred_path "$t"; info "Удалено: $t"; done
  _honest_disk_note
}

cmd_empty() {
  require_macos
  if [[ ! -d "$TRASH_DIR" ]]; then err "Нет папки $TRASH_DIR (запусти 'securetrash setup')."; exit 1; fi
  if [[ -z "$(ls -A "$TRASH_DIR")" ]]; then info "Папка уже пуста."; exit 0; fi
  if ! confirm "Опустошить $TRASH_DIR безвозвратно?"; then warn "Отменено."; exit 1; fi
  chmod -R u+w "$TRASH_DIR"/* 2>/dev/null || true
  ( shopt -s dotglob nullglob; rm -rfP "$TRASH_DIR"/* )
  info "Папка опустошена: $TRASH_DIR"
  _honest_disk_note
}
```

Wire dispatcher: `shred) cmd_shred "$@" ;;` and `empty) cmd_empty "$@" ;;`

- [ ] **Step 4: Run test to verify it passes**

Run: `bats test/securetrash.bats -f "shred|empty"`
Expected: PASS.

- [ ] **Step 5: Commit**

```bash
git add securetrash test/securetrash.bats
git commit -m "feat: add shred and empty subcommands with honest disk notes"
```

---

### Task 6: `vault` — encrypted sparsebundle crypto-shred

**Files:**
- Modify: `securetrash` (add `cmd_vault`, wire dispatcher)
- Modify: `test/securetrash.bats`

- [ ] **Step 1: Write the failing test**

(Unit-test the arg routing with a mocked `hdiutil`; real container creation is covered by
the CI smoke test in Task 9, not here, to keep unit tests fast and offline.)

```bash
# append to test/securetrash.bats

@test "vault with no subcommand errors" {
  run env PATH="${BATS_TEST_DIRNAME}/mocks:$PATH" bash "$SCRIPT" vault
  [ "$status" -ne 0 ]
  [[ "$output" == *"create|open|close|destroy"* ]]
}

@test "vault create calls hdiutil create" {
  tmp="$(mktemp -d)"
  run env HOME="$tmp" ST_VAULT_PASS=test1234 \
    PATH="${BATS_TEST_DIRNAME}/mocks:$PATH" \
    bash "$SCRIPT" vault create
  [ "$status" -eq 0 ]
  [ -f "$tmp/hdiutil_calls.log" ]
  grep -q "create" "$tmp/hdiutil_calls.log"
  rm -rf "$tmp"
}

@test "vault destroy requires confirmation and removes container" {
  tmp="$(mktemp -d)"; touch "$tmp/SecureVault.sparsebundle"  # placeholder file
  # represent a sparsebundle as a file for the unit test
  run env HOME="$tmp" ST_ASSUME_YES=1 \
    PATH="${BATS_TEST_DIRNAME}/mocks:$PATH" \
    bash "$SCRIPT" vault destroy
  [ "$status" -eq 0 ]
  [ ! -e "$tmp/SecureVault.sparsebundle" ]
  rm -rf "$tmp"
}
```

Create mock `test/mocks/hdiutil` (chmod +x) — logs calls, fakes success:

```bash
#!/usr/bin/env bash
echo "$@" >> "${HOME}/hdiutil_calls.log"
# fake a successful create by making the container path if given
case "$1" in
  create)
    for a in "$@"; do last="$a"; done
    : > "$last" 2>/dev/null || true ;;
  attach|detach) : ;;
esac
exit 0
```

- [ ] **Step 2: Run test to verify it fails**

Run: `bats test/securetrash.bats -f "vault"`
Expected: FAIL — `vault` unknown.

- [ ] **Step 3: Write minimal implementation**

```bash
VAULT_PATH="${HOME}/SecureVault.sparsebundle"
VAULT_VOLUME="/Volumes/SecretVault"

# Прочитать пароль: из ST_VAULT_PASS (для тестов) или интерактивно.
_vault_pass() {
  if [[ -n "${ST_VAULT_PASS:-}" ]]; then printf '%s' "$ST_VAULT_PASS"; return; fi
  read -r -s -p "Пароль контейнера: " p; echo >&2; printf '%s' "$p"
}

cmd_vault() {
  require_macos
  local sub="${1:-}"; shift || true
  case "$sub" in
    create)
      if [[ -e "$VAULT_PATH" ]]; then err "Контейнер уже существует: $VAULT_PATH"; exit 1; fi
      local size="${1:-1g}"
      _vault_pass | hdiutil create -size "$size" -type SPARSEBUNDLE -fs APFS \
        -encryption AES-256 -stdinpass -volname SecretVault "$VAULT_PATH"
      info "Контейнер создан: $VAULT_PATH (размер $size)."
      ;;
    open)
      if [[ ! -e "$VAULT_PATH" ]]; then err "Нет контейнера. Сначала 'securetrash vault create'."; exit 1; fi
      _vault_pass | hdiutil attach "$VAULT_PATH" -stdinpass
      info "Смонтировано: $VAULT_VOLUME"
      ;;
    close)
      hdiutil detach "$VAULT_VOLUME" 2>/dev/null || { err "Не удалось размонтировать (не открыт?)."; exit 1; }
      info "Размонтировано — данные снова зашифрованы."
      ;;
    destroy)
      if [[ ! -e "$VAULT_PATH" ]]; then err "Нет контейнера: $VAULT_PATH"; exit 1; fi
      if ! confirm "УНИЧТОЖИТЬ контейнер и всё внутри ($VAULT_PATH)?"; then warn "Отменено."; exit 1; fi
      hdiutil detach "$VAULT_VOLUME" 2>/dev/null || true
      rm -rfP "$VAULT_PATH"
      info "Контейнер уничтожен (crypto-shred). Данные неизвлекаемы без ключа."
      ;;
    *)
      err "vault: укажи create|open|close|destroy"; exit 1 ;;
  esac
}
```

Wire dispatcher: `vault) cmd_vault "$@" ;;`

- [ ] **Step 4: Run test to verify it passes**

Run: `chmod +x test/mocks/hdiutil && bats test/securetrash.bats -f "vault"`
Expected: PASS.

- [ ] **Step 5: Commit**

```bash
git add securetrash test/securetrash.bats test/mocks/hdiutil
git commit -m "feat: add vault subcommand for encrypted-container crypto-shred"
```

---

### Task 7: Full test suite green + shellcheck clean

**Files:**
- Modify: `securetrash` (fix any shellcheck findings)

- [ ] **Step 1: Run the whole suite**

Run: `bats test/securetrash.bats`
Expected: all tests PASS.

- [ ] **Step 2: Run shellcheck**

Run: `shellcheck securetrash install.sh 2>/dev/null || shellcheck securetrash`
Expected: no errors. Fix any (quote expansions, `local` separate from assignment where
return code matters). Re-run until clean.

- [ ] **Step 3: Commit**

```bash
git add securetrash
git commit -m "fix: resolve shellcheck findings"
```

---

### Task 8: `install.sh` + Homebrew formula

**Files:**
- Create: `install.sh`
- Create: `Formula/securetrash.rb`

- [ ] **Step 1: Write `install.sh`**

```bash
#!/usr/bin/env bash
# Устанавливает securetrash в /usr/local/bin. Использование:
#   curl -fsSL https://raw.githubusercontent.com/Di-kairos/securetrash/main/install.sh | bash
set -euo pipefail

if [[ "$(uname -s)" != "Darwin" ]]; then
  echo "securetrash работает только на macOS." >&2; exit 1
fi

REPO_RAW="https://raw.githubusercontent.com/Di-kairos/securetrash/main/securetrash"
DEST="/usr/local/bin/securetrash"

echo "Скачиваю securetrash..."
if [[ -w "$(dirname "$DEST")" ]]; then
  curl -fsSL "$REPO_RAW" -o "$DEST"
  chmod +x "$DEST"
else
  curl -fsSL "$REPO_RAW" | sudo tee "$DEST" >/dev/null
  sudo chmod +x "$DEST"
fi

echo "Установлено: $DEST"
echo "Дальше: securetrash setup && securetrash check"
```

- [ ] **Step 2: Verify install.sh parses and lints**

Run: `bash -n install.sh && shellcheck install.sh`
Expected: no output / no errors.

- [ ] **Step 3: Write `Formula/securetrash.rb`**

```ruby
class Securetrash < Formula
  desc "Honest secure file deletion for macOS (FileVault + crypto-shred vaults)"
  homepage "https://github.com/Di-kairos/securetrash"
  url "https://github.com/Di-kairos/securetrash/archive/refs/tags/v0.1.0.tar.gz"
  # sha256 заполняется после создания релиз-тега: shasum -a 256 <tarball>
  sha256 "REPLACE_AFTER_TAG"
  license "MIT"

  def install
    bin.install "securetrash"
  end

  test do
    assert_match "securetrash", shell_output("#{bin}/securetrash version")
  end
end
```

Note: `sha256` stays `REPLACE_AFTER_TAG` until the v0.1.0 tag exists; the publish step
(post-plan) fills it. The formula is committed now so the tap structure is ready.

- [ ] **Step 4: Commit**

```bash
chmod +x install.sh
git add install.sh Formula/securetrash.rb
git commit -m "feat: add curl installer and Homebrew formula"
```

---

### Task 9: CI workflow (shellcheck + bats + vault smoke)

**Files:**
- Create: `.github/workflows/ci.yml`

- [ ] **Step 1: Write the workflow**

```yaml
name: ci
on: [push, pull_request]
jobs:
  test:
    runs-on: macos-latest
    steps:
      - uses: actions/checkout@v4
      - name: Install tools
        run: brew install bats-core shellcheck
      - name: Lint
        run: shellcheck securetrash install.sh
      - name: Unit tests
        run: bats test/securetrash.bats
      - name: Vault smoke test (real hdiutil)
        run: |
          export ST_VAULT_PASS=ci-test-pass ST_ASSUME_YES=1
          ./securetrash vault create 10m
          ./securetrash vault open
          echo secret > /Volumes/SecretVault/s.txt
          ./securetrash vault close
          ./securetrash vault destroy
          test ! -e "$HOME/SecureVault.sparsebundle"
```

- [ ] **Step 2: Verify YAML is valid**

Run: `python3 -c "import yaml,sys; yaml.safe_load(open('.github/workflows/ci.yml'))" && echo OK`
Expected: `OK`.

- [ ] **Step 3: Commit**

```bash
git add .github/workflows/ci.yml
git commit -m "ci: shellcheck, bats, and vault smoke test on macOS"
```

---

### Task 10: README, LICENSE, corrected guide

**Files:**
- Create: `README.md`
- Create: `LICENSE`
- Create: `docs/GUIDE.md`

- [ ] **Step 1: Write `LICENSE`** (MIT, holder "Mr. Di", year 2026). Use the standard MIT text.

- [ ] **Step 2: Write `README.md`**

Must include, in order:
1. Title + one-line honest pitch + badges (CI status, license, macOS, shellcheck).
2. **The problem** — Trash doesn't erase; recoverable with Disk Drill/PhotoRec.
3. **The honest truth box** — `rm -P` does NOT guarantee erasure on SSD/APFS
   (wear leveling, COW, TRIM); Apple removed `srm`/Secure Empty Trash in 10.11.
4. **What actually protects you** — FileVault (base) + crypto-shred vault (per-secret).
5. **Install** — Homebrew one-liner + curl one-liner.
6. **Quickstart** — `setup` → `check` → drop files → `empty`; and vault workflow.
7. **Command table** (check/setup/empty/shred/vault).
8. **FAQ** — "Can files be recovered after shred?", "Why a vault instead of overwrite?",
   "Does this work without FileVault?", "Is it safe to run destroy?".
9. **How it works** — short crypto-shred explanation.
10. **Disclaimer** — no warranty; verify FileVault; vault is preventive.

- [ ] **Step 3: Write `docs/GUIDE.md`** — the original SecureTrash walkthrough, corrected:
   keep the friendly drop-folder workflow, but replace the false "практически невозможно
   восстановить через rm -P" claims with the honest SSD caveat and point to FileVault +
   `vault` as the real guarantees.

- [ ] **Step 4: Verify links/formatting**

Run: `grep -n "Di-kairos/securetrash" README.md install.sh Formula/securetrash.rb`
Expected: repo slug consistent across all files.

- [ ] **Step 5: Commit**

```bash
git add README.md LICENSE docs/GUIDE.md
git commit -m "docs: add README, LICENSE, and corrected guide"
```

---

### Task 11: Publish (manual gate — requires confirmation)

**Files:** none (GitHub operations)

> Pushing to a new public repo is outward-facing — confirm with Mr. Di before running.
> `gh` is already authenticated (verified this session).

- [ ] **Step 1: Create the public repo + push**

```bash
gh repo create Di-kairos/securetrash --public --source=. --remote=origin --push
```

- [ ] **Step 2: Tag the release and fill the formula sha256**

```bash
git tag v0.1.0 && git push origin v0.1.0
# затем: скачать tarball, shasum -a 256, вписать в Formula/securetrash.rb, commit+push
```

- [ ] **Step 3: Verify CI is green** on the pushed commit (`gh run watch`).

---

## Self-Review

**Spec coverage:**
- check → Task 3 ✓
- setup → Task 4 ✓
- empty → Task 5 ✓
- shred → Task 5 ✓
- vault create/open/close/destroy → Task 6 ✓
- Honest SSD/HDD behavior → Tasks 3, 5 ✓
- Pure Bash + native tools → all tasks ✓
- bats + shellcheck → Tasks 1-7, 9 ✓
- Homebrew + curl install → Task 8 ✓
- README/LICENSE/docs → Task 10 ✓
- Repo structure → File Structure section ✓
- Success criteria 1-5 → check (T3), vault smoke (T9), shellcheck (T7), README (T10), install (T8) ✓

**Placeholder scan:** `REPLACE_AFTER_TAG` in the formula is intentional and documented
(filled at publish/Task 11), not a plan gap. No other placeholders.

**Type/name consistency:** Helper names consistent across tasks — `is_ssd`,
`filevault_on`, `require_macos`, `confirm`, `info/warn/err`, `_shred_path`,
`_honest_disk_note`, `_vault_pass`, `cmd_*`. `TRASH_DIR`, `VAULT_PATH`, `VAULT_VOLUME`
defined once, reused. Mock dirs `test/mocks`, `test/mocks-fvoff` consistent. Env overrides
`ST_ASSUME_YES`, `ST_VAULT_PASS` used consistently.
