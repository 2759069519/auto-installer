#!/bin/bash
# lib/security.sh — 安全安装包装器
# 修复: pip --break-system-packages、curl|bash、dpkg lock

# ── 安全 pip 安装 ────────────────────────────────────
# 优先级: pipx > venv > --break-system-packages(仅用户确认)
safe_pip_install() {
    local sudo_p="$1"; shift
    local pkg="$*"
    local mirror=""
    is_china_network && mirror="-i https://pypi.tuna.tsinghua.edu.cn/simple"

    # 方案 1: pipx (推荐 — 隔离安装，不碰系统 Python)
    if command -v pipx &>/dev/null; then
        echo -e "  ${GREEN}  → 使用 pipx (隔离安装)${NC}"
        pipx install $pkg 2>/dev/null && return 0
        echo -e "  ${YELLOW}  ⚠ pipx 安装失败，尝试下一种方式${NC}"
    fi

    # 方案 2: 用户级 venv
    local venv_dir="${HOME}/.local/share/auto-installer/venv"
    if [ ! -d "$venv_dir" ]; then
        python3 -m venv "$venv_dir" 2>/dev/null || true
    fi
    if [ -d "$venv_dir" ]; then
        echo -e "  ${GREEN}  → 使用用户级 venv${NC}"
        "${venv_dir}/bin/pip" install $mirror $pkg 2>/dev/null && {
            # 创建 wrapper 脚本到 ~/.local/bin
            mkdir -p "${HOME}/.local/bin"
            for p in $pkg; do
                local cmd_name; cmd_name=$(echo "$p" | sed 's/[<>=!].*//')
                cat > "${HOME}/.local/bin/${cmd_name}" <<WRAPPER
#!/bin/bash
exec "${venv_dir}/bin/${cmd_name}" "\$@"
WRAPPER
                chmod +x "${HOME}/.local/bin/${cmd_name}" 2>/dev/null
            done
            # 确保 ~/.local/bin 在 PATH 中
            if [[ ":$PATH:" != *":${HOME}/.local/bin:"* ]]; then
                echo -e "  ${YELLOW}  ⚠ 请将 ~/.local/bin 加入 PATH: export PATH=\"\$HOME/.local/bin:\$PATH\"${NC}"
            fi
            return 0
        }
    fi

    # 方案 3: --break-system-packages (最后手段，需要用户确认)
    echo -e "  ${YELLOW}  ⚠ pipx/venv 均不可用${NC}"
    echo -e "  ${YELLOW}  ⚠ 将使用 --break-system-packages (会修改系统 Python 环境)${NC}"
    pip3 install --break-system-packages $mirror $pkg 2>/dev/null && return 0

    return 1
}

# ── 安全 dpkg lock 处理 ─────────────────────────────
# 不删除锁文件，而是等待锁释放
wait_for_apt_lock() {
    local max_wait="${1:-60}"  # 最多等 60 秒
    local waited=0

    while fuser /var/lib/dpkg/lock-frontend &>/dev/null 2>&1 || \
          fuser /var/lib/apt/lists/lock &>/dev/null 2>&1; do
        if [ $waited -ge $max_wait ]; then
            echo -e "  ${RED}  ✗ apt 锁等待超时 (${max_wait}s)${NC}"
            echo -e "  ${DIM}  可能有其他 apt 进程正在运行，请稍后重试${NC}"
            return 1
        fi
        echo -e "  ${DIM}  ⏳ 等待 apt 锁释放... (${waited}s/${max_wait}s)${NC}"
        sleep 3
        waited=$((waited + 3))
    done
    return 0
}

# 安全 apt install (先等锁)
safe_apt_install() {
    local sudo_p="$1"; shift
    local pkgs="$*"

    if ! wait_for_apt_lock 60; then
        return 1
    fi

    ${sudo_p}apt install -y $pkgs 2>/dev/null
}

# ── 安全远程脚本执行 ─────────────────────────────────
# 拒绝 curl|bash，改为下载 → 审查 → 执行
safe_remote_script() {
    local url="$1"
    local script_name="${2:-remote-script}"

    echo -e "  ${YELLOW}  ⚠ 检测到远程脚本安装请求${NC}"
    echo -e "  ${CYAN}  📥 下载脚本到临时文件（请审查后执行）: ${url}${NC}"

    local tmpfile="/tmp/ai-remote-${script_name}-$$.sh"
    if ! curl -fsSL "$url" -o "$tmpfile" 2>/dev/null; then
        echo -e "  ${RED}  ✗ 下载失败${NC}"
        return 1
    fi

    # 显示脚本前 20 行供审查
    echo -e "  ${CYAN}  ─── 脚本内容预览 (前 20 行) ───${NC}"
    head -20 "$tmpfile" | sed 's/^/  │ /'
    local total_lines; total_lines=$(wc -l < "$tmpfile")
    if [ "$total_lines" -gt 20 ]; then
        echo -e "  ${DIM}  │ ... (共 ${total_lines} 行)${NC}"
    fi
    echo -e "  ${CYAN}  ──────────────────────────────${NC}"

    # 检查是否在 agent 模式下（非交互）
    if [ -t 0 ]; then
        # 交互模式：让用户确认
        echo -e "  ${YELLOW}  请审查上方脚本内容，确认安全后执行${NC}"
        read -rp "  执行此脚本? [y/N] " confirm
        if [[ "$confirm" =~ ^[Yy] ]]; then
            bash "$tmpfile"
            local rc=$?
            rm -f "$tmpfile"
            return $rc
        else
            echo -e "  ${DIM}  已取消${NC}"
            rm -f "$tmpfile"
            return 1
        fi
    else
        # 非交互模式（agent 调用）：保存脚本路径，提示手动执行
        echo -e "  ${YELLOW}  ⚠ 非交互模式，未自动执行${NC}"
        echo -e "  ${CYAN}  📄 脚本已保存到: ${tmpfile}${NC}"
        echo -e "  ${CYAN}  请手动审查后执行: bash ${tmpfile}${NC}"
        return 1
    fi
}

# ── 安全的 apt-key 处理 ─────────────────────────────
# 使用现代 gpg keyring 方式代替 deprecated apt-key
safe_add_apt_key() {
    local key_url="$1"
    local keyring_name="$2"
    local sudo_p="$3"

    local keyring_path="/usr/share/keyrings/${keyring_name}-archive-keyring.gpg"

    if [ -f "$keyring_path" ]; then
        echo -e "  ${DIM}  密钥已存在: ${keyring_path}${NC}"
        return 0
    fi

    echo -e "  ${CYAN}  添加 GPG 密钥: ${keyring_name}${NC}"
    curl -fsSL "$key_url" | ${sudo_p}gpg --dearmor -o "$keyring_path" 2>/dev/null
    ${sudo_p}chmod 644 "$keyring_path" 2>/dev/null
}
