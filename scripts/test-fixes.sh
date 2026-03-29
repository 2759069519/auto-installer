#!/bin/bash
# ============================================================
# test-fixes.sh — 验证 v2.3 修复项
# 用法: bash scripts/test-fixes.sh
# ============================================================
set -uo pipefail

GREEN='\033[0;32m'; RED='\033[0;31m'; YELLOW='\033[1;33m'
CYAN='\033[0;36m'; BOLD='\033[1m'; NC='\033[0m'

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
SKILL_DIR="${SCRIPT_DIR}/.."
PASS=0 FAIL=0

check() {
    local name="$1"; shift
    if "$@" >/dev/null 2>&1; then
        echo -e "  ${GREEN}✅ PASS${NC} ${name}"
        PASS=$((PASS+1))
    else
        echo -e "  ${RED}❌ FAIL${NC} ${name}"
        FAIL=$((FAIL+1))
    fi
}

check_not() {
    local name="$1"; shift
    if "$@" >/dev/null 2>&1; then
        echo -e "  ${RED}❌ FAIL${NC} ${name}"
        FAIL=$((FAIL+1))
    else
        echo -e "  ${GREEN}✅ PASS${NC} ${name}"
        PASS=$((PASS+1))
    fi
}

echo ""
echo -e "${BOLD}${CYAN}🧪 auto-installer v2.3 修复验证${NC}"
echo ""

# ── 文件结构 ──
echo -e "${BOLD}📁 文件结构${NC}"
check "主脚本存在" test -f "${SKILL_DIR}/scripts/auto-install-search.sh"
check "platform.sh 存在" test -f "${SKILL_DIR}/lib/platform.sh"
check "security.sh 存在" test -f "${SKILL_DIR}/lib/security.sh"
check "inference.sh 存在" test -f "${SKILL_DIR}/lib/inference.sh"
check "logging.sh 存在" test -f "${SKILL_DIR}/lib/logging.sh"
check "SECURITY.md 存在" test -f "${SKILL_DIR}/SECURITY.md"
check "映射表存在" test -f "${SKILL_DIR}/references/task-tool-map.md"

echo ""

# ── 语法检查 ──
echo -e "${BOLD}📝 语法检查${NC}"
check "主脚本 bash 语法" bash -n "${SKILL_DIR}/scripts/auto-install-search.sh"
check "platform.sh 语法" bash -n "${SKILL_DIR}/lib/platform.sh"
check "security.sh 语法" bash -n "${SKILL_DIR}/lib/security.sh"
check "inference.sh 语法" bash -n "${SKILL_DIR}/lib/inference.sh"
check "logging.sh 语法" bash -n "${SKILL_DIR}/lib/logging.sh"

echo ""

# ── 安全检查 ──
echo -e "${BOLD}🔒 安全检查${NC}"
# grep 检查辅助函数
_grep_file() { grep -q "$2" "$3"; }
_grep_pipe() { grep -vE "$2" "$4" | grep -q "$3"; }

check "主脚本无直接 rm lock 文件" bash -c "! grep -vE '^\s*#' '${SKILL_DIR}/scripts/auto-install-search.sh' | grep -q 'rm.*dpkg.*lock'"
# 检查主脚本中没有实际执行 curl|bash (排除注释和 echo 提示)
_no_curl_bash() {
    ! grep -vE '^\s*#|echo ' "$1" | grep -qE 'curl\s.*\|\s*bash'
}
check "主脚本无直接 curl|bash" _no_curl_bash "${SKILL_DIR}/scripts/auto-install-search.sh"
check "pip 安装走 safe_pip_install" grep -q 'safe_pip_install' "${SKILL_DIR}/scripts/auto-install-search.sh"
check "apt 安装走 safe_apt_install" grep -q 'safe_apt_install' "${SKILL_DIR}/scripts/auto-install-search.sh"
check "security.sh 定义 safe_pip_install" grep -q 'safe_pip_install' "${SKILL_DIR}/lib/security.sh"
check "security.sh 定义 safe_apt_install" grep -q 'safe_apt_install' "${SKILL_DIR}/lib/security.sh"
check "security.sh 定义 wait_for_apt_lock" grep -q 'wait_for_apt_lock' "${SKILL_DIR}/lib/security.sh"
check "security.sh 定义 safe_remote_script" grep -q 'safe_remote_script' "${SKILL_DIR}/lib/security.sh"

echo ""

# ── 跨平台检查 ──
echo -e "${BOLD}🌍 跨平台检查${NC}"
check "platform.sh 支持 dnf" grep -q 'dnf' "${SKILL_DIR}/lib/platform.sh"
check "platform.sh 支持 yum" grep -q 'yum' "${SKILL_DIR}/lib/platform.sh"
check "platform.sh 支持 pacman" grep -q 'pacman' "${SKILL_DIR}/lib/platform.sh"
check "platform.sh 支持 brew" grep -q 'brew' "${SKILL_DIR}/lib/platform.sh"
check "platform.sh 支持 apk" grep -q 'apk' "${SKILL_DIR}/lib/platform.sh"
check "主脚本使用 system_install" grep -q 'system_install' "${SKILL_DIR}/scripts/auto-install-search.sh"
check "主脚本使用 system_search" grep -q 'system_search' "${SKILL_DIR}/scripts/auto-install-search.sh"

echo ""

# ── 推理增强检查 ──
echo -e "${BOLD}🧠 推理增强检查${NC}"
check "inference.sh 包含 CMD_ALIASES" grep -q 'CMD_ALIASES' "${SKILL_DIR}/lib/inference.sh"
check "inference.sh 包含 PYTHON_TO_SYSTEM" grep -q 'PYTHON_TO_SYSTEM' "${SKILL_DIR}/lib/inference.sh"
check "inference.sh 覆盖 rg→ripgrep" grep -q 'rg.*ripgrep' "${SKILL_DIR}/lib/inference.sh"
check "inference.sh 覆盖 fd→fd-find" grep -q 'fd.*fd-find' "${SKILL_DIR}/lib/inference.sh"
check "inference.sh 覆盖 ImportError" grep -q 'ImportError' "${SKILL_DIR}/lib/inference.sh"
check "inference.sh 覆盖 No space" grep -q 'No.*space' "${SKILL_DIR}/lib/inference.sh"

echo ""

# ── logging 检查 ──
echo -e "${BOLD}📝 Logging 检查${NC}"
check "logging.sh 包含纯 Bash JSONL" grep -q 'json_escape' "${SKILL_DIR}/lib/logging.sh"
check "logging.sh 包含纯 Bash 统计" grep -q 'sed -i' "${SKILL_DIR}/lib/logging.sh"

echo ""

# ── 文档检查 ──
echo -e "${BOLD}📖 文档检查${NC}"
check "SKILL.md 版本 2.3" grep -q '2.3' "${SKILL_DIR}/SKILL.md"
check "SKILL.md 提及安全加固" grep -q '安全加固' "${SKILL_DIR}/SKILL.md"
check "SKILL.md 提及跨平台" grep -q '跨平台' "${SKILL_DIR}/SKILL.md"
check_not "映射表残留 break-system-packages" grep -qE 'pip3 install --break' "${SKILL_DIR}/references/task-tool-map.md"

echo ""

# ── 功能测试 ──
echo -e "${BOLD}⚙️  功能测试${NC}"

# 测试 platform.sh 加载
if source "${SKILL_DIR}/lib/platform.sh" 2>/dev/null; then
    check "platform.sh 可加载" true
    check "PKMGR 已设置" test -n "$PKMGR"
    check "PKMGR 非 unknown" test "$PKMGR" != "unknown"
    echo -e "  ${CYAN}ℹ  检测到包管理器: ${PKMGR}${NC}"
else
    check "platform.sh 可加载" false
fi

# 测试 security.sh 加载
check "security.sh 可加载" source "${SKILL_DIR}/lib/security.sh" 2>/dev/null

# 测试 inference.sh 加载
check "inference.sh 可加载" source "${SKILL_DIR}/lib/inference.sh" 2>/dev/null

# 测试 logging.sh 加载
check "logging.sh 可加载" source "${SKILL_DIR}/lib/logging.sh" 2>/dev/null

# 测试推理功能
if source "${SKILL_DIR}/lib/inference.sh" 2>/dev/null; then
    local_result=$(infer_from_error "command not found: rg" 2>/dev/null || true)
    check "推理: command not found rg" test -n "$local_result"
    local_result2=$(infer_from_error "ModuleNotFoundError: No module named 'pandas'" 2>/dev/null || true)
    check "推理: ModuleNotFoundError pandas" test -n "$local_result2"
    local_result3=$(infer_from_error "Permission denied" 2>/dev/null || true)
    check "推理: Permission denied" test -n "$local_result3"
fi

# 测试 json_escape
if source "${SKILL_DIR}/lib/logging.sh" 2>/dev/null; then
    escaped=$(json_escape 'hello "world" \\test' 2>/dev/null || true)
    check "json_escape 转义引号" echo "$escaped" | grep -q '\\\\'
fi

echo ""

# ── 汇总 ──
echo -e "${BOLD}${CYAN}════════════════════════════════════${NC}"
echo -e "${BOLD}  结果: ${GREEN}${PASS} 通过${NC} / ${RED}${FAIL} 失败${NC}"
echo -e "${BOLD}${CYAN}════════════════════════════════════${NC}"
echo ""

if [ "$FAIL" -eq 0 ]; then
    echo -e "  ${GREEN}${BOLD}🎉 全部通过！${NC}"
    exit 0
else
    echo -e "  ${RED}${BOLD}⚠ 有 ${FAIL} 项未通过${NC}"
    exit 1
fi
