# Тесты канонической библиотеки lib/common.sh (источник вендоринга экосистемы).
setup() {
  LIB="${BATS_TEST_DIRNAME}/../lib/common.sh"
}

@test "common.sh sources cleanly and is idempotent" {
  run bash -c "source '$LIB'; source '$LIB'; echo OK"
  [ "$status" -eq 0 ]
  [[ "$output" == *"OK"* ]]
}

@test "info/warn/err format with markers" {
  run bash -c "source '$LIB'; info hi; warn wa; err er" 2>&1
  [[ "$output" == *"hi"* ]]
  [[ "$output" == *"wa"* ]]
  [[ "$output" == *"er"* ]]
}

@test "locale defaults to en, ru via ST_LANG" {
  run bash -c "unset ST_LANG LC_ALL LANG; source '$LIB'; echo \$ST_LOCALE"
  [[ "$output" == *"en"* ]]
  run bash -c "ST_LANG=ru_RU source '$LIB'; echo \$ST_LOCALE"
  [[ "$output" == *"ru"* ]]
}

@test "confirm passes with ST_ASSUME_YES" {
  run bash -c "ST_ASSUME_YES=1 bash -c 'source \"$LIB\"; confirm prompt && echo YES'"
  [ "$status" -eq 0 ]
  [[ "$output" == *"YES"* ]]
}

@test "confirm accepts exactly yes, rejects others" {
  run bash -c "source '$LIB'; echo yes | confirm q && echo PASS"
  [[ "$output" == *"PASS"* ]]
  run bash -c "source '$LIB'; echo no | confirm q && echo PASS || echo FAIL"
  [[ "$output" == *"FAIL"* ]]
}

@test "is_ssd true when diskutil reports SSD Yes (mocked)" {
  run env PATH="${BATS_TEST_DIRNAME}/mocks:$PATH" \
    bash -c "source '$LIB'; is_ssd / && echo SSD || echo NOT"
  [[ "$output" == *"SSD"* ]]
}

@test "_disk_kind returns ssd/hdd/unknown" {
  run env PATH="${BATS_TEST_DIRNAME}/mocks:$PATH" \
    bash -c "source '$LIB'; _disk_kind /"
  [[ "$output" == *"ssd"* ]]
  run env PATH="${BATS_TEST_DIRNAME}/mocks-unknown:$PATH" \
    bash -c "source '$LIB'; _disk_kind /"
  [[ "$output" == *"unknown"* ]]
}

@test "filevault_on reflects fdesetup (mocked)" {
  run env PATH="${BATS_TEST_DIRNAME}/mocks:$PATH" \
    bash -c "source '$LIB'; filevault_on && echo ON || echo OFF"
  [[ "$output" == *"ON"* ]]
  run env PATH="${BATS_TEST_DIRNAME}/mocks-fvoff:$PATH" \
    bash -c "source '$LIB'; filevault_on && echo ON || echo OFF"
  [[ "$output" == *"OFF"* ]]
}

@test "_abspath canonicalizes trailing slash and symlinks" {
  tmp="$(mktemp -d)"; mkdir -p "$tmp/real"; ln -s "$tmp/real" "$tmp/link"
  run bash -c "source '$LIB'; _abspath '$tmp/link/'"
  [[ "$output" == *"/real"* ]]
  rm -rf "$tmp"
}

@test "_disk_kind returns hdd on spinning disk (mocked)" {
  run env PATH="${BATS_TEST_DIRNAME}/mocks-hdd:$PATH" \
    bash -c "source '$LIB'; _disk_kind /"
  [[ "$output" == *"hdd"* ]]
}

@test "require_macos passes on Darwin, exits on non-macOS" {
  run bash -c "source '$LIB'; require_macos && echo PASS"
  [ "$status" -eq 0 ]
  [[ "$output" == *"PASS"* ]]
  run env PATH="${BATS_TEST_DIRNAME}/mocks-linux:$PATH" \
    bash -c "source '$LIB'; require_macos; echo SHOULD_NOT_PRINT"
  [ "$status" -ne 0 ]
  [[ "$output" != *"SHOULD_NOT_PRINT"* ]]
  [[ "$output" == *"macOS"* ]]
}

@test "guard prevents function redefinition on re-source" {
  run bash -c "source '$LIB'; info() { echo SENTINEL; }; source '$LIB'; info x"
  [[ "$output" == *"SENTINEL"* ]]
}

@test "locale falls back to system LANG when ST_LANG unset" {
  run bash -c "unset ST_LANG LC_ALL; LANG=ru_RU.UTF-8 bash -c 'source \"$LIB\"; echo \$ST_LOCALE'"
  [[ "$output" == *"ru"* ]]
}

@test "confirm rejects on EOF (fail-closed)" {
  run bash -c "source '$LIB'; confirm q </dev/null && echo PASS || echo REJECT"
  [[ "$output" == *"REJECT"* ]]
}
