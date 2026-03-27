#!/bin/bash
# ============================================================
# 🦞 auto-installer: 5 层智能搜索脚本
# 用法: bash auto-install-search.sh <关键词或报错信息>
# ============================================================
set -euo pipefail

QUERY="${1:?用法: bash auto-install-search.sh <关键词>}"
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
BOLD='\033[1m'
NC='\033[0m'

FOUND=0
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
MAP_FILE="${SCRIPT_DIR}/../references/task-tool-map.md"

echo ""
echo -e "${BOLD}${CYAN}╔══════════════════════════════════════════════════╗${NC}"
echo -e "${BOLD}${CYAN}║  🦞 Auto-Installer 5 层智能搜索                 ║${NC}"
echo -e "${BOLD}${CYAN}╚══════════════════════════════════════════════════╝${NC}"
echo -e "  ${YELLOW}关键词: ${BOLD}${QUERY}${NC}"
echo ""

# ── 第 1 层: 查固定映射表 ────────────────────────────
echo -e "${GREEN}${BOLD}━━━ 第 1 层: 固定映射表 ━━━${NC}"
if [ -f "$MAP_FILE" ]; then
    HITS=$(grep -i "$QUERY" "$MAP_FILE" 2>/dev/null | head -10 || true)
    if [ -n "$HITS" ]; then
        echo "$HITS"
        FOUND=1
        echo -e "  ${GREEN}✓ 映射表命中！${NC}"
    else
        echo -e "  ${YELLOW}○ 未命中，进入下一层...${NC}"
    fi
else
    echo -e "  ${YELLOW}○ 映射表文件不存在，跳过${NC}"
fi

# ── 第 2 层: 搜索 apt ────────────────────────────────
echo ""
echo -e "${BLUE}${BOLD}━━━ 第 2 层: 系统包 (apt) ━━━${NC}"
if command -v apt &>/dev/null; then
    APT_HITS=$(apt search "$QUERY" 2>/dev/null | head -15 || true)
    if [ -n "$APT_HITS" ]; then
        echo "$APT_HITS"
        FOUND=1
    else
        echo -e "  ${YELLOW}○ apt 未找到相关包${NC}"
    fi
else
    echo -e "  ${YELLOW}○ apt 不可用${NC}"
fi

# ── 第 3 层: 搜索 pip ────────────────────────────────
echo ""
echo -e "${BLUE}${BOLD}━━━ 第 3 层: Python 包 (pip) ━━━${NC}"
if command -v pip3 &>/dev/null; then
    PIP_HITS=$(pip3 index versions "$QUERY" 2>/dev/null | head -5 || true)
    if [ -z "$PIP_HITS" ]; then
        PIP_HITS=$(pip3 search "$QUERY" 2>/dev/null | head -10 || true)
    fi
    if [ -n "$PIP_HITS" ]; then
        echo "$PIP_HITS"
        FOUND=1
    else
        echo -e "  ${YELLOW}○ pip 未找到相关包${NC}"
    fi
else
    echo -e "  ${YELLOW}○ pip3 不可用${NC}"
fi

# ── 第 4 层: 搜索 npm ────────────────────────────────
echo ""
echo -e "${BLUE}${BOLD}━━━ 第 4 层: Node 模块 (npm) ━━━${NC}"
if command -v npm &>/dev/null; then
    NPM_HITS=$(npm search "$QUERY" 2>/dev/null | head -10 || true)
    if [ -n "$NPM_HITS" ]; then
        echo "$NPM_HITS"
        FOUND=1
    else
        echo -e "  ${YELLOW}○ npm 未找到相关模块${NC}"
    fi
else
    echo -e "  ${YELLOW}○ npm 不可用${NC}"
fi

# ── 第 5 层: 搜索 ClawHub ────────────────────────────
echo ""
echo -e "${BLUE}${BOLD}━━━ 第 5 层: ClawHub 技能 ━━━${NC}"
if command -v npx &>/dev/null; then
    CLAWHUB_HITS=$(npx clawhub search "$QUERY" 2>/dev/null | head -10 || true)
    if [ -n "$CLAWHUB_HITS" ]; then
        echo "$CLAWHUB_HITS"
        FOUND=1
    else
        echo -e "  ${YELLOW}○ ClawHub 未找到相关技能${NC}"
    fi
else
    echo -e "  ${YELLOW}○ npx 不可用${NC}"
fi

# ── 结果汇总 ─────────────────────────────────────────
echo ""
echo -e "${BOLD}${CYAN}╔══════════════════════════════════════════════════╗${NC}"
if [ $FOUND -eq 1 ]; then
    echo -e "${BOLD}${CYAN}║${NC}  ${GREEN}${BOLD}✓ 找到结果，请 agent 分析并选择安装。${NC}       ${BOLD}${CYAN}║${NC}"
else
    echo -e "${BOLD}${CYAN}║${NC}  ${YELLOW}${BOLD}⚠ 本地搜索无结果${NC}                              ${BOLD}${CYAN}║${NC}"
    echo -e "${BOLD}${CYAN}║${NC}  ${YELLOW}建议 agent 用 mimo_web_search 联网搜索:${NC}      ${BOLD}${CYAN}║${NC}"
    echo -e "${BOLD}${CYAN}║${NC}  ${CYAN}'${QUERY} install ubuntu'${NC}                    ${BOLD}${CYAN}║${NC}"
    echo -e "${BOLD}${CYAN}║${NC}  ${CYAN}'${QUERY} linux alternative'${NC}                  ${BOLD}${CYAN}║${NC}"
fi
echo -e "${BOLD}${CYAN}╚══════════════════════════════════════════════════╝${NC}"
echo ""
