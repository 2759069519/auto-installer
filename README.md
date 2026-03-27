# 🦞 Auto-Installer 万能补全器

> **任何阻碍 → 自动解决。不问用户，直接干。**

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
│   └── task-tool-map.md               # 任务→工具映射表 (200+)，含降级链
└── scripts/
    └── auto-install-search.sh         # 5层搜索 + 自动安装脚本
```

## 🚀 安装

```bash
# 克隆到 OpenClaw 技能目录
git clone https://github.com/2759069519/auto-installer.git ~/.openclaw/skills/auto-installer
```

## 📖 使用

### 仅搜索

```bash
bash scripts/auto-install-search.sh "JSON"
```

### 搜索并自动安装

```bash
bash scripts/auto-install-search.sh "json-server" --install
```

## 🔗 安装降级链

每个工具支持多路径安装，首选失败自动尝试下一条：

```
CLI 工具: apt → snap → pipx → npm → GitHub Release → 源码编译
Python 库: pip → pip(清华镜像) → conda
```

自动检测国内网络，GitHub 下载走 `ghfast.top` 镜像加速。

## 📋 映射表覆盖范围

| 分类 | 工具数 |
|------|--------|
| 📂 文件搜索 & 操作 | 10 |
| 📊 数据处理 | 7 |
| 🌐 网络 & API | 15 |
| 📄 文档处理 | 11 |
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
| 🐍 Python 数据科学 | 19 |
| 🦞 ClawHub 技能 | 6 |

## 📄 License

MIT
