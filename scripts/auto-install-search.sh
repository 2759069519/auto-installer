#!/bin/bash
# ============================================================
# 🦞 auto-installer v2.2: 6层智能搜索 + 降级链 + 自学习 + 自动回写 + JSONL历史 + 已装检测
#
# 用法:
#   bash auto-install-search.sh <关键词|报错信息>                # 仅搜索
#   bash auto-install-search.sh <关键词|报错信息> --install      # 搜索并自动安装
#   bash auto-install-search.sh --install tool1 tool2 tool3     # 批量安装（走6层全链路）
#   bash auto-install-search.sh --learn <工具名> [描述]          # 手动学习
#   bash auto-install-search.sh --promote                       # 整理学习记录到映射表
#   bash auto-install-search.sh --history                       # 查看学习历史
#   bash auto-install-search.sh --failures                      # 查看失败记录
#   bash auto-install-search.sh --scan                          # 扫描系统已装工具
#   bash auto-install-search.sh --stats                         # 查看安装统计
#
# 退出码:
#   0 = 成功（找到了方案或安装成功）
#   1 = 参数错误
#   10 = 全部6层未命中，建议 agent 联网搜索
# ============================================================
set -euo pipefail

# 确保 snap 命令在 PATH 中
[ -d /snap/bin ] && export PATH="/snap/bin:$PATH"

# ── 颜色 ─────────────────────────────────────────────
GREEN='\033[0;32m'; BLUE='\033[0;34m'; YELLOW='\033[1;33m'
CYAN='\033[0;36m'; RED='\033[0;31m'; BOLD='\033[1m'; DIM='\033[2m'; NC='\033[0m'

# ── 全局路径 ─────────────────────────────────────────
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
SKILL_DIR="${SCRIPT_DIR}/.."
MAP_FILE="${SKILL_DIR}/references/task-tool-map.md"
LEARN_LOG="${SKILL_DIR}/references/learned-tools.log"
FAIL_LOG="${SKILL_DIR}/references/failed-installs.log"
STATS_FILE="${SKILL_DIR}/references/usage-stats.json"
DATA_DIR="${SKILL_DIR}/data"
HISTORY_FILE="${DATA_DIR}/install-history.jsonl"
INSTALLED_INDEX="${DATA_DIR}/installed-index.json"

# ── 全局状态 ─────────────────────────────────────────
QUERY=""
DO_INSTALL=0
MODE="search"
ALL_ARGS=()
EXIT_CODE=0

# ── 参数解析 ─────────────────────────────────────────
parse_args() {
    if [ $# -eq 0 ]; then
        echo -e "${RED}用法: bash auto-install-search.sh <关键词> [--install]${NC}"
        echo -e "${DIM}      bash auto-install-search.sh --install tool1 tool2 tool3${NC}"
        echo -e "${DIM}      bash auto-install-search.sh --learn <工具名> [描述]${NC}"
        echo -e "${DIM}      bash auto-install-search.sh --promote${NC}"
        echo -e "${DIM}      bash auto-install-search.sh --history / --failures / --stats / --scan${NC}"
        exit 1
    fi

    case "$1" in
        --learn)    MODE="learn"; shift; ALL_ARGS=("$@") ;;
        --history)  MODE="history" ;;
        --failures) MODE="failures" ;;
        --promote)  MODE="promote" ;;
        --scan)     MODE="scan" ;;
        --stats)    MODE="stats" ;;
        --install)
            DO_INSTALL=1
            shift
            if [ $# -eq 0 ]; then
                echo -e "${RED}错误: --install 需要至少一个工具名${NC}"; exit 1
            fi
            ALL_ARGS=("$@")
            if [ ${#ALL_ARGS[@]} -eq 1 ]; then
                QUERY="$1"
                MODE="search"
            else
                MODE="batch"
            fi
            ;;
        *)
            QUERY="$1"
            if [ "${2:-}" = "--install" ]; then
                DO_INSTALL=1
            fi
            ;;
    esac
}

# ── 工具函数 ─────────────────────────────────────────

is_china_network() {
    ! curl -s --connect-timeout 3 https://www.google.com >/dev/null 2>&1
}

has_sudo() {
    if [ "$(id -u)" -eq 0 ]; then echo ""
    elif command -v sudo &>/dev/null && sudo -n true 2>/dev/null; then echo "sudo "
    else echo "NEED_SUDO"
    fi
}

# GitHub 代理
GITHUB_PROXIES=(
    "https://ghfast.top" "https://gh.llkk.cc" "https://gh-proxy.com"
    "https://gh.monlor.com" "https://gh.xxooo.cf" "https://gh.jasonzeng.dev"
    "https://gh.dpik.top"
)
_CACHED_PROXY=""
_CACHED_PROXY_TESTED=0

find_fastest_proxy() {
    [ "$_CACHED_PROXY_TESTED" -eq 1 ] && { echo "$_CACHED_PROXY"; return; }
    _CACHED_PROXY_TESTED=1
    local test_path="/https://raw.githubusercontent.com/cli/cli/master/README.md"
    local tmpdir pids=()
    tmpdir=$(mktemp -d)
    for i in "${!GITHUB_PROXIES[@]}"; do
        local proxy="${GITHUB_PROXIES[$i]}"
        (
            local s e code; s=$(date +%s%N)
            code=$(curl -s -o /dev/null -w "%{http_code}" --connect-timeout 3 --max-time 8 "${proxy}${test_path}" 2>/dev/null) || code="000"
            e=$(date +%s%N); echo "$(( (e-s)/1000000 )) ${code} ${proxy}" > "${tmpdir}/p${i}"
        ) & pids+=($!)
    done
    local t=0; while [ $t -lt 10 ]; do
        local all=1; for p in "${pids[@]}"; do kill -0 "$p" 2>/dev/null && { all=0; break; }; done
        [ "$all" -eq 1 ] && break; sleep 0.5; t=$((t+1))
    done
    for p in "${pids[@]}"; do kill "$p" 2>/dev/null || true; done; wait 2>/dev/null
    local best="" best_t=999999
    for f in "${tmpdir}"/p*; do
        [ -f "$f" ] || continue
        local ms code px; read -r ms code px < "$f"
        [ "$code" = "200" ] && [ "$ms" -lt "$best_t" ] && { best_t=$ms; best=$px; }
    done
    rm -rf "$tmpdir"; _CACHED_PROXY="$best"; echo "$best"
}

github_mirror_url() {
    local url="$1"
    is_china_network && { local p; p=$(find_fastest_proxy); [ -n "$p" ] && { echo "${p}/${url}"; return; }; }
    echo "$url"
}

pip_mirror_flag() {
    is_china_network && echo "-i https://pypi.tuna.tsinghua.edu.cn/simple" || echo ""
}

# ── 验证命令可用 ─────────────────────────────────────

verify_cmd() {
    local cmd="$1" names=()
    if [[ "$cmd" =~ ^([a-zA-Z0-9._-]+)[[:space:]]*\(([a-zA-Z0-9._-]+)\)$ ]]; then
        names+=("${BASH_REMATCH[2]}" "${BASH_REMATCH[1]}")
    elif [[ "$cmd" =~ ^([a-zA-Z0-9._-]+)[[:space:]]*/[[:space:]]*([a-zA-Z0-9._-]+)$ ]]; then
        names+=("${BASH_REMATCH[1]}" "${BASH_REMATCH[2]}")
    else names+=("$cmd"); fi
    for n in "${names[@]}"; do
        if command -v "$n" &>/dev/null; then
            local ver; ver=$("$n" --version 2>/dev/null | head -1 || echo "installed")
            echo -e "  ${GREEN}${BOLD}✅ 安装成功: ${n} — ${ver}${NC}"; return 0
        fi
    done
    # 最后兜底：检查 dpkg 是否已安装此包
    if dpkg -s "$cmd" 2>/dev/null | grep -q "Status: install ok installed"; then
        echo -e "  ${GREEN}${BOLD}✅ 安装成功: ${cmd} (dpkg 确认已安装)${NC}"; return 0
    fi
    echo -e "  ${RED}${BOLD}❌ 验证失败: ${cmd} 不存在${NC}"; return 1
}

extract_cmd_name() {
    local raw="$1"
    [[ "$raw" =~ \(([a-zA-Z0-9._-]+)\) ]] && { echo "${BASH_REMATCH[1]}"; return; }
    [[ "$raw" =~ ^([a-zA-Z0-9._-]+) ]] && { echo "${BASH_REMATCH[1]}"; return; }
    echo "$raw"
}

# ── JSONL 安装历史 ───────────────────────────────────

log_install_history() {
    local query="$1" cmd="$2" method="$3" success="$4" time_ms="${5:-0}"
    mkdir -p "$DATA_DIR"
    local ts; ts=$(date '+%Y-%m-%dT%H:%M:%S%z')
    # 用 python 写 JSONL，避免 shell JSON 转义问题
    python3 -c "
import json
entry = {'ts':'${ts}','query':'''${query}'''.replace(\"'\",\"\\\\'\"),'cmd':'${cmd}','method':'${method}','success':${success},'time_ms':${time_ms}}
with open('${HISTORY_FILE}','a') as f:
    f.write(json.dumps(entry, ensure_ascii=False) + '\n')
" 2>/dev/null || echo "{\"ts\":\"${ts}\",\"query\":\"${query}\",\"cmd\":\"${cmd}\",\"method\":\"${method}\",\"success\":${success},\"time_ms\":${time_ms}}" >> "$HISTORY_FILE"
}

# ── 已安装工具索引 ───────────────────────────────────

is_already_installed() {
    local cmd="$1"
    # 检查命令是否已在 PATH 中
    command -v "$cmd" &>/dev/null && return 0
    # 检查 dpkg
    dpkg -s "$cmd" 2>/dev/null | grep -q "Status: install ok installed" && return 0
    return 1
}

do_scan() {
    echo -e "\n${BOLD}${CYAN}🔍 扫描系统已安装工具${NC}\n"
    mkdir -p "$DATA_DIR"
    local tmp="${DATA_DIR}/.scan-tmp.json"
    echo '{}' > "$tmp"

    # dpkg 已装包
    if command -v dpkg &>/dev/null; then
        local count; count=$(dpkg -l 2>/dev/null | grep '^ii' | wc -l)
        echo -e "  ${CYAN}📦 dpkg: ${count} 个包${NC}"
        python3 -c "
import json, subprocess
d=json.load(open('${tmp}'))
result=subprocess.run(['dpkg-query','-W','-f=\${Package}\\\n'], capture_output=True, text=True)
pkgs=[p.strip() for p in result.stdout.strip().split('\n') if p.strip()]
d['apt']={'count':len(pkgs),'packages':pkgs[:200]}
json.dump(d, open('${tmp}','w'), indent=2, ensure_ascii=False)
" 2>/dev/null || true
    fi

    # pip 已装包
    if command -v pip3 &>/dev/null; then
        local pcount; pcount=$(pip3 list --format=json 2>/dev/null | python3 -c "import json,sys;print(len(json.load(sys.stdin)))" 2>/dev/null || echo "0")
        echo -e "  ${CYAN}🐍 pip3: ${pcount} 个包${NC}"
        python3 -c "
import json, subprocess
d=json.load(open('${tmp}'))
result=subprocess.run(['pip3','list','--format=json'], capture_output=True, text=True)
pkgs=json.loads(result.stdout) if result.stdout else []
d['pip']={'count':len(pkgs),'packages':pkgs[:200]}
json.dump(d, open('${tmp}','w'), indent=2, ensure_ascii=False)
" 2>/dev/null || true
    fi

    # npm 全局包
    if command -v npm &>/dev/null; then
        local ncount; ncount=$(npm list -g --depth=0 2>/dev/null | grep -c '──' || echo "0")
        echo -e "  ${CYAN}📦 npm: ${ncount} 个全局包${NC}"
        python3 -c "
import json, subprocess
d=json.load(open('${tmp}'))
result=subprocess.run(['npm','list','-g','--json','--depth=0'], capture_output=True, text=True)
try: data=json.loads(result.stdout); pkgs=list(data.get('dependencies',{}).keys())
except: pkgs=[]
d['npm']={'count':len(pkgs),'packages':pkgs}
json.dump(d, open('${tmp}','w'), indent=2, ensure_ascii=False)
" 2>/dev/null || true
    fi

    # snap 包
    if command -v snap &>/dev/null; then
        local scount; scount=$(snap list 2>/dev/null | tail -n +2 | wc -l || echo "0")
        echo -e "  ${CYAN}📦 snap: ${scount} 个包${NC}"
        python3 -c "
import json, subprocess
d=json.load(open('${tmp}'))
result=subprocess.run(['snap','list'], capture_output=True, text=True)
lines=result.stdout.strip().split('\n')[1:]
pkgs=[l.split()[0] for l in lines if l.strip()]
d['snap']={'count':len(pkgs),'packages':pkgs}
json.dump(d, open('${tmp}','w'), indent=2, ensure_ascii=False)
" 2>/dev/null || true
    fi

    mv "$tmp" "$INSTALLED_INDEX"
    echo -e "\n  ${GREEN}${BOLD}✅ 索引已保存: ${INSTALLED_INDEX}${NC}\n"
}

# ── 学习 & 失败记录 ─────────────────────────────────

# 检查某条降级链步骤是否近期失败过
is_recently_failed() {
    local tool="$1" method="$2" pkg="$3"
    [ ! -f "$FAIL_LOG" ] && return 1
    grep -q "| ${tool} | ${method} ${pkg} |" "$FAIL_LOG" 2>/dev/null
}

# 记录成功学习（安装后自动回写映射表）
record_success() {
    local tool="$1" desc="${2:-自动学习}" chain="${3:-}" query="${4:-}" skip_wb="${5:-0}"
    [ -z "$tool" ] && return 0
    # 去重：已存在则跳过
    grep -qi "^| ${tool} |" "$MAP_FILE" 2>/dev/null && return 0
    grep -qi "${tool} | 已学习" "$LEARN_LOG" 2>/dev/null && return 0

    mkdir -p "$(dirname "$LEARN_LOG")"
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] ${tool} | 已学习 | ${chain} | ${desc}" >> "$LEARN_LOG"
    echo -e "  ${GREEN}📝 已记录成功: ${tool}${NC}"

    # ✨ v2.2: 自动回写映射表
    if [ "$skip_wb" = "1" ]; then echo -e "  ${DIM}  跳过回写（无描述）${NC}"; else auto_writeback_mapping "$tool" "$desc" "$chain"; fi

    # 更新使用统计
    increment_stat "$tool"
}

# 自动回写映射表
auto_writeback_mapping() {
    local tool="$1" desc="$2" chain="$3"
    # 检查映射表是否已有此工具
    grep -qi "| \`${tool}" "$MAP_FILE" 2>/dev/null && return 0

    # 检查自动发现分类
    if ! grep -q "🔧 自动发现的工具" "$MAP_FILE" 2>/dev/null; then
        echo "" >> "$MAP_FILE"
        echo "## 🔧 自动发现的工具" >> "$MAP_FILE"
        echo "" >> "$MAP_FILE"
        echo "| 任务 | 工具 | 安装降级链 |" >> "$MAP_FILE"
        echo "|------|------|-----------|" >> "$MAP_FILE"
    fi

    echo "| ${desc} | \`${tool}\` | \`${chain}\` |" >> "$MAP_FILE"
    echo -e "  ${GREEN}📄 已回写映射表: ${tool}${NC}"
}

# 记录失败
record_failure() {
    local tool="$1" method="$2" pkg="$3" reason="${4:-安装失败}"
    mkdir -p "$(dirname "$FAIL_LOG")"
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] ${tool} | ${method} ${pkg} | ${reason}" >> "$FAIL_LOG"
    echo -e "  ${DIM}📝 已记录失败: ${method} ${pkg} — ${reason}${NC}"
}

# 使用统计
increment_stat() {
    local tool="$1"
    mkdir -p "$(dirname "$STATS_FILE")"
    if [ ! -f "$STATS_FILE" ]; then echo '{}' > "$STATS_FILE"; fi
    local count
    count=$(grep -o "\"${tool}\":[0-9]*" "$STATS_FILE" 2>/dev/null | grep -o '[0-9]*$' || echo "0")
    count=$((count + 1))
    python3 -c "
import json, sys
f='${STATS_FILE}'; t='${tool}'; c=${count}
try:
    d=json.load(open(f))
except: d={}
d[t]=c
json.dump(d, open(f,'w'), indent=2, ensure_ascii=False)
" 2>/dev/null || true
}

# ── 自学习命令 ───────────────────────────────────────

do_learn() {
    local tool="${ALL_ARGS[0]:-}" desc="${ALL_ARGS[1]:-自动学习}"
    [ -z "$tool" ] && { echo -e "${RED}用法: --learn <工具名> [描述]${NC}"; exit 1; }
    echo -e "\n${BOLD}${CYAN}📝 自学习模式${NC}\n"
    local method="" chain=""
    if command -v "$tool" &>/dev/null; then
        echo -e "  ${GREEN}✓ ${tool} 已安装${NC}"
        local src; src=$(dpkg -S "$(command -v "$tool")" 2>/dev/null | head -1 || true)
        [ -n "$src" ] && method="apt"
    fi
    [ -n "$method" ] && chain="${method} ${tool}" || chain="apt ${tool}"
    local _swb=0; [ "${ALL_ARGS[1]:-}" = "" ] && _swb=1; record_success "$tool" "$desc" "$chain" "" "$_swb"
}

do_history() {
    echo -e "\n${BOLD}${CYAN}📝 学习历史${NC}\n"
    if [ ! -f "$LEARN_LOG" ]; then echo -e "  ${YELLOW}○ 暂无记录${NC}"; return; fi
    local c; c=$(wc -l < "$LEARN_LOG")
    echo -e "  ${GREEN}共学习 ${c} 个工具:${NC}\n"
    cat "$LEARN_LOG"
}

do_failures() {
    echo -e "\n${BOLD}${CYAN}📝 失败记录${NC}\n"
    if [ ! -f "$FAIL_LOG" ]; then echo -e "  ${YELLOW}○ 暂无失败记录${NC}"; return; fi
    local c; c=$(wc -l < "$FAIL_LOG")
    echo -e "  ${RED}共 ${c} 条失败记录:${NC}\n"
    cat "$FAIL_LOG"
}

# ── 安装统计 ─────────────────────────────────────────

do_stats() {
    echo -e "\n${BOLD}${CYAN}📊 安装统计${NC}\n"
    # 使用统计
    if [ -f "$STATS_FILE" ]; then
        echo -e "  ${CYAN}🔑 使用次数:${NC}"
        python3 -c "
import json
d=json.load(open('${STATS_FILE}'))
for k,v in sorted(d.items(), key=lambda x:-x[1]):
    if k != '_searches':
        print(f'    {k}: {v} 次')
" 2>/dev/null || echo "    (无法读取)"
    fi
    # JSONL 历史
    if [ -f "$HISTORY_FILE" ]; then
        local total success fail
        local total success fail rate
        read -r total success fail rate < <(python3 -c "
import json
lines=open('${HISTORY_FILE}').readlines()
t=len(lines)
s=sum(1 for l in lines if ('true' in l and 'success' in l))
f=t-s
r=(s*100//t) if t>0 else 0
print(t,s,f,r)
" 2>/dev/null || echo "0 0 0 0")
        echo ""
        echo -e "  ${CYAN}📦 安装历史: ${total} 条${NC}"
        echo -e "  ${GREEN}  ✅ 成功: ${success}${NC}"
        echo -e "  ${RED}  ❌ 失败: ${fail}${NC}"
        echo -e "  ${CYAN}  📈 成功率: ${rate}%${NC}"
    fi
    # 学习记录
    if [ -f "$LEARN_LOG" ]; then
        local lc; lc=$(wc -l < "$LEARN_LOG")
        echo -e "\n  ${CYAN}📝 已学习工具: ${lc} 个${NC}"
    fi
    # 映射表
    if [ -f "$MAP_FILE" ]; then
        local mc; mc=$(grep -c '^|' "$MAP_FILE" 2>/dev/null || echo 0)
        mc=$((mc - 3))  # 减去表头行
        echo -e "  ${CYAN}🗺️  映射表条目: ${mc} 个${NC}"
    fi
    echo ""
}

# ── 整理学习记录到映射表 ─────────────────────────────

do_promote() {
    echo -e "\n${BOLD}${CYAN}🔄 整理学习记录到映射表${NC}\n"
    if [ ! -f "$LEARN_LOG" ]; then echo -e "  ${YELLOW}○ 无学习记录可整理${NC}"; return; fi

    local promoted=0 skipped=0
    while IFS= read -r line; do
        local tool desc chain
        tool=$(echo "$line" | sed 's/^\[[^]]*\] //' | awk -F'|' '{print $1}' | xargs)
        chain=$(echo "$line" | sed 's/^\[[^]]*\] //' | awk -F'|' '{print $3}' | xargs)
        desc=$(echo "$line" | sed 's/^\[[^]]*\] //' | awk -F'|' '{print $4}' | xargs)
        [ -z "$desc" ] && desc="自动发现的工具"
        [ -z "$tool" ] && continue

        # 检查映射表是否已有
        if grep -qi "| \`${tool}" "$MAP_FILE" 2>/dev/null; then
            echo -e "  ${DIM}跳过 ${tool}（已存在）${NC}"
            skipped=$((skipped+1)); continue
        fi

        if ! grep -q "🔧 自动发现的工具" "$MAP_FILE" 2>/dev/null; then
            echo "" >> "$MAP_FILE"
            echo "## 🔧 自动发现的工具" >> "$MAP_FILE"
            echo "" >> "$MAP_FILE"
            echo "| 任务 | 工具 | 安装降级链 |" >> "$MAP_FILE"
            echo "|------|------|-----------|" >> "$MAP_FILE"
        fi

        echo "| ${desc} | \`${tool}\` | \`${chain}\` |" >> "$MAP_FILE"
        echo -e "  ${GREEN}✓ 已写入: ${tool} → ${chain}${NC}"
        promoted=$((promoted+1))
    done < "$LEARN_LOG"

    echo -e "\n  ${GREEN}${BOLD}整理完成: ${promoted} 个已写入, ${skipped} 个跳过${NC}"
    if [ "$promoted" -gt 0 ]; then
        > "$LEARN_LOG"
        echo -e "  ${DIM}学习记录已清空${NC}"
    fi
}

# ── 智能推理 ─────────────────────────────────────────

infer_from_error() {
    local input="$1"
    # command not found: xxx
    if [[ "$input" =~ command[[:space:]]+not[[:space:]]+found:?[\ ]*([a-zA-Z0-9._-]+) ]]; then
        local t="${BASH_REMATCH[1]}"
        echo "tool=${t} cmd=${t} chain=apt ${t} type=command"; return 0
    fi
    # ModuleNotFoundError
    if [[ "$input" =~ ModuleNotFoundError.*[\'\"]([a-zA-Z0-9_.-]+)[\'\"] ]]; then
        local t="${BASH_REMATCH[1]}"
        echo "tool=${t} cmd=${t} chain=pip ${t} → pip -i https://pypi.tuna.tsinghua.edu.cn/simple ${t} type=python"; return 0
    fi
    # Cannot find module
    if [[ "$input" =~ Cannot[[:space:]]+find[[:space:]]+module[\ ]*[\'\"]([a-zA-Z0-9_.-]+)[\'\"] ]]; then
        local t="${BASH_REMATCH[1]}"
        echo "tool=${t} cmd=${t} chain=npm ${t} type=node"; return 0
    fi
    # shared library
    if [[ "$input" =~ loading[[:space:]]+shared[[:space:]]+libraries:.*lib([a-zA-Z0-9_-]+) ]]; then
        local t="lib${BASH_REMATCH[1]}-dev"
        echo "tool=${t} cmd=${t} chain=apt ${t} type=library"; return 0
    fi
    # ImportError: libGL
    if [[ "$input" =~ ImportError.*libGL ]]; then
        echo "tool=libgl1-mesa-glx cmd=libgl1-mesa-glx chain=apt libgl1-mesa-glx type=library"; return 0
    fi
    # Permission denied → chmod
    if [[ "$input" =~ Permission[[:space:]]+denied ]]; then
        echo "tool=chmod cmd=chmod chain= type=builtin"; return 0
    fi
    return 1
}

# ── 降级链安装 ───────────────────────────────────────

install_from_chain() {
    local chain="$1" cmd_name="$2" query="${3:-$cmd_name}"
    local sudo_p; sudo_p=$(has_sudo)
    [ "$sudo_p" = "NEED_SUDO" ] && { echo -e "  ${YELLOW}⚠ 需要 sudo 权限${NC}"; sudo_p=""; }

    echo -e "\n${BOLD}${CYAN}🔧 安装降级链: ${chain}${NC}\n"

    # ✨ 检查是否已安装
    if is_already_installed "$cmd_name"; then
        local ver; ver=$("$cmd_name" --version 2>/dev/null | head -1 || echo "already installed")
        echo -e "  ${GREEN}${BOLD}✅ 已安装: ${cmd_name} — ${ver}${NC}"
        log_install_history "$query" "$cmd_name" "already" "true" "0"
        return 0
    fi

    IFS='→' read -ra STEPS <<< "$chain"
    local tried_any=0 install_start; install_start=$(date +%s%N)
    for step in "${STEPS[@]}"; do
        step=$(echo "$step" | xargs | tr -d '`')
        local method; method=$(echo "$step" | awk '{print $1}')
        local pkg; pkg=$(echo "$step" | awk '{$1=""; print $0}' | xargs)
        [ -z "$pkg" ] && continue

        # 检查此步骤是否近期失败过
        if is_recently_failed "$cmd_name" "$method" "$pkg"; then
            echo -e "${BLUE}  跳过: ${method} ${pkg} ${DIM}(近期失败，24h 内不再重试)${NC}"
            continue
        fi

        tried_any=1
        echo -e "${BLUE}  尝试: ${method} ${pkg}...${NC}"

        local install_ok=0 step_start; step_start=$(date +%s%N)
        case "$method" in
            apt)
                ${sudo_p}apt install -y $pkg 2>/dev/null && install_ok=1
                [ $install_ok -eq 0 ] && record_failure "$cmd_name" "apt" "$pkg" "apt install 失败"
                ;;
            snap)
                snap install $pkg 2>/dev/null && install_ok=1
                [ $install_ok -eq 0 ] && record_failure "$cmd_name" "snap" "$pkg" "snap install 失败"
                ;;
            pip)
                local mirror; mirror=$(pip_mirror_flag)
                pip3 install --break-system-packages $mirror $pkg 2>/dev/null && install_ok=1
                [ $install_ok -eq 0 ] && record_failure "$cmd_name" "pip" "$pkg" "pip install 失败"
                ;;
            npm)
                npm install -g $pkg 2>/dev/null && install_ok=1
                [ $install_ok -eq 0 ] && record_failure "$cmd_name" "npm" "$pkg" "npm install 失败"
                ;;
            dl|download)
                install_ok=$(try_download "$pkg" "$cmd_name") || true
                [ $install_ok -eq 0 ] && record_failure "$cmd_name" "dl" "$pkg" "下载安装失败"
                ;;
            src|source)
                install_ok=$(try_source_build "$pkg" "$cmd_name" "$sudo_p") || true
                [ $install_ok -eq 0 ] && record_failure "$cmd_name" "src" "$pkg" "源码编译失败"
                ;;
            go)
                if command -v go &>/dev/null; then
                    go install "${pkg}@latest" 2>/dev/null && { echo -e "  ${GREEN}  ✓ go install 成功${NC}"; install_ok=1; }
                fi
                [ $install_ok -eq 0 ] && record_failure "$cmd_name" "go" "$pkg" "go install 失败"
                ;;
            pipx)
                if command -v pipx &>/dev/null; then
                    pipx install $pkg 2>/dev/null && install_ok=1
                fi
                [ $install_ok -eq 0 ] && record_failure "$cmd_name" "pipx" "$pkg" "pipx install 失败"
                ;;
            *)
                echo -e "  ${YELLOW}  ✗ 未知方式: ${method}${NC}"
                ;;
        esac

        # 验证 + 学习
        if [ $install_ok -eq 1 ]; then
            local step_end; step_end=$(date +%s%N)
            local elapsed_ms=$(( (step_end - step_start) / 1000000 ))
            if [ "$method" = "pip" ]; then
                echo -e "  ${GREEN}  ✓ pip 安装成功${NC}"
                record_success "$cmd_name" "自动学习" "${method} ${pkg}" "$query"
                log_install_history "$query" "$cmd_name" "$method" "true" "$elapsed_ms"
                return 0
            elif verify_cmd "$cmd_name"; then
                record_success "$cmd_name" "自动学习" "${method} ${pkg}" "$query"
                log_install_history "$query" "$cmd_name" "$method" "true" "$elapsed_ms"
                return 0
            fi
        fi
    done

    # 记录失败到 JSONL
    local step_end; step_end=$(date +%s%N)
    local elapsed_ms=$(( (step_end - install_start) / 1000000 ))
    log_install_history "$query" "$cmd_name" "chain_failed" "false" "$elapsed_ms"

    if [ $tried_any -eq 0 ]; then
        echo -e "  ${YELLOW}  ⚠ 所有步骤均被跳过（近期均失败过）${NC}"
        echo -e "  ${DIM}  等待 24h 后重试，或用 --failures 查看详情${NC}"
    else
        echo -e "  ${RED}${BOLD}❌ 所有安装方式均失败${NC}"
    fi
    return 1
}

# ── GitHub Release 下载 ─────────────────────────────

try_download() {
    local pkg="$1" cmd_name="$2" sudo_p="${3:-}"
    local repo_path="" dl_url=""

    if echo "$pkg" | grep -qE "^https?://"; then
        dl_url="$pkg"
        repo_path=$(echo "$pkg" | sed -n 's|.*/github.com/\([^/]*/[^/]*\).*|\1|p')
    elif echo "$pkg" | grep -qE "^github\.com/"; then
        repo_path=$(echo "$pkg" | sed 's|^github.com/||')
        dl_url="https://github.com/${repo_path}"
    else
        dl_url="https://${pkg}"
        repo_path=$(echo "$pkg" | sed 'n;s|.*/github.com/\([^/]*/[^/]*\).*|\1|p')
    fi

    if [ -z "$repo_path" ]; then
        echo -e "  ${YELLOW}  ⚠ 无法解析 GitHub 仓库${NC}"
        echo 0; return 0
    fi

    local arch; arch=$(uname -m)
    local os; os=$(uname -s | tr '[:upper:]' '[:lower:]')
    local suffix
    case "$arch" in x86_64) suffix="amd64";; aarch64|arm64) suffix="arm64";; *) suffix="$arch";; esac

    echo -e "  ${CYAN}  🔍 查询 Release: ${repo_path}${NC}"
    local rjson
    rjson=$(curl -s --connect-timeout 5 --max-time 10 "https://api.github.com/repos/${repo_path}/releases/latest" 2>/dev/null || true)

    if [ -z "$rjson" ] || echo "$rjson" | grep -q '"message": "Not Found"'; then
        echo -e "  ${YELLOW}  ⚠ 无 Release 信息${NC}"; echo 0; return 0
    fi

    local asset_url
    asset_url=$(echo "$rjson" | grep -oP '"browser_download_url":\s*"\K[^"]+' | grep -i "$os" | grep -i "$suffix" | head -1 || true)
    [ -z "$asset_url" ] && asset_url=$(echo "$rjson" | grep -oP '"browser_download_url":\s*"\K[^"]+' | grep -i "linux" | head -1 || true)

    if [ -z "$asset_url" ]; then
        local page; page=$(github_mirror_url "https://github.com/${repo_path}/releases/latest")
        echo -e "  ${YELLOW}  ⚠ 未找到 ${os}/${suffix} 的二进制${NC}"
        echo -e "  ${CYAN}  📋 Release 页面: ${page}${NC}"; echo 0; return 0
    fi

    local mirror_url; mirror_url=$(github_mirror_url "$asset_url")
    local filename; filename=$(basename "$asset_url")
    echo -e "  ${CYAN}  ⬇️  下载: ${mirror_url}${NC}"

    if ! curl -sL --connect-timeout 10 --max-time 120 "$mirror_url" -o "/tmp/${filename}" 2>/dev/null; then
        echo -e "  ${YELLOW}  ✗ 下载失败${NC}"; echo 0; return 0
    fi

    echo -e "  ${GREEN}  ✓ 下载完成: /tmp/${filename}${NC}"

    # 自动解压+安装
    local tmpdir="/tmp/ai-extract-$$"; mkdir -p "$tmpdir"
    case "$filename" in
        *.tar.gz|*.tgz) tar -xzf "/tmp/${filename}" -C "$tmpdir" 2>/dev/null ;;
        *.zip) unzip -o "/tmp/${filename}" -d "$tmpdir" 2>/dev/null ;;
        *.deb) ${sudo_p}dpkg -i "/tmp/${filename}" 2>/dev/null && { verify_cmd "$cmd_name"; echo $?; return 0; } ;;
        *) cp "/tmp/${filename}" "$tmpdir/" 2>/dev/null ;;
    esac

    local binary; binary=$(find "$tmpdir" -maxdepth 3 -name "$cmd_name" -type f 2>/dev/null | head -1 || true)
    if [ -n "$binary" ]; then
        ${sudo_p}install -m 755 "$binary" /usr/local/bin/ 2>/dev/null
        rm -rf "$tmpdir"
        verify_cmd "$cmd_name" && { echo 1; return 0; }
    fi

    # 试着找任何同名可执行文件
    binary=$(find "$tmpdir" -maxdepth 3 -type f -executable -name "$cmd_name*" 2>/dev/null | head -1 || true)
    if [ -n "$binary" ]; then
        ${sudo_p}install -m 755 "$binary" /usr/local/bin/"$cmd_name" 2>/dev/null
        rm -rf "$tmpdir"
        verify_cmd "$cmd_name" && { echo 1; return 0; }
    fi

    rm -rf "$tmpdir"
    echo -e "  ${YELLOW}  ⚠ 下载成功但未找到可执行文件，请手动安装${NC}"
    echo -e "  ${CYAN}  文件: /tmp/${filename}${NC}"
    echo 0
}

# ── 源码编译 ─────────────────────────────────────────

try_source_build() {
    local pkg="$1" cmd_name="$2" sudo_p="$3"
    local repo=""
    if echo "$pkg" | grep -qE "^github\.com/"; then
        repo=$(echo "$pkg" | sed 's|^github.com/||')
    elif echo "$pkg" | grep -qE "^https?://github\.com/"; then
        repo=$(echo "$pkg" | sed -n 's|.*/github.com/\([^/]*/[^/]*\).*|\1|p')
    fi

    if [ -z "$repo" ]; then
        echo -e "  ${YELLOW}  ⚠ 无仓库信息，无法编译${NC}"; echo 0; return 0
    fi

    local src_url; src_url=$(github_mirror_url "https://github.com/${repo}.git")
    echo -e "  ${CYAN}  📥 克隆: ${src_url}${NC}"
    local dir="/tmp/ai-build-${cmd_name}-$$"; rm -rf "$dir"

    if ! git clone --depth 1 "$src_url" "$dir" 2>/dev/null; then
        echo -e "  ${YELLOW}  ✗ 克隆失败${NC}"; echo 0; return 0
    fi

    if [ -f "${dir}/Makefile" ]; then
        (cd "$dir" && make -j$(nproc) 2>/dev/null && ${sudo_p}make install 2>/dev/null) && { rm -rf "$dir"; verify_cmd "$cmd_name" && { echo 1; return 0; } }
    elif [ -f "${dir}/Cargo.toml" ] && command -v cargo &>/dev/null; then
        (cd "$dir" && cargo build --release 2>/dev/null && ${sudo_p}cp target/release/"$cmd_name" /usr/local/bin/ 2>/dev/null) && { rm -rf "$dir"; verify_cmd "$cmd_name" && { echo 1; return 0; } }
    fi

    rm -rf "$dir"
    echo -e "  ${YELLOW}  ✗ 编译失败${NC}"; echo 0
}

# ── 核心搜索逻辑 ─────────────────────────────────────

do_search() {
    # 空关键词保护
    if [ -z "$QUERY" ]; then
        echo -e "${RED}错误: 关键词不能为空${NC}"
        exit 1
    fi
    local MF=0 AF=0 PF=0 NF=0 SF=0 CF=0
    local MC="" MCMD=""

    echo ""
    echo -e "${BOLD}${CYAN}╔══════════════════════════════════════════════════════════════╗${NC}"
    echo -e "${BOLD}${CYAN}║  🦞 Auto-Installer v2.2 · 6层搜索 + 自学习 + 自动回写       ║${NC}"
    echo -e "${BOLD}${CYAN}╚══════════════════════════════════════════════════════════════╝${NC}"
    echo -e "  ${YELLOW}关键词: ${BOLD}${QUERY}${NC}"
    [ "$DO_INSTALL" -eq 1 ] && echo -e "  ${GREEN}模式: 搜索 + 自动安装${NC}" || echo -e "  ${CYAN}模式: 仅搜索${NC}"
    is_china_network && echo -e "  ${YELLOW}网络: 国内环境，镜像加速${NC}"
    increment_stat "_searches"
    echo ""

    # ━━━ 第 1 层: 固定映射表 ━━━
    echo -e "${GREEN}${BOLD}━━━ 第 1 层: 固定映射表 ━━━${NC}"
    local HITS=""
    if [ -f "$MAP_FILE" ]; then
        # 精确匹配工具名
        HITS=$(grep -i "| \`${QUERY}" "$MAP_FILE" 2>/dev/null | grep "^|" | grep -v "command not found: xxx" | head -5 || true)
        # 中文描述搜索
        if [ -z "$HITS" ]; then
            HITS=$(grep -i "$QUERY" "$MAP_FILE" 2>/dev/null | grep "^|" | grep -v "^| 任务" | grep -v "^|------" | grep -v "^| 能力" | grep -v "command not found: xxx" | head -5 || true)
        fi
        # 去除常见前缀/后缀再搜
        if [ -z "$HITS" ]; then
            local cq; cq=$(echo "$QUERY" | sed 's/^lib//' | sed 's/-dev$//' | sed 's/-tools$//' | sed 's/-utils$//' | sed 's/^python3-//' | sed 's/^golang-//')
            [ "$cq" != "$QUERY" ] && HITS=$(grep -i "| \`${cq}" "$MAP_FILE" 2>/dev/null | head -5 || true)
        fi
        if [ -n "$HITS" ]; then
            echo "$HITS"; MF=1
            MC=$(echo "$HITS" | head -1 | awk -F'|' '{print $4}' | xargs | tr -d '`')
            MCMD=$(echo "$HITS" | head -1 | awk -F'|' '{print $3}' | xargs | tr -d '`')
            echo -e "  ${GREEN}${BOLD}✓ 命中！${NC} 降级链: ${MC}"
        else
            echo -e "  ${YELLOW}○ 未命中${NC}"
        fi
    fi

    # ━━━ 第 2 层: 智能推理 ━━━
    echo -e "\n${BLUE}${BOLD}━━━ 第 2 层: 智能推理 ━━━${NC}"
    local inf=""
    if inf=$(infer_from_error "$QUERY"); then
        local it ic itype; it=$(echo "$inf" | grep -oP 'tool=\K[^ ]+')
        ic=$(echo "$inf" | grep -oP 'chain=\K.*(?= type=)'); itype=$(echo "$inf" | grep -oP 'type=\K[^ ]+')
        echo -e "  ${GREEN}✓ 推断: ${BOLD}${it}${NC} (${itype}) → ${ic}"
        # 别名匹配
        if [ -f "$MAP_FILE" ]; then
            local ah; ah=$(grep -i "(${it})" "$MAP_FILE" 2>/dev/null | grep "^|" | head -1 || true)
            if [ -n "$ah" ]; then
                local ac acmd
                ac=$(echo "$ah" | awk -F'|' '{print $4}' | xargs | tr -d '`')
                acmd=$(echo "$ah" | awk -F'|' '{print $3}' | xargs | tr -d '`')
                [ -n "$ac" ] && { MC="$ac"; MCMD="$acmd"; MF=1; echo -e "  ${GREEN}  ✓ 别名→映射表: ${acmd} → ${ac}"; }
            fi
        fi
        [ "$MF" -eq 0 ] && { MC="$ic"; MCMD="$it"; MF=1; }
    else
        echo -e "  ${YELLOW}○ 非报错格式${NC}"
    fi

    # ━━━ 第 3 层: apt/snap ━━━
    echo -e "\n${BLUE}${BOLD}━━━ 第 3 层: 系统包 (apt/snap) ━━━${NC}"
    if command -v apt &>/dev/null; then
        local ah; ah=$(timeout 10 apt search "$QUERY" 2>/dev/null | grep -v "^Sorting\|^Full Text\|^WARNING" | grep -i "$QUERY" | head -5 || true)
        [ -n "$ah" ] && { echo "$ah"; AF=1; } || echo -e "  ${YELLOW}○ apt 未找到${NC}"
    fi
    if command -v snap &>/dev/null; then
        local sh; sh=$(timeout 10 snap find "$QUERY" 2>/dev/null | head -5 || true)
        if [ -n "$sh" ] && ! echo "$sh" | grep -q "No matching snaps"; then
            echo -e "${CYAN}  snap:${NC}"; echo "$sh"; SF=1
        fi
    fi

    # ━━━ 第 4 层: pip/npm ━━━
    echo -e "\n${BLUE}${BOLD}━━━ 第 4 层: Python / Node 包 ━━━${NC}"
    if command -v pip3 &>/dev/null; then
        local ph; ph=$(timeout 10 pip3 index versions "$QUERY" 2>/dev/null | head -3 || true)
        [ -n "$ph" ] && { echo "pip: $ph"; PF=1; }
    fi
    if command -v npm &>/dev/null; then
        local nh; nh=$(timeout 10 npm search "$QUERY" 2>/dev/null | head -3 || true)
        if [ -n "$nh" ] && ! echo "$nh" | grep -qi "no matches"; then echo "npm: $nh"; NF=1; fi
    fi
    [ "$PF" -eq 0 ] && [ "$NF" -eq 0 ] && echo -e "  ${YELLOW}○ pip/npm 未找到${NC}"

    # ━━━ 第 5 层: ClawHub ━━━
    echo -e "\n${BLUE}${BOLD}━━━ 第 5 层: ClawHub 技能 ━━━${NC}"
    if command -v npx &>/dev/null; then
        local ch; ch=$(timeout 15 npx clawhub search "$QUERY" 2>/dev/null | head -5 || true)
        [ -n "$ch" ] && { echo "$ch"; CF=1; } || echo -e "  ${YELLOW}○ ClawHub 未找到${NC}"
    else echo -e "  ${YELLOW}○ npx 不可用${NC}"; fi

    # ━━━ 第 6 层: 学习记录 ━━━
    echo -e "\n${BLUE}${BOLD}━━━ 第 6 层: 学习记录 ━━━${NC}"
    if [ -f "$LEARN_LOG" ]; then
        local lh; lh=$(grep -i "$QUERY" "$LEARN_LOG" 2>/dev/null | head -3 || true)
        if [ -n "$lh" ]; then
            echo "$lh"; echo -e "  ${GREEN}✓ 匹配学习记录${NC}"
            if [ "$MF" -eq 0 ]; then
                local lc; lc=$(echo "$lh" | head -1 | awk -F'|' '{print $4}' | xargs)
                MCMD=$(echo "$lh" | head -1 | awk -F'|' '{print $2}' | xargs)
                [ -n "$lc" ] && { MC="$lc"; MF=1; echo -e "  ${GREEN}  降级链: ${lc}${NC}"; }
            fi
        else echo -e "  ${YELLOW}○ 未找到${NC}"; fi
    else echo -e "  ${YELLOW}○ 暂无记录${NC}"; fi

    # ── 汇总 ──
    echo ""
    echo -e "${BOLD}${CYAN}╔══════════════════════════════════════════════════════════════╗${NC}"

    if [ "$MF" -eq 1 ] && [ -n "$MCMD" ]; then
        echo -e "${BOLD}${CYAN}║${NC}  ${GREEN}${BOLD}✅ 找到方案${NC}: ${MCMD} 降级链: ${MC}"
        if [ "$DO_INSTALL" -eq 1 ]; then
            echo -e "${BOLD}${CYAN}║${NC}  ${GREEN}正在安装...${NC}"
            echo -e "${BOLD}${CYAN}╚══════════════════════════════════════════════════════════════╝${NC}"
            install_from_chain "$MC" "$MCMD" "$QUERY" || EXIT_CODE=1
        else
            echo -e "${BOLD}${CYAN}║${NC}  ${CYAN}加 --install 自动安装${NC}"
            echo -e "${BOLD}${CYAN}╚══════════════════════════════════════════════════════════════╝${NC}"
        fi
    elif [ "$AF" -eq 1 ] || [ "$PF" -eq 1 ] || [ "$NF" -eq 1 ] || [ "$SF" -eq 1 ]; then
        echo -e "${BOLD}${CYAN}║${NC}  ${YELLOW}⚡ 中置信：包管理器有结果，建议分析后安装${NC}"
        echo -e "${BOLD}${CYAN}╚══════════════════════════════════════════════════════════════╝${NC}"
    else
        echo -e "${BOLD}${CYAN}║${NC}  ${RED}${BOLD}❌ 6层全部未命中${NC}"
        echo -e "${BOLD}${CYAN}║${NC}  ${YELLOW}→ agent 应调用 mimo_web_search 联网搜索${NC}"
        echo -e "${BOLD}${CYAN}║${NC}  ${DIM}  退出码 10 表示需联网搜索${NC}"
        echo -e "${BOLD}${CYAN}╚══════════════════════════════════════════════════════════════╝${NC}"
        EXIT_CODE=10
    fi
    echo ""
}

# ── 批量安装 ─────────────────────────────────────────

do_batch() {
    echo ""
    echo -e "${BOLD}${CYAN}📦 批量安装: ${ALL_ARGS[*]}${NC}"
    echo ""
    local total=${#ALL_ARGS[@]} ok=0 fail=0
    for tool in "${ALL_ARGS[@]}"; do
        echo -e "${BOLD}── [$((ok+fail+1))/${total}] ${tool} ──${NC}"
        QUERY="$tool"; DO_INSTALL=1
        # ✨ v2.2: 批量模式也走6层全链路搜索
        local MF=0; local MC="" MCMD=""
        # 第1层: 映射表
        if [ -f "$MAP_FILE" ]; then
            local h; h=$(grep -i "| \`${tool}" "$MAP_FILE" 2>/dev/null | head -1 || true)
            [ -z "$h" ] && h=$(grep -i "${tool}" "$MAP_FILE" 2>/dev/null | grep "^|" | grep -v "任务\|------\|能" | head -1 || true)
            [ -z "$h" ] && h=$(grep -i "(${tool})" "$MAP_FILE" 2>/dev/null | grep "^|" | head -1 || true)
            if [ -n "$h" ]; then
                MC=$(echo "$h" | awk -F'|' '{print $4}' | xargs | tr -d '`')
                MCMD=$(echo "$h" | awk -F'|' '{print $3}' | xargs | tr -d '`')
                MF=1
            fi
        fi
        # 第2层: 智能推理
        if [ "$MF" -eq 0 ]; then
            local inf=""
            if inf=$(infer_from_error "$tool"); then
                MC=$(echo "$inf" | grep -oP 'chain=\K.*(?= type=)')
                MCMD=$(echo "$inf" | grep -oP 'tool=\K[^ ]+')
                # 别名匹配
                if [ -f "$MAP_FILE" ]; then
                    local ah; ah=$(grep -i "(${MCMD})" "$MAP_FILE" 2>/dev/null | grep "^|" | head -1 || true)
                    if [ -n "$ah" ]; then
                        MC=$(echo "$ah" | awk -F'|' '{print $4}' | xargs | tr -d '`')
                        MCMD=$(echo "$ah" | awk -F'|' '{print $3}' | xargs | tr -d '`')
                    fi
                fi
                MF=1
            fi
        fi
        # 第3层: apt search
        if [ "$MF" -eq 0 ] && command -v apt &>/dev/null; then
            local ah; ah=$(timeout 10 apt search "$tool" 2>/dev/null | grep -i "$tool" | grep -v "^Sorting\|^Full Text\|^WARNING" | head -1 || true)
            if [ -n "$ah" ]; then
                local pkg; pkg=$(echo "$ah" | awk -F'/' '{print $1}' | xargs)
                [ -n "$pkg" ] && { MC="apt ${pkg}"; MCMD="$pkg"; MF=1; }
            fi
        fi
        # 第4层: pip search
        if [ "$MF" -eq 0 ] && command -v pip3 &>/dev/null; then
            local ph; ph=$(timeout 10 pip3 index versions "$tool" 2>/dev/null | head -1 || true)
            if [ -n "$ph" ]; then
                MC="pip ${tool}"; MCMD="$tool"; MF=1
            fi
        fi
        # 第5层: npm search
        if [ "$MF" -eq 0 ] && command -v npm &>/dev/null; then
            local nh; nh=$(timeout 10 npm search "$tool" 2>/dev/null | head -1 || true)
            if [ -n "$nh" ] && ! echo "$nh" | grep -qi "no matches"; then
                MC="npm ${tool}"; MCMD="$tool"; MF=1
            fi
        fi
        # 第6层: 学习记录
        if [ "$MF" -eq 0 ] && [ -f "$LEARN_LOG" ]; then
            local lh; lh=$(grep -i "$tool" "$LEARN_LOG" 2>/dev/null | head -1 || true)
            if [ -n "$lh" ]; then
                MC=$(echo "$lh" | awk -F'|' '{print $4}' | xargs)
                MCMD=$(echo "$lh" | awk -F'|' '{print $2}' | xargs)
                MF=1
            fi
        fi
        if [ "$MF" -eq 1 ] && [ -n "$MC" ]; then
            if install_from_chain "$MC" "$MCMD" "$tool"; then ok=$((ok+1)); else fail=$((fail+1)); fi
        else
            echo -e "  ${RED}✗ 6层全部未命中，跳过${NC}"
            log_install_history "$tool" "$tool" "not_found" "false" "0"
            fail=$((fail+1))
        fi
        echo ""
    done
    echo -e "${BOLD}${CYAN}📦 批量安装完成: ${GREEN}${ok} 成功${NC} / ${RED}${fail} 失败${NC} / ${total} 总计${NC}"
}

# ── 主入口 ───────────────────────────────────────────
parse_args "$@"

case "$MODE" in
    search)  do_search ;;
    batch)   do_batch ;;
    learn)   do_learn ;;
    history) do_history ;;
    failures) do_failures ;;
    promote) do_promote ;;
    scan)    do_scan ;;
    stats)   do_stats ;;
esac

exit $EXIT_CODE
