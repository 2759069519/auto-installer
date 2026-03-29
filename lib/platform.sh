#!/bin/bash
# lib/platform.sh — 跨平台包管理器检测
# 支持: apt / dnf / yum / pacman / brew / apk / zypper

# 检测当前系统可用的包管理器
detect_pkg_manager() {
    PKMGR=""
    PKMGR_INSTALL=""

    if command -v apt &>/dev/null; then
        PKMGR="apt"
        PKMGR_INSTALL="apt_install"
    elif command -v dnf &>/dev/null; then
        PKMGR="dnf"
        PKMGR_INSTALL="dnf_install"
    elif command -v yum &>/dev/null; then
        PKMGR="yum"
        PKMGR_INSTALL="yum_install"
    elif command -v pacman &>/dev/null; then
        PKMGR="pacman"
        PKMGR_INSTALL="pacman_install"
    elif command -v apk &>/dev/null; then
        PKMGR="apk"
        PKMGR_INSTALL="apk_install"
    elif command -v zypper &>/dev/null; then
        PKMGR="zypper"
        PKMGR_INSTALL="zypper_install"
    elif command -v brew &>/dev/null; then
        PKMGR="brew"
        PKMGR_INSTALL="brew_install"
    else
        PKMGR="unknown"
        PKMGR_INSTALL="unknown_install"
    fi

    export PKMGR PKMGR_INSTALL
}

# 检测 OS 发行版
detect_os() {
    OS_ID=""
    OS_VERSION=""
    if [ -f /etc/os-release ]; then
        . /etc/os-release
        OS_ID="${ID:-}"
        OS_VERSION="${VERSION_ID:-}"
    elif [ "$(uname -s)" = "Darwin" ]; then
        OS_ID="macos"
        OS_VERSION=$(sw_vers -productVersion 2>/dev/null || echo "unknown")
    fi
    export OS_ID OS_VERSION
}

# 包名映射: 不同发行版同功能的包名可能不同
map_package_name() {
    local tool="$1"
    local from_mgr="${2:-$PKMGR}"

    case "${from_mgr}:${tool}" in
        # ripgrep
        dnf:ripgrep|yum:ripgrep) echo "ripgrep" ;;
        brew:ripgrep) echo "ripgrep" ;;
        pacman:ripgrep) echo "ripgrep" ;;

        # fd
        apt:fd) echo "fd-find" ;;
        dnf:fd|yum:fd) echo "fd-find" ;;
        brew:fd) echo "fd" ;;
        pacman:fd) echo "fd" ;;

        # bat
        apt:bat) echo "bat" ;;
        dnf:bat|yum:bat) echo "bat" ;;
        brew:bat) echo "bat" ;;

        # htop (all platforms have it)
        *:htop) echo "htop" ;;

        # btop
        *:btop) echo "btop" ;;

        # build tools
        apt:build-essential) echo "build-essential" ;;
        dnf:build-essential|yum:build-essential) echo "@development-tools" ;;
        pacman:build-essential) echo "base-devel" ;;
        brew:build-essential) echo "" ;; # Xcode CLI tools

        # openssl dev
        apt:libssl-dev) echo "libssl-dev" ;;
        dnf:libssl-dev|yum:libssl-dev) echo "openssl-devel" ;;
        pacman:libssl-dev) echo "openssl" ;;

        *) echo "$tool" ;;
    esac
}

# ── 包管理器安装函数 ──────────────────────────────────

apt_install() {
    local sudo_p="$1"; shift
    local pkgs="$*"
    ${sudo_p}apt install -y $pkgs 2>/dev/null
}

dnf_install() {
    local sudo_p="$1"; shift
    local pkgs="$*"
    ${sudo_p}dnf install -y $pkgs 2>/dev/null
}

yum_install() {
    local sudo_p="$1"; shift
    local pkgs="$*"
    ${sudo_p}yum install -y $pkgs 2>/dev/null
}

pacman_install() {
    local sudo_p="$1"; shift
    local pkgs="$*"
    ${sudo_p}pacman -S --noconfirm $pkgs 2>/dev/null
}

apk_install() {
    local sudo_p="$1"; shift
    local pkgs="$*"
    ${sudo_p}apk add $pkgs 2>/dev/null
}

zypper_install() {
    local sudo_p="$1"; shift
    local pkgs="$*"
    ${sudo_p}zypper install -y $pkgs 2>/dev/null
}

brew_install() {
    # brew 不需要 sudo
    local sudo_p="$1"; shift
    local pkgs="$*"
    brew install $pkgs 2>/dev/null
}

unknown_install() {
    return 1
}

# 通用安装入口: 根据包管理器分发
system_install() {
    local sudo_p="$1"; shift
    local tool="$1"
    local mapped; mapped=$(map_package_name "$tool" "$PKMGR")

    if [ -z "$mapped" ]; then
        echo -e "  ${YELLOW}  ⚠ ${tool} 在 ${PKMGR} 上无需额外安装${NC}"
        return 0
    fi

    $PKMGR_INSTALL "$sudo_p" "$mapped"
}

# 包管理器搜索
system_search() {
    local query="$1"
    local result=""

    case "$PKMGR" in
        apt)
            result=$(timeout 10 apt search "$query" 2>/dev/null | grep -v "^Sorting\|^Full Text\|^WARNING" | grep -i "$query" | head -5 || true)
            ;;
        dnf|yum)
            result=$(timeout 10 $PKMGR search "$query" 2>/dev/null | grep -i "$query" | head -5 || true)
            ;;
        pacman)
            result=$(timeout 10 pacman -Ss "$query" 2>/dev/null | grep -i "$query" | head -5 || true)
            ;;
        brew)
            result=$(timeout 10 brew search "$query" 2>/dev/null | head -5 || true)
            ;;
        apk)
            result=$(timeout 10 apk search "$query" 2>/dev/null | grep -i "$query" | head -5 || true)
            ;;
    esac

    echo "$result"
}

# 检查系统包是否已安装
system_is_installed() {
    local pkg="$1"
    case "$PKMGR" in
        apt)
            dpkg -s "$pkg" 2>/dev/null | grep -q "Status: install ok installed"
            ;;
        dnf|yum)
            $PKMGR list installed "$pkg" &>/dev/null
            ;;
        pacman)
            pacman -Qi "$pkg" &>/dev/null
            ;;
        brew)
            brew list "$pkg" &>/dev/null
            ;;
        apk)
            apk info -e "$pkg" &>/dev/null
            ;;
        *)
            return 1
            ;;
    esac
}

# 初始化
detect_os
detect_pkg_manager
