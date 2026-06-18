# Тесты целостности install.sh: проверяет, что установщик ставит бинарь только
# при совпадении SHA256 и fail-closed отказывается при подмене.
setup() {
  INSTALL="${BATS_TEST_DIRNAME}/../install.sh"
  WORK="$(mktemp -d)"
  FIX="${WORK}/release"        # «релиз»: securetrash + SHA256SUMS
  DEST="${WORK}/bin/securetrash"
  mkdir -p "$FIX" "${WORK}/bin"
  # Полезная нагрузка-заглушка.
  printf '#!/usr/bin/env bash\necho payload-ok\n' > "${FIX}/securetrash"
  ( cd "$FIX" && shasum -a 256 securetrash > SHA256SUMS )
}

teardown() {
  rm -rf "$WORK"
}

@test "install.sh installs binary when checksum matches" {
  run env ST_BASE_URL="file://${FIX}" ST_DEST="$DEST" bash "$INSTALL"
  [ "$status" -eq 0 ]
  [ -x "$DEST" ]
  run "$DEST"
  [[ "$output" == *"payload-ok"* ]]
}

@test "install.sh fails closed on checksum mismatch" {
  # Подменяем бинарь ПОСЛЕ генерации SHA256SUMS — хеш больше не сходится.
  printf '#!/usr/bin/env bash\necho TAMPERED\n' > "${FIX}/securetrash"
  run env ST_BASE_URL="file://${FIX}" ST_DEST="$DEST" bash "$INSTALL"
  [ "$status" -ne 0 ]
  [ ! -e "$DEST" ]
}

@test "install.sh aborts when SHA256SUMS is unavailable" {
  rm -f "${FIX}/SHA256SUMS"
  run env ST_BASE_URL="file://${FIX}" ST_DEST="$DEST" bash "$INSTALL"
  [ "$status" -ne 0 ]
  [ ! -e "$DEST" ]
}
