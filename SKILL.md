---
name: auto-installer
description: "遇到 command not found / ModuleNotFoundError / Permission denied 等报错时，自动搜索并安装所需依赖工具。支持跨平台系统包管理器 + pip/npm 降级链 + 自学习 + 自动回写映射表 + JSONL历史 + 已装检测 + 批量安装走6层全链路。安全加固: pip 隔离安装、不删除 apt 锁。"
version: "2.3.0"
tags: [installer, resolver, auto-fix, dependency, self-learning, batch, auto-writeback, cross-platform]
---

# 🦞 Auto-Installer 万能补全器 v2.3 (Fixed)

> **任何阻碍 → 自动解决。成功学，失败也学。越用越强。**

## 🔒 v2.3 安全加固

- **pip 安装**: 优先使用 pipx (隔离) → venv → 最后才 --break-system-packages
- **apt 锁**: 等待锁释放（最多 60s），**绝不删除** `/var/lib/dpkg/lock*`
- **远程脚本**: 拒绝 `curl | bash`，改为下载 → 预览 → 用户确认
- **GPG 密钥**: 使用现代 `gpg --dearmor` 而非 deprecated `apt-key`
- **JSONL 记录**: 纯 Bash 兜底，不强制依赖 python3

## 🌍 v2.3 跨平台支持

自动检测当前系统包管理器，自动映射包名：

| 平台 | 包管理器 | 状态 |
|------|---------|------|
| Debian/Ubuntu | apt | ✅ 完全支持 |
| RHEL/CentOS/Fedora | dnf/yum | ✅ 支持 |
| Arch Linux | pacman | ✅ 支持 |
| macOS | brew | ✅ 支持 |
| Alpine | apk | ✅ 支持 |
| openSUSE | zypper | ✅ 支持 |

## 📁 文件结构

```
auto-installer/
├── SKILL.md                    # 本文件
├── README.md
├── SECURITY.md                 # 安全文档
├── lib/
│   ├── platform.sh             # 跨平台包管理器检测
│   ├── security.sh             # 安全安装包装器
│   ├── inference.sh            # 增强版智能推理
│   └── logging.sh              # 纯 Bash JSONL 记录
├── scripts/
│   └── auto-install-search.sh  # 主脚本（模块化）
├── references/
│   ├── task-tool-map.md        # 工具映射表
│   ├── learned-tools.log
│   ├── failed-installs.log
│   └── usage-stats.json
└── data/
    ├── install-history.jsonl
    └── installed-index.json
```

## 🎯 触发条件

| 触发类型 | 示例 |
|---------|------|
| exec 报错 | `command not found`, `ModuleNotFoundError`, `Permission denied` 等 |
| 用户表达 | "帮我装"、"找工具"、"不会做"、"报错了"、"搞不定" |
| agent 判断 | 任务需要某个能力但当前环境不具备 |

## 🔄 执行流程（6 层递进 + 自学习 + 自动回写）

```
第 1 层: 查固定映射表  ──→  秒级匹配，中英文双搜（含中文别名表）
    ↓ 未命中
第 2 层: 智能推理      ──→  从报错推断依赖 + 别名匹配映射表（含40+别名）
    ↓ 无法推断
第 3 层: 搜索系统包    ──→  apt/dnf/yum/pacman/brew 搜索
    ↓ 未找到
第 4 层: 搜索 pip/npm  ──→  Python / Node 包管理器搜索
    ↓ 未找到
第 5 层: ClawHub 技能  ──→  搜索 ClawHub 技能库
    ↓ 未找到
第 6 层: 学习记录      ──→  查询历史成功/失败学习记录
    ↓ 全部失败 → 退出码 10 → agent 联网搜索
```

---

### 📖 第 1 层：查固定映射表（秒级）

读取 `references/task-tool-map.md`，按报错信息或任务描述匹配关键词。

**中文支持**：同时搜索工具名（英文）和描述（中文），如"压缩文件"能匹配到 `zip`/`p7zip-full` 等。

- ✅ 匹配到 → 按**安装降级链**执行 → 重试原任务
- ❌ 未命中 → 进入第 2 层

### 🧠 第 2 层：智能推理

解析报错信息，自动推断依赖（含 40+ 常见命令别名）：

| 报错格式 | 推断结果 |
|---------|---------|
| `command not found: xxx` | 查别名表 → 系统工具 xxx |
| `ModuleNotFoundError: 'xxx'` | 查 Python→系统映射 → Python 包 xxx |
| `Cannot find module 'xxx'` | Node 模块 xxx |
| `libxxx.so: cannot open` | 系统库 libxxx-dev |
| `ImportError: libGL.so.1` | libgl1-mesa-glx |
| `Permission denied` | chmod 权限问题 |
| `No space left on device` | ncdu 磁盘分析 |

- ✅ 推断成功 → 执行降级链
- ❌ 无法推断 → 进入第 3 层

### 📦 第 3-5 层：包管理器搜索

依次搜索系统包管理器 → pip/npm → ClawHub。

### 📚 第 6 层：学习记录

查询 `references/learned-tools.log` 和 `references/failed-installs.log`。

---

## 🔧 安装降级链

每条工具支持多路径安装，首选失败自动降级：

```
apt(系统包) → snap → pip(安全模式) → npm → dl(GitHub Release) → src(源码编译) → go → pipx
```

安装前自动检查是否已安装（command + 系统包管理器），避免重复操作。

安装成功后：
1. ✅ 自动验证命令可用
2. ✅ 自动记录到 `learned-tools.log`
3. ✅ **自动回写**到 `task-tool-map.md`
4. ✅ 记录到 `data/install-history.jsonl`
5. ✅ 更新使用统计

安装失败后：
1. ✅ 记录到 `failed-installs.log`
2. ✅ 24h 内自动跳过同路径
3. ✅ 记录到 JSONL 历史（success=false）

---

## 📋 命令参考

```bash
# 搜索（不安装）
bash scripts/auto-install-search.sh "关键词"

# 搜索 + 自动安装
bash scripts/auto-install-search.sh "关键词" --install

# 从报错安装（智能推理）
bash scripts/auto-install-search.sh "command not found: rg" --install

# 中文关键词
bash scripts/auto-install-search.sh "压缩文件" --install

# 批量安装
bash scripts/auto-install-search.sh --install ripgrep fzf jq bat tree

# 手动学习
bash scripts/auto-install-search.sh --learn "lazydocker" "Docker管理TUI"

# 整理学习记录到映射表
bash scripts/auto-install-search.sh --promote

# 查看历史 / 失败记录 / 统计 / 扫描
bash scripts/auto-install-search.sh --history
bash scripts/auto-install-search.sh --failures
bash scripts/auto-install-search.sh --stats
bash scripts/auto-install-search.sh --scan

# 查看版本
bash scripts/auto-install-search.sh --version
```

## 退出码

| 退出码 | 含义 |
|--------|------|
| 0 | 成功 |
| 1 | 参数错误 |
| 10 | 6层全部未命中 → agent 应联网搜索 |

当退出码为 10 时，agent 应调用 `mimo_web_search` 搜索并手动安装。

---

## ⚠️ 与原版 v2.2 的区别

| 维度 | v2.2 (原版) | v2.3 (修复版) |
|------|------------|--------------|
| pip 安装 | 直接 `--break-system-packages` | pipx → venv → 最后才 break |
| apt 锁 | `rm /var/lib/dpkg/lock*` | 等待锁释放 |
| 远程脚本 | `curl \| bash` | 下载 → 预览 → 确认 |
| 平台 | 仅 apt | apt/dnf/yum/pacman/brew/apk |
| 推理别名 | 基础 | 40+ 命令别名 + Python→系统映射 |
| JSONL 记录 | 强制 python3 | python3 + 纯 Bash 兜底 |
| 脚本结构 | 967 行单文件 | 模块化 (lib/ + 主脚本) |
