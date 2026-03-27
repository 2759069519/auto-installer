#!/bin/bash
# ============================================================
# 🦞 auto-installer: 5 层智能搜索 + 降级链安装脚本
# 用法:
#   bash auto-install-search.sh <关键词>           # 仅搜索
#   bash auto-install-search.sh <关键词> --install  # 搜索并自动安装
# ============================================================
set -euo pipefail

# 确保 snap 命令在 PATH 中
[ -d /snap/bin ] && export PATH="/snap/bin:$PATH"

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

# GitHub 代理列表（按优先级排列，多个备用）
GITHUB_PROXIES=(
    "https://ghfast.top"
    "https://gh.llkk.cc"
    "https://gh-proxy.com"
    "https://gh.monlor.com"
    "https://gh.xxooo.cf"
    "https://gh.jasonzeng.dev"
    "https://gh.dpik.top"
)

# 缓存已找到的可用代理
_CACHED_PROXY=""

# 并行测试所有代理，返回最快可用的（总耗时不超过最慢单个）
find_fastest_proxy() {
    local test_path="/https://raw.githubusercontent.com/cli/cli/master/README.md"
    local tmpdir=$(mktemp -d)
    local pids=()

    # 并行发起所有代理测试
    for i in "${!GITHUB_PROXIES[@]}"; do
        proxy="${GITHUB_PROXIES[$i]}"
        (
            start=$(date +%s%N)
            code=$(curl -s -o /dev/null -w "%{http_code}" --connect-timeout 3 --max-time 8 "${proxy}${test_path}" 2>/dev/null) || code="000"
            end=$(date +%s%N)
            elapsed=$(( (end - start) / 1000000 ))  # ms
            echo "${code} ${elapsed} ${proxy}" > "${tmpdir}/proxy_${i}"
        ) &
        pids+=($!)
    done

    # 等待所有测试完成（最多10秒）
    local timeout_timer=0
    while [ $timeout_timer -lt 10 ]; do
        local all_done=1
        for pid in "${pids[@]}"; do
            if kill -0 "$pid" 2>/dev/null; then
                all_done=0
                break
            fi
        done
        [ "$all_done" -eq 1 ] && break
        sleep 0.5
        timeout_timer=$((timeout_timer + 1))
    done

    # 杀掉残留进程
    for pid in "${pids[@]}"; do
        kill "$pid" 2>/dev/null || true
    done
    wait 2>/dev/null

    # 找到最快的 200 代理
    local best_proxy=""
    local best_time=999999
    for f in "${tmpdir}"/proxy_*; do
        [ -f "$f" ] || continue
        local line=$(cat "$f")
        local code=$(echo "$line" | awk '{print $1}')
        local ms=$(echo "$line" | awk '{print $2}')
        local px=$(echo "$line" | awk '{print $3}')
        if [ "$code" = "200" ] && [ "$ms" -lt "$best_time" ]; then
            best_time=$ms
            best_proxy=$px
        fi
    done

    rm -rf "$tmpdir"
    echo "$best_proxy"
}

# GitHub 镜像加速 URL（自动选择最快可用代理，带缓存）
github_mirror_url() {
    local url="$1"
    if ! is_china_network; then
        echo "$url"
        return
    fi
    # 首次调用时并行测试所有代理
    if [ -z "$_CACHED_PROXY" ]; then
        _CACHED_PROXY=$(find_fastest_proxy)
    fi
    if [ -n "$_CACHED_PROXY" ]; then
        echo "${_CACHED_PROXY}/${url}"
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
# 支持 "name (alias)" 格式，如 "ripgrep (rg)" → 先查 rg，再查 ripgrep
verify_cmd() {
    local cmd="$1"
    local cmd_names=()
    # 解析 "name (alias)" 格式
    if [[ "$cmd" =~ ^([a-zA-Z0-9_-]+)[[:space:]]*\(([a-zA-Z0-9_-]+)\)$ ]]; then
        cmd_names+=("${BASH_REMATCH[2]}")  # alias 优先（如 rg）
        cmd_names+=("${BASH_REMATCH[1]}")  # 主名（如 ripgrep）
    else
        cmd_names+=("$cmd")
    fi
    for name in "${cmd_names[@]}"; do
        if command -v "$name" &>/dev/null; then
            local version=$("$name" --version 2>/dev/null | head -1 || echo "installed")
            echo -e "  ${GREEN}${BOLD}✅ 安装成功: ${name} — ${version}${NC}"
            return 0
        fi
    done
    echo -e "  ${RED}${BOLD}❌ 安装后验证失败: ${cmd} 不存在${NC}"
    return 1
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
                # 处理 URL 格式：支持完整 URL 和 github.com/repo 两种格式
                local dl_url
                if echo "$pkg" | grep -qE "^https?://"; then
                    dl_url="$pkg"
                else
                    dl_url="https://${pkg}"
                fi
                local mirror_url=$(github_mirror_url "$dl_url")
                echo -e "  ${YELLOW}  ⚡ 需要下载: ${dl_url}${NC}"
                echo -e "  ${CYAN}  镜像加速: ${mirror_url}${NC}"
                # Release 页面也用镜像加速
                local release_url="${dl_url}/releases/latest"
                local mirror_release=$(github_mirror_url "$release_url")
                echo -e "  ${CYAN}  Release页: ${mirror_release}${NC}"
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
