#!/usr/bin/env bash
set -euo pipefail

REPO_RAW_URL="https://raw.githubusercontent.com/fishman132yangbo/frontend-migrate-agent/main/bin/frontend-migrate"
INSTALL_DIR="${INSTALL_DIR:-$HOME/.local/bin}"
INSTALL_PATH="$INSTALL_DIR/frontend-migrate"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

mkdir -p "$INSTALL_DIR"

if [[ -f "$SCRIPT_DIR/bin/frontend-migrate" ]]; then
  install -m 755 "$SCRIPT_DIR/bin/frontend-migrate" "$INSTALL_PATH"
else
  if ! command -v curl >/dev/null 2>&1; then
    printf '错误: 未找到 curl，无法下载安装文件。\n' >&2
    exit 1
  fi
  curl -fsSL "$REPO_RAW_URL" -o "$INSTALL_PATH"
  chmod +x "$INSTALL_PATH"
fi

printf '已安装: %s\n' "$INSTALL_PATH"

case ":$PATH:" in
  *":$INSTALL_DIR:"*) ;;
  *)
    printf '提示: %s 当前不在 PATH 中。\n' "$INSTALL_DIR"
    printf '可以把下面这行加入你的 shell 配置文件:\n'
    printf 'export PATH="$HOME/.local/bin:$PATH"\n'
    ;;
esac
