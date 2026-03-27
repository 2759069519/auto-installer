#!/bin/bash
# ============================================================
# 🦞 auto-installer: 5 层智能搜索 + 降级链安装脚本
# 用法:
#   bash auto-install-search.sh <关键词>           # 仅搜索
#   bash auto-install-search.sh <关键词> --install  # 搜索并自动安装
# ============================================================
set -euo pipefail

QUERY="${1:?用法: bash auto-install-search.sh <关键词> [--install]}"
DO_INSTALL="${2:-}"
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
RED='\033[0;31m'
BOLD='\033[1m'
NC='\033[0m'

MAP_FOUND=0
APT_FOUND=0
PIP_FOUND=0
NPM_FOUND=0
SNAP_FOUND=0
CLAWHUB_FOUND=0
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
MAP_FILE="${SCRIPT_DIR}/../references/task-tool-map.md"

# ── 工具函数 ─────────────────────────────────────────

# 检测是否在国内网络
is_china_network() {
    ! curl -s --connect-timeout 3 https://www.google.com >/dev/null 2>&1
}

# GitHub 镜像加速 URL
github_mirror_url() {
    local url="$1"
    if is_china_network; then
        echo "https://ghfast.top/${url}"
    else
        echo "$url"
    fi
}

# pip 清华镜像参数
pip_mirror_flag() {
    if is_china_network; then
        echo "-i https://pypi.tuna.tsinghua.edu.cn/simple"
    else
        echo ""
    fi
}

# 验证命令是否真正可用
verify_cmd() {
    local cmd="$1"
    if command -v "$cmd" &>/dev/null; then
        local version=$("$cmd" --version 2>/dev/null | head -1 || echo "installed")
        echo -e "  ${GREEN}${BOLD}✅ 安装成功: ${cmd} — ${version}${NC}"
        return 0
    else
        echo -e "  ${RED}${BOLD}❌ 安装后验证失败: ${cmd} 不存在${NC}"
        return 1
    fi
}

# ── 降级链安装函数 ────────────────────────────────────

install_from_chain() {
    local chain="$1"
    local cmd_name="$2"

    echo ""
    echo -e "${BOLD}${CYAN}🔧 执行安装降级链: ${chain}${NC}"
    echo ""

    IFS='→' read -ra STEPS <<< "$chain"
    for step in "${STEPS[@]}"; do
        step=$(echo "$step" | xargs | tr -d '`')  # trim + strip backticks
        local method=$(echo "$step" | awk '{print $1}')
        local pkg=$(echo "$step" | awk '{$1=""; print $0}' | xargs)

        echo -e "${BLUE}  尝试: ${method} ${pkg}...${NC}"

        case "$method" in
            apt)
                if apt install -y $pkg 2>/dev/null; then
                    verify_cmd "$cmd_name" && return 0
                fi
                echo -e "  ${YELLOW}  ✗ apt 失败${NC}"
                ;;
            snap)
                if snap install $pkg 2>/dev/null; then
                    verify_cmd "$cmd_name" && return 0
                fi
                echo -e "  ${YELLOW}  ✗ snap 失败${NC}"
                ;;
            pip)
                local mirror=$(pip_mirror_flag)
                if pip3 install --break-system-packages $mirror $pkg 2>/dev/null; then
                    echo -e "  ${GREEN}  ✓ pip 安装成功${NC}"
                    return 0
                fi
                echo -e "  ${YELLOW}  ✗ pip 失败${NC}"
                ;;
            npm)
                if npm install -g $pkg 2>/dev/null; then
                    verify_cmd "$cmd_name" && return 0
                fi
                echo -e "  ${YELLOW}  ✗ npm 失败${NC}"
                ;;
            dl|download)
                echo -e "  ${YELLOW}  ⚡ 需要手动下载: ${pkg}${NC}"
                echo -e "  ${CYAN}  镜像URL: $(github_mirror_url "https://github.com/${pkg}")${NC}"
                ;;
            src|source)
                echo -e "  ${YELLOW}  ⚡ 需要源码编译: ${pkg}${NC}"
                ;;
            go)
                if command -v go &>/dev/null; then
                    go install "${pkg}@latest" 2>/dev/null && echo -e "  ${GREEN}  ✓ go install 成功${NC}" && return 0
                fi
                echo -e "  ${YELLOW}  ✗ go 不可用${NC}"
                ;;
            pipx)
                if command -v pipx &>/dev/null; then
                    pipx install $pkg 2>/dev/null && verify_cmd "$cmd_name" && return 0
                fi
                echo -e "  ${YELLOW}  ✗ pipx 不可用${NC}"
                ;;
            *)
                echo -e "  ${YELLOW}  ✗ 未知安装方式: ${method}${NC}"
                ;;
        esac
    done

    echo -e "  ${RED}${BOLD}❌ 所有安装方式均失败${NC}"
    return 1
}

# ── 主界面 ───────────────────────────────────────────

echo ""
echo -e "${BOLD}${CYAN}╔══════════════════════════════════════════════════════╗${NC}"
echo -e "${BOLD}${CYAN}║  🦞 Auto-Installer 5 层智能搜索                     ║${NC}"
echo -e "${BOLD}${CYAN}╚══════════════════════════════════════════════════════╝${NC}"
echo -e "  ${YELLOW}关键词: ${BOLD}${QUERY}${NC}"
if [ -n "$DO_INSTALL" ]; then
    echo -e "  ${GREEN}模式: 搜索 + 自动安装${NC}"
else
    echo -e "  ${CYAN}模式: 仅搜索（加 --install 自动安装）${NC}"
fi

# 检测网络环境
if is_china_network; then
    echo -e "  ${YELLOW}网络: 检测到国内环境，将使用镜像加速${NC}"
fi
echo ""

# ── 第 1 层: 查固定映射表 ────────────────────────────
echo -e "${GREEN}${BOLD}━━━ 第 1 层: 固定映射表 ━━━${NC}"
MATCHED_CHAIN=""
MATCHED_CMD=""

if [ -f "$MAP_FILE" ]; then
    # 精确匹配：找包含工具名的行
    HITS=$(grep -i "| \`.*${QUERY}" "$MAP_FILE" 2>/dev/null | head -5 || true)
    if [ -z "$HITS" ]; then
        # 宽松匹配
        HITS=$(grep -i "$QUERY" "$MAP_FILE" 2>/dev/null | grep "^|" | head -5 || true)
    fi

    if [ -n "$HITS" ]; then
        echo "$HITS"
        MAP_FOUND=1

        # 提取降级链（第4列）和工具名（第3列），去掉反引号
        MATCHED_CHAIN=$(echo "$HITS" | head -1 | awk -F'|' '{print $4}' | xargs | tr -d '`')
        MATCHED_CMD=$(echo "$HITS" | head -1 | awk -F'|' '{print $3}' | xargs | tr -d '`')

        echo -e "  ${GREEN}${BOLD}✓ 映射表命中！${NC}"
        if [ -n "$MATCHED_CHAIN" ]; then
            echo -e "  ${GREEN}降级链: ${MATCHED_CHAIN}${NC}"
        fi
    else
        echo -e "  ${YELLOW}○ 未命中，进入下一层...${NC}"
    fi
else
    echo -e "  ${RED}○ 映射表文件不存在${NC}"
fi

# ── 第 2 层: 搜索 apt ────────────────────────────────
echo ""
echo -e "${BLUE}${BOLD}━━━ 第 2 层: 系统包 (apt/snap) ━━━${NC}"
if command -v apt &>/dev/null; then
    APT_HITS=$(timeout 10 apt search "$QUERY" 2>/dev/null | grep -v "^Sorting\|^Full Text\|^WARNING" | grep -i "$QUERY" | head -5 || true)
    if [ -n "$APT_HITS" ]; then
        echo "$APT_HITS"
        APT_FOUND=1
    else
        echo -e "  ${YELLOW}○ apt 未找到${NC}"
    fi
fi

if command -v snap &>/dev/null; then
    SNAP_HITS=$(timeout 10 snap find "$QUERY" 2>/dev/null | head -5 || true)
    if [ -n "$SNAP_HITS" ] && ! echo "$SNAP_HITS" | grep -q "No matching snaps"; then
        echo -e "${CYAN}  snap 结果:${NC}"
        echo "$SNAP_HITS"
        SNAP_FOUND=1
    fi
fi

# ── 第 3 层: 搜索 pip/npm ───────────────────────────
echo ""
echo -e "${BLUE}${BOLD}━━━ 第 3 层: Python / Node 包 ━━━${NC}"
if command -v pip3 &>/dev/null; then
    PIP_HITS=$(timeout 10 pip3 index versions "$QUERY" 2>/dev/null | head -3 || true)
    if [ -n "$PIP_HITS" ]; then
        echo "pip: $PIP_HITS"
        PIP_FOUND=1
    fi
fi

if command -v npm &>/dev/null; then
    NPM_HITS=$(timeout 10 npm search "$QUERY" 2>/dev/null | head -3 || true)
    if [ -n "$NPM_HITS" ] && ! echo "$NPM_HITS" | grep -qi "no matches"; then
        echo "npm: $NPM_HITS"
        NPM_FOUND=1
    fi
fi

if [ "$PIP_FOUND" -eq 0 ] && [ "$NPM_FOUND" -eq 0 ]; then
    echo -e "  ${YELLOW}○ pip/npm 均未找到${NC}"
fi

# ── 第 4 层: ClawHub ─────────────────────────────────
echo ""
echo -e "${BLUE}${BOLD}━━━ 第 4 层: ClawHub 技能 ━━━${NC}"
if command -v npx &>/dev/null; then
    CLAWHUB_HITS=$(timeout 15 npx clawhub search "$QUERY" 2>/dev/null | head -5 || true)
    if [ -n "$CLAWHUB_HITS" ]; then
        echo "$CLAWHUB_HITS"
        CLAWHUB_FOUND=1
    else
        echo -e "  ${YELLOW}○ ClawHub 未找到${NC}"
    fi
else
    echo -e "  ${YELLOW}○ npx 不可用${NC}"
fi

# ── 结果汇总 ─────────────────────────────────────────
echo ""
echo -e "${BOLD}${CYAN}╔══════════════════════════════════════════════════════╗${NC}"

if [ "$MAP_FOUND" -eq 1 ]; then
    echo -e "${BOLD}${CYAN}║${NC}  ${GREEN}${BOLD}✅ 高置信：映射表命中${NC}                            ${BOLD}${CYAN}║${NC}"
    if [ -n "$MATCHED_CHAIN" ]; then
        echo -e "${BOLD}${CYAN}║${NC}  ${GREEN}降级链: ${MATCHED_CHAIN}${NC}"
    fi

    # 自动安装
    if [ "$DO_INSTALL" = "--install" ] && [ -n "$MATCHED_CMD" ] && [ -n "$MATCHED_CHAIN" ]; then
        echo -e "${BOLD}${CYAN}║${NC}  ${GREEN}正在自动安装...${NC}                                  ${BOLD}${CYAN}║${NC}"
        echo -e "${BOLD}${CYAN}╚══════════════════════════════════════════════════════╝${NC}"
        install_from_chain "$MATCHED_CHAIN" "$MATCHED_CMD"
    else
        echo -e "${BOLD}${CYAN}╚══════════════════════════════════════════════════════╝${NC}"
    fi

elif [ "$APT_FOUND" -eq 1 ] || [ "$PIP_FOUND" -eq 1 ] || [ "$NPM_FOUND" -eq 1 ] || [ "$SNAP_FOUND" -eq 1 ]; then
    echo -e "${BOLD}${CYAN}║${NC}  ${YELLOW}${BOLD}⚡ 中置信：包管理器有结果${NC}                        ${BOLD}${CYAN}║${NC}"
    echo -e "${BOLD}${CYAN}║${NC}  ${YELLOW}建议分析相关性后安装${NC}                            ${BOLD}${CYAN}║${NC}"
    echo -e "${BOLD}${CYAN}╚══════════════════════════════════════════════════════╝${NC}"

elif [ "$CLAWHUB_FOUND" -eq 1 ]; then
    echo -e "${BOLD}${CYAN}║${NC}  ${YELLOW}${BOLD}💡 低置信：仅 ClawHub 有结果${NC}                      ${BOLD}${CYAN}║${NC}"
    echo -e "${BOLD}${CYAN}╚══════════════════════════════════════════════════════╝${NC}"

else
    echo -e "${BOLD}${CYAN}║${NC}  ${RED}${BOLD}❌ 无结果：5 层搜索均未命中${NC}                       ${BOLD}${CYAN}║${NC}"
    echo -e "${BOLD}${CYAN}║${NC}  ${YELLOW}建议 agent 用 mimo_web_search 联网搜索:${NC}         ${BOLD}${CYAN}║${NC}"
    echo -e "${BOLD}${CYAN}║${NC}  ${CYAN}  '${QUERY} install ubuntu'${NC}                     ${BOLD}${CYAN}║${NC}"
    echo -e "${BOLD}${CYAN}║${NC}  ${CYAN}  '${QUERY} linux alternative'${NC}                   ${BOLD}${CYAN}║${NC}"
    echo -e "${BOLD}${CYAN}╚══════════════════════════════════════════════════════╝${NC}"
fi

echo ""
