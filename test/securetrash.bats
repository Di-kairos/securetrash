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

@test "check on SSD + FileVault On gives crypto-shred verdict" {
  run env PATH="${BATS_TEST_DIRNAME}/mocks:$PATH" bash "$SCRIPT" check
  [ "$status" -eq 0 ]
  [[ "$output" == *"FileVault"* ]]
  [[ "$output" == *"SSD"* ]]
  [[ "$output" == *"vault"* ]]
}

@test "check warns loudly when FileVault is Off" {
  run env PATH="${BATS_TEST_DIRNAME}/mocks-fvoff:$PATH" bash "$SCRIPT" check
  [[ "$output" == *"FileVault is OFF"* ]] || [[ "$output" == *"FileVault is Off"* ]]
}

@test "check in Russian (ST_LANG=ru) produces Russian output" {
  run env ST_LANG=ru PATH="${BATS_TEST_DIRNAME}/mocks:$PATH" bash "$SCRIPT" check
  [ "$status" -eq 0 ]
  [[ "$output" == *"ВКЛЮЧЕН"* ]]
}

@test "setup creates the trash dir and is idempotent" {
  tmp="$(mktemp -d)"
  run env HOME="$tmp" PATH="${BATS_TEST_DIRNAME}/mocks:$PATH" \
    bash "$SCRIPT" setup
  [ "$status" -eq 0 ]
  [ -d "$tmp/SecureTrash" ]
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

@test "shred handles a filename starting with a dash (-- guard)" {
  tmp="$(mktemp -d)"; echo secret > "$tmp/-rf-test"
  run env ST_ASSUME_YES=1 PATH="${BATS_TEST_DIRNAME}/mocks:$PATH" \
    bash "$SCRIPT" shred "$tmp/-rf-test"
  [ "$status" -eq 0 ]
  [ ! -e "$tmp/-rf-test" ]
  rm -rf "$tmp"
}

@test "--yes flag bypasses confirmation like ST_ASSUME_YES" {
  tmp="$(mktemp -d)"; echo secret > "$tmp/f.txt"
  run env PATH="${BATS_TEST_DIRNAME}/mocks:$PATH" \
    bash "$SCRIPT" shred --yes "$tmp/f.txt"
  [ "$status" -eq 0 ]
  [ ! -e "$tmp/f.txt" ]
  rm -rf "$tmp"
}

@test "check on unknown disk type warns about no guarantee" {
  run env PATH="${BATS_TEST_DIRNAME}/mocks-unknown:$PATH" bash "$SCRIPT" check
  [ "$status" -eq 0 ]
  [[ "$output" == *"could not be determined"* ]] || [[ "$output" == *"determine the disk type"* ]]
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
  tmp="$(mktemp -d)"; touch "$tmp/SecureVault.sparsebundle"
  run env HOME="$tmp" ST_ASSUME_YES=1 \
    PATH="${BATS_TEST_DIRNAME}/mocks:$PATH" \
    bash "$SCRIPT" vault destroy
  [ "$status" -eq 0 ]
  [ ! -e "$tmp/SecureVault.sparsebundle" ]
  rm -rf "$tmp"
}
