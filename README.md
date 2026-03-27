# 🦞 Auto-Installer 万能补全器

> **任何阻碍 → 自动解决。不问用户，直接干。**

OpenClaw 智能技能：遇到任何环境阻碍（命令找不到、模块缺失、权限问题等）时，自动分析并解决。

---

## ✨ 特性

- **5 层递进搜索**：映射表 → 智能推理 → 系统包搜索 → 联网搜索 → 创造方案
- **全场景覆盖**：文件搜索、数据处理、网络、文档、图片、音视频、开发、DevOps、数据库等 15+ 分类
- **200+ 工具映射**：任务描述直接对应安装命令，秒级响应
- **自我学习**：每次解决新问题后自动更新映射表

## 📁 项目结构

```
auto-installer/
├── SKILL.md                           # 技能主文档
├── references/
│   └── task-tool-map.md               # 任务→工具全场景映射表 (200+)
└── scripts/
    └── auto-install-search.sh         # 5层智能搜索脚本
```

## 🚀 安装

### 方式一：手动安装

```bash
git clone https://github.com/2759069519/auto-installer.git ~/.openclaw/skills/auto-installer
```

### 方式二：ClawHub（推荐）

```bash
npx clawhub install auto-installer --workdir ~/.openclaw
```

## 📋 映射表覆盖范围

| 分类 | 工具数量 |
|------|---------|
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
| 🗄️ 数据库客户端 | 6 |
| 📡 系统监控 & 调试 | 12 |
| ⚡ 终端效率 | 7 |
| 🔒 安全 & 加密 | 6 |
| 🐍 Python 数据科学 | 19 |
| 🦞 ClawHub 技能 | 8 |

## 🧠 5 层执行流程

```
第 1 层: 查固定映射表  ──→  秒级匹配，最快路径
    ↓ 未命中
第 2 层: 智能推理      ──→  不需要网络，从报错推断
    ↓ 无法推断
第 3 层: 搜索系统包    ──→  apt / pip / npm 内部搜索
    ↓ 未找到
第 4 层: 联网搜索      ──→  web search 找方案（兜底）
    ↓ 全部失败
第 5 层: 创造方案      ──→  自己写脚本/代码解决（终极手段）
```

## 🔧 快速使用

### 搜索工具

```bash
bash scripts/auto-install-search.sh "JSON"
```

### 常见场景

```bash
# Python 缺包
pip3 install --break-system-packages <包名>

# 系统缺命令
apt install -y <工具名>

# Node 缺模块
npm install -g <模块名>
```

## 📄 License

MIT
