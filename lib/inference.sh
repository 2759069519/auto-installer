#!/bin/bash
# lib/inference.sh — 增强版智能推理
# 从报错信息推断需要安装的工具

# 常见命令别名表
declare -A CMD_ALIASES=(
    [rg]="ripgrep"
    [fd]="fd-find"
    [bat]="bat"
    [ag]="silversearcher-ag"
    [batcat]="bat"
    [pip]="python3-pip"
    [python]="python3"
    [node]="nodejs"
    [nc]="netcat-openbsd"
    [cc]="build-essential"
    [g++]="build-essential"
    [gcc]="build-essential"
    [make]="build-essential"
    [docker-compose]="docker-compose-v2"
    [pygmentize]="python3-pygments"
    [convert]="imagemagick"
    [identify]="imagemagick"
    [mogrify]="imagemagick"
    [dot]="graphviz"
    [tshark]="tshark"
    [mysql]="mysql-client"
    [psql]="postgresql-client"
    [redis-cli]="redis-tools"
    [mongosh]="mongosh"
    [git-delta]="git-delta"
    [lazygit]="lazygit"
    [lazydocker]="lazydocker"
    [fzf]="fzf"
    [zoxide]="zoxide"
    [btop]="btop"
    [htop]="htop"
    [ncdu]="ncdu"
    [jq]="jq"
    [yq]="yq"
    [mlr]="miller"
    [cwebp]="webp"
    [dwebp]="webp"
    [tesseract]="tesseract-ocr"
)

# 常见 Python 包名 → 系统包名映射
declare -A PYTHON_TO_SYSTEM=(
    [cv2]="python3-opencv"
    [PIL]="python3-pil"
    [yaml]="python3-yaml"
    [gi]="python3-gi"
    [gi.repository]="python3-gi"
    [dbus]="python3-dbus"
    [apt]="python3-apt"
    [lxml]="python3-lxml"
)

infer_from_error() {
    local input="$1"
    local tool="" cmd="" chain="" type=""

    # ── command not found ──
    if [[ "$input" =~ command[[:space:]]+not[[:space:]]+found:?[\ ]*([a-zA-Z0-9._-]+) ]]; then
        tool="${BASH_REMATCH[1]}"
        cmd="$tool"

        # 查别名表
        if [ -n "${CMD_ALIASES[$tool]:-}" ]; then
            local mapped="${CMD_ALIASES[$tool]}"
            echo "tool=${mapped} cmd=${tool} chain=apt ${mapped} type=command_alias"
            return 0
        fi

        # 尝试从映射表中匹配 (tool) 格式
        if [ -f "$MAP_FILE" ]; then
            local match; match=$(grep -i "(${tool})" "$MAP_FILE" 2>/dev/null | head -1 || true)
            if [ -n "$match" ]; then
                local m_chain m_cmd
                m_chain=$(echo "$match" | awk -F'|' '{print $4}' | xargs | tr -d '`')
                m_cmd=$(echo "$match" | awk -F'|' '{print $3}' | xargs | tr -d '`')
                echo "tool=${m_cmd} cmd=${tool} chain=${m_chain} type=command_alias_map"
                return 0
            fi
        fi

        echo "tool=${tool} cmd=${tool} chain=apt ${tool} type=command"
        return 0
    fi

    # ── ModuleNotFoundError ──
    if [[ "$input" =~ ModuleNotFoundError.*[\'\"]([a-zA-Z0-9_.-]+)[\'\"] ]]; then
        tool="${BASH_REMATCH[1]}"
        # 尝试系统包
        if [ -n "${PYTHON_TO_SYSTEM[$tool]:-}" ]; then
            local sys_pkg="${PYTHON_TO_SYSTEM[$tool]}"
            echo "tool=${sys_pkg} cmd=${tool} chain=apt ${sys_pkg} type=python_system"
            return 0
        fi
        echo "tool=${tool} cmd=${tool} chain=pip ${tool} type=python"
        return 0
    fi

    # ── Cannot find module (Node.js) ──
    if [[ "$input" =~ Cannot[[:space:]]+find[[:space:]]+module[\ ]*[\'\"]([a-zA-Z0-9_.@/-]+)[\'\"] ]]; then
        tool="${BASH_REMATCH[1]}"
        echo "tool=${tool} cmd=${tool} chain=npm install -g ${tool} type=node"
        return 0
    fi

    # ── ImportError ──
    if [[ "$input" =~ ImportError:[[:space:]]*([a-zA-Z0-9_.-]+) ]]; then
        tool="${BASH_REMATCH[1]}"
        if [ -n "${PYTHON_TO_SYSTEM[$tool]:-}" ]; then
            local sys_pkg="${PYTHON_TO_SYSTEM[$tool]}"
            echo "tool=${sys_pkg} cmd=${tool} chain=apt ${sys_pkg} type=python_system"
            return 0
        fi
        echo "tool=${tool} cmd=${tool} chain=pip ${tool} type=python"
        return 0
    fi

    # ── Shared library ──
    if [[ "$input" =~ loading[[:space:]]+shared[[:space:]]+libraries:.*lib([a-zA-Z0-9_.-]+)\.so ]]; then
        local lib="${BASH_REMATCH[1]}"
        tool="lib${lib}-dev"
        echo "tool=${tool} cmd=${tool} chain=apt ${tool} type=library"
        return 0
    fi

    # ── ImportError: libGL.so.1 ──
    if [[ "$input" =~ libGL ]]; then
        echo "tool=libgl1-mesa-glx cmd=libgl1-mesa-glx chain=apt libgl1-mesa-glx type=library"
        return 0
    fi

    # ── Permission denied ──
    if [[ "$input" =~ Permission[[:space:]]+denied ]]; then
        echo "tool=chmod cmd=chmod chain= type=builtin"
        return 0
    fi

    # ── No space left on device ──
    if [[ "$input" =~ No[[:space:]]+space[[:space:]]+left ]]; then
        echo "tool=ncdu cmd=ncdu chain=apt ncdu type=diagnostic"
        return 0
    fi

    # ── Connection refused ──
    if [[ "$input" =~ Connection[[:space:]]+refused ]]; then
        echo "tool=systemctl cmd=systemctl chain= type=builtin"
        return 0
    fi

    # ── SSL certificate ──
    if [[ "$input" =~ SSL[[:space:]]+certificate ]]; then
        echo "tool=ca-certificates cmd=update-ca-certificates chain=apt ca-certificates type=library"
        return 0
    fi

    # ── dpkg lock ──
    if [[ "$input" =~ dpkg.*lock ]]; then
        echo "tool=dpkg cmd=dpkg chain= type=builtin"
        return 0
    fi

    # ── cargo/rust 未安装 ──
    if [[ "$input" =~ cargo ]] && ! command -v cargo &>/dev/null; then
        echo "tool=cargo cmd=cargo chain=apt rustc cargo type=dev"
        return 0
    fi

    return 1
}
