#!/bin/bash
# ============================================================
# 🦞 auto-installer v3.0 — Bash 薄入口
# 核心逻辑在 auto-installer.py
# ============================================================
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"

# 优先使用 Python3
if command -v python3 &>/dev/null; then
    exec python3 "${SCRIPT_DIR}/auto-installer.py" "$@"
elif command -v python &>/dev/null; then
    exec python "${SCRIPT_DIR}/auto-installer.py" "$@"
else
    echo -e "\033[0;31m❌ 需要 Python 3.7+ 来运行 auto-installer v3.0\033[0m"
    echo -e "\033[2m  尝试: apt install python3 / dnf install python3 / brew install python3\033[0m"
    exit 1
fi
