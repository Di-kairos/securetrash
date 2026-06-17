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
