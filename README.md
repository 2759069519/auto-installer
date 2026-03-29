# 🦞 Auto-Installer 万能补全器 v2.3 (Fixed)

> 遇到 `command not found` / `ModuleNotFoundError` / `Permission denied` 等报错时，自动搜索并安装所需工具。

## 🚀 快速使用

```bash
# 克隆到 OpenClaw 技能目录
git clone https://github.com/2759069519/auto-installer.git ~/.openclaw/skills/auto-installer

# 搜索工具
bash scripts/auto-install-search.sh "jq"

# 搜索并自动安装
bash scripts/auto-install-search.sh "fzf" --install

# 从报错推断（自动识别别名：rg → ripgrep）
bash scripts/auto-install-search.sh "command not found: rg" --install

# 中文关键词
bash scripts/auto-install-search.sh "压缩文件"
bash scripts/auto-install-search.sh "系统监控"

# 批量安装（走6层全链路搜索）
bash scripts/auto-install-search.sh --install ripgrep fzf jq bat tree

# 扫描系统已装工具
bash scripts/auto-install-search.sh --scan

# 查看安装统计
bash scripts/auto-install-search.sh --stats
```

## 🔒 v2.3 安全加固

| 问题 | 原版 (v2.2) | 修复版 (v2.3) |
|------|------------|--------------|
| pip 安装 | 直接 `--break-system-packages` | pipx → venv → 最后才 break |
| apt 锁 | `rm /var/lib/dpkg/lock*` | 等待锁释放 (fuser) |
| 远程脚本 | `curl \| bash` | 下载 → 预览 → 确认 |
| GPG 密钥 | deprecated `apt-key` | 现代 `gpg --dearmor` |
| JSONL | 强制 python3 | python3 + 纯 Bash 兜底 |

## 🌍 跨平台支持

自动检测并适配：apt / dnf / yum / pacman / brew / apk / zypper

## 📁 结构

```
├── SKILL.md                    # 技能文档
├── SECURITY.md                 # 安全文档
├── lib/
│   ├── platform.sh             # 跨平台检测
│   ├── security.sh             # 安全安装包装器
│   ├── inference.sh            # 增强推理 (40+ 别名)
│   └── logging.sh              # 纯 Bash 日志
├── scripts/
│   ├── auto-install-search.sh  # 主脚本
│   └── test-fixes.sh           # 修复验证测试
├── references/
│   └── task-tool-map.md        # 工具映射表
└── data/
    └── install-history.jsonl   # 安装历史
```

## 🧪 运行测试

```bash
bash scripts/test-fixes.sh
```

## 📋 6 层搜索

1. 固定映射表（秒级匹配 + 中英文双搜）
2. 智能推理（报错解析 + 40+ 命令别名）
3. 系统包管理器搜索（apt/dnf/yum/pacman/brew）
4. pip/npm 搜索
5. ClawHub 技能搜索
6. 学习记录

## 退出码

| 退出码 | 含义 |
|--------|------|
| 0 | 成功 |
| 1 | 参数错误 |
| 10 | 6层全部未命中 → agent 应联网搜索 |

## License

MIT
