#!/usr/bin/env bash
# Устанавливает securetrash в /usr/local/bin с проверкой целостности.
#
# Тянет бинарь и SHA256SUMS из РЕЛИЗНОГО тега (не из ветки main) и проверяет
# хеш ДО установки. Закрывает supply-chain риск «curl|bash из main без проверки»:
# содержимое релизного тега неизменно (в отличие от подвижной main), а хеш ловит
# повреждение, частичную/кэш-подмену и рассинхрон бинаря с публикацией.
# ЧЕСТНО: сумма и бинарь приходят по одному каналу — от подмены САМОГО релиза
# (переписаны оба) это не защищает; для подлинности нужна подпись (F-4) / Homebrew.
#
# Использование (рекомендуется verify-then-run, см. README):
#   curl -fsSLO https://github.com/Di-kairos/securetrash/releases/latest/download/install.sh
#   curl -fsSLO https://github.com/Di-kairos/securetrash/releases/latest/download/SHA256SUMS
#   shasum -a 256 -c SHA256SUMS --ignore-missing   # проверить сам install.sh
#   less install.sh                                  # прочитать глазами
#   bash install.sh
#
# Переменные окружения:
#   ST_VERSION   — поставить конкретный тег (напр. 0.4.0). По умолчанию latest.
#   ST_BASE_URL  — переопределить источник целиком (для форков/тестов).
#   ST_DEST      — путь установки. По умолчанию /usr/local/bin/securetrash.
set -euo pipefail

if [[ "$(uname -s)" != "Darwin" ]]; then
  echo "securetrash работает только на macOS." >&2; exit 1
fi

REPO="Di-kairos/securetrash"
# Источник: явный ST_BASE_URL → конкретный тег ST_VERSION → latest-релиз.
if [[ -n "${ST_BASE_URL:-}" ]]; then
  BASE_URL="$ST_BASE_URL"
elif [[ -n "${ST_VERSION:-}" ]]; then
  BASE_URL="https://github.com/${REPO}/releases/download/v${ST_VERSION}"
else
  BASE_URL="https://github.com/${REPO}/releases/latest/download"
fi
DEST="${ST_DEST:-/usr/local/bin/securetrash}"

# Временный каталог под загрузку; чистим в любом случае.
TMP="$(mktemp -d)"
trap 'rm -rf "$TMP"' EXIT

echo "Скачиваю securetrash и SHA256SUMS из релиза..."
curl -fsSL "${BASE_URL}/securetrash" -o "${TMP}/securetrash"
curl -fsSL "${BASE_URL}/SHA256SUMS" -o "${TMP}/SHA256SUMS"

# Проверка целостности ДО chmod +x. --ignore-missing: в SHA256SUMS есть и
# Windows-скрипт, которого тут нет, — проверяем только присутствующий файл.
echo "Проверяю контрольную сумму..."
if ! ( cd "$TMP" && shasum -a 256 -c SHA256SUMS --ignore-missing ); then
  echo "✗ Контрольная сумма НЕ совпала — установка прервана (возможна подмена)." >&2
  exit 1
fi

# --- Проверка ПОДПИСИ релиза (аутентичность поверх целостности) ---
# Релизы подписаны выделенным ed25519-ключом (ssh-keygen -Y). Pubkey вшит ниже —
# меняется только при ротации ключа. Мягкая деградация (НЕ ломает установку):
#   * pubkey ещё не выдан (пусто) ИЛИ нет ssh-keygen → молча пропускаем;
#   * у релиза нет .sig (старый/неподписанный) → честное замечание, идём дальше
#     (целостность по SHA256 уже подтверждена выше);
#   * .sig есть и НЕ сошёлся → жёсткий отказ (явный признак подмены).
RELEASE_SIGNING_PUBKEY=""   # ssh-ed25519 AAAA... (заполнить при выдаче ключа)
SIGN_PRINCIPAL="releases@paranoid-tools"
if [[ -n "$RELEASE_SIGNING_PUBKEY" ]] && command -v ssh-keygen >/dev/null 2>&1; then
  if curl -fsSL "${BASE_URL}/SHA256SUMS.sig" -o "${TMP}/SHA256SUMS.sig" 2>/dev/null; then
    printf '%s namespaces="file" %s\n' "$SIGN_PRINCIPAL" "$RELEASE_SIGNING_PUBKEY" > "${TMP}/allowed_signers"
    echo "Проверяю подпись релиза..."
    if ( cd "$TMP" && ssh-keygen -Y verify -f allowed_signers -I "$SIGN_PRINCIPAL" \
                        -n file -s SHA256SUMS.sig < SHA256SUMS >/dev/null 2>&1 ); then
      echo "✓ Подпись релиза верна (аутентичность подтверждена)."
    else
      echo "✗ Подпись релиза НЕ прошла проверку — установка прервана (возможна подмена)." >&2
      exit 1
    fi
  else
    echo "! Подпись для этого релиза недоступна — пропускаю (целостность по SHA256 проверена)."
  fi
fi

# Хеш верный → устанавливаем. Под несписываемый каталог — через sudo.
echo "Устанавливаю в ${DEST}..."
if [[ -w "$(dirname "$DEST")" ]]; then
  install -m 0755 "${TMP}/securetrash" "$DEST"
else
  sudo install -m 0755 "${TMP}/securetrash" "$DEST"
fi

echo "Установлено: $DEST"
echo "Дальше: securetrash setup && securetrash check"
