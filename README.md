# 🦞 Auto-Installer 万能补全器

> **任何阻碍 → 自动解决。不问用户，直接干。**
>
> `v1.2.0` · MIT License

OpenClaw 智能技能：遇到任何环境阻碍（命令找不到、模块缺失、权限问题等）时，自动分析并解决。

---

## ✨ 特性

- **5 层递进搜索**：映射表 → 智能推理 → 系统包搜索 → 联网搜索 → 创造方案
- **安装降级链**：每条工具支持多路径安装（apt→snap→pip→npm→手动下载），首选失败自动降级
- **国内镜像加速**：自动检测网络环境，GitHub 走 `ghfast.top` 镜像，pip 走清华源
- **全场景覆盖**：文件搜索、数据处理、网络、文档、图片、音视频、开发、DevOps、数据库等 15+ 分类
- **200+ 工具映射**：任务描述直接对应安装命令，秒级响应
- **自我学习**：每次解决新问题后自动更新映射表

## 📁 项目结构

```
auto-installer/
├── SKILL.md                           # 技能主文档
├── references/
│   └── task-tool-map.md               # 任务→工具映射表 (213)，含降级链
└── scripts/
    └── auto-install-search.sh         # 5层搜索 + 自动安装脚本
```

## 🚀 安装

```bash
git clone https://github.com/2759069519/auto-installer.git ~/.openclaw/skills/auto-installer
```

## 📖 使用

### 搜索模式

```bash
bash scripts/auto-install-search.sh "jq"
```

输出示例：

```
╔══════════════════════════════════════════════════════╗
║  🦞 Auto-Installer 5 层智能搜索                     ║
╚══════════════════════════════════════════════════════╝
  关键词: jq
  网络: 检测到国内环境，将使用镜像加速

━━━ 第 1 层: 固定映射表 ━━━
| 处理 JSON | `jq` | `apt jq → dl github.com/jqlang/jq` |
  ✓ 映射表命中！

━━━ 第 2 层: 系统包 (apt/snap) ━━━
jq for binary formats (program)

━━━ 第 3 层: Python / Node 包 ━━━
pip: jq (1.11.0)
npm: jq — Server-side jQuery wrapper for node.

╔══════════════════════════════════════════════════════╗
║  ✅ 高置信：映射表命中                                ║
║  降级链: apt jq → dl github.com/jqlang/jq            ║
╚══════════════════════════════════════════════════════╝
```

### 自动安装模式

```bash
bash scripts/auto-install-search.sh "jq" --install
```

映射表命中后自动按降级链安装，安装完验证命令是否可用。

## 🔗 安装降级链

每个工具支持多路径安装，首选失败自动尝试下一条：

```
CLI 工具:  apt → snap → pipx → npm → GitHub Release → 源码编译
Python 库: pip → pip(清华镜像) → conda
```

自动检测国内网络，GitHub 下载走 `ghfast.top` 镜像加速。

## 📋 映射表覆盖范围

| 分类 | 工具数 |
|------|--------|
| 📂 文件搜索 & 操作 | 10 |
| 📊 数据处理 (JSON/YAML/XML/CSV) | 7 |
| 🌐 网络 & API | 15 |
| 📄 文档处理 (PDF/Word/Excel/PPT) | 11 |
| 🖼️ 图片处理 | 12 |
| 🎵 音频处理 | 8 |
| 🎬 视频处理 | 3 |
| 📦 压缩归档 | 9 |
| 🔐 SSH & 远程 & 容器 | 7 |
| 🛠️ 开发基础 | 15 |
| ☁️ DevOps & 云原生 | 10 |
| 🗄️ 数据库客户端 | 5 |
| 📡 系统监控 & 调试 | 12 |
| ⚡ 终端效率 | 6 |
| 🔒 安全 & 加密 | 6 |
| 🐍 Python 数据科学 & ML | 19 |
| 🦞 ClawHub 技能 | 6 |
| 🧩 常见报错修复 | 16 |
| 🔧 常用组合安装 | 7 |

## 📝 Changelog

### v1.2.0-fix (2026-03-27)

- 🐛 修复 npm "No matches found" 误判为命中结果
- 🐛 所有包管理器搜索加 timeout 保护（apt/snap/pip 10s, npm 10s, npx 15s）
- 🔧 jq GitHub 地址 `stedolan/jq` → `jqlang/jq`
- 🔧 SKILL.md description 精简（170字 → 55字，提高技能匹配精度）
- 🔧 新增 pip `--break-system-packages` 安全提示

### v1.2.0 (2026-03-27)

- ✨ 每个工具增加安装降级链 (apt→snap→pip→npm→手动下载)
- ✨ 自动检测国内网络，GitHub 走 ghfast.top 镜像
- ✨ pip 自动切换清华源
- ✨ `--install` 自动安装模式
- ✨ 新增 snap 搜索层
- ✨ 200+ 工具全部更新为降级链格式

### v1.1.0 (2026-03-18)

- ✨ 初始版本，基础搜索 + 安装功能

## 📄 License

MIT
