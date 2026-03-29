# 🔒 安全文档 — auto-installer v2.3

## 已修复的安全问题

### 1. pip 安装绕过系统限制

**原版 (v2.2):** 无条件使用 `pip3 install --break-system-packages`
**风险:** 破坏系统 Python 环境，可能导致系统工具依赖冲突
**修复 (v2.3):** 三级降级策略

```
pipx (隔离安装，推荐)
  ↓ 失败
venv (用户级虚拟环境: ~/.local/share/auto-installer/venv)
  ↓ 失败
--break-system-packages (最后手段，仅在前两者不可用时)
```

### 2. apt 锁文件处理

**原版 (v2.2):** `rm /var/lib/dpkg/lock* && dpkg --configure -a`
**风险:** 如果 dpkg 正在运行，删除锁文件会导致包管理系统损坏
**修复 (v2.3):** 使用 `fuser` 检测锁持有进程，等待最多 60 秒

### 3. 远程脚本执行

**原版 (v2.2):** `curl -fsSL https://get.docker.com | bash` (在映射表中)
**风险:** 不可审计的远程代码执行
**修复 (v2.3):**
- 降级链中的 `curl` 方法被拦截，不会自动执行
- 提供 `safe_remote_script()` 函数：下载 → 预览前 20 行 → 交互确认
- 非交互模式下保存到临时文件并提示手动执行

### 4. GPG 密钥管理

**原版 (v2.2):** 使用 deprecated `apt-key adv`
**修复 (v2.3):** 使用 `safe_add_apt_key()` → `curl | gpg --dearmor` + 现代 keyring 路径

### 5. JSONL 记录依赖

**原版 (v2.2):** 每次写 JSONL 都调用 `python3 -c "import json..."`
**风险:** 目标环境可能没有 python3（正是需要安装的工具）
**修复 (v2.3):** 优先 python3，失败时纯 Bash 兜底

## 不变的安全规则

- 脚本不需要网络访问（除了下载工具时）
- 不读取/修改系统密钥文件
- 不修改 OpenClaw 配置
- 不外发任何数据
- 所有安装操作需要 sudo 时提示用户

## 使用建议

1. **生产环境**: 建议先用 `--scan` 了解当前环境，用搜索模式确认结果后再安装
2. **批量安装**: 建议先单个测试，确认降级链正确后再批量
3. **敏感环境**: 用 `--learn` 手动学习已知安全的工具，避免自动搜索未知包
