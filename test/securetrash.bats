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
