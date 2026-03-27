# 🦞 Auto-Installer 万能补全器

> **任何阻碍 → 自动解决。不问用户，直接干。**
>
> `v1.3.0` · MIT License

OpenClaw 智能技能：遇到任何环境阻碍（命令找不到、模块缺失、权限问题等）时，自动分析并解决。

---

## ✨ 特性

- **5 层递进搜索**：映射表 → 智能推理 → 系统包搜索 → 联网搜索 → 创造方案
- **安装降级链**：每条工具支持多路径安装（apt→snap→pip→npm→手动下载），首选失败自动降级
- **国内镜像加速**：自动检测网络环境，**7 个 GitHub 代理并行测速自动选择最快**，pip 走清华源
- **全场景覆盖**：文件搜索、数据处理、网络、文档、图片、音视频、开发、DevOps、数据库等 15+ 分类
- **200+ 工具映射**：任务描述直接对应安装命令，秒级响应
- **智能命令验证**：自动识别 `name (alias)` 格式（如 `ripgrep (rg)`），优先验证别名
- **自我学习**：每次解决新问题后自动更新映射表

## 📁 项目结构

```
auto-installer/
├── README.md                          # 项目说明
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

## 🌐 GitHub 代理加速（v1.3.0 新增）

内置 **7 个 GitHub 代理**，并行测试自动选择响应最快的：

| 优先级 | 代理地址 | 特点 |
|-------|---------|------|
| 1 | `ghfast.top` | 主力代理，稳定性好 |
| 2 | `gh.llkk.cc` | 备用代理 |
| 3 | `gh-proxy.com` | 备用代理 |
| 4 | `gh.monlor.com` | 响应快 |
| 5 | `gh.xxooo.cf` | 备用代理 |
| 6 | `gh.jasonzeng.dev` | 备用代理 |
| 7 | `gh.dpik.top` | 备用代理 |

**特性：**
- 并行测试所有代理（首次 ~10s），自动选择最快的
- 结果缓存，后续调用秒级响应
- 国际网络直连，不走代理
- 全部不可用时自动回退到原始 GitHub URL

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

### v1.3.0 (2026-03-28)

- ✨ **GitHub 代理多备份**：从 1 个代理升级到 7 个，并行测速自动选择最快
- ✨ **代理结果缓存**：首次测试后缓存，后续调用秒响应
- 🐛 修复 snap 安装后命令找不到（`/snap/bin` 不在 PATH）
- 🐛 修复 dl 模式 GitHub URL 双重 `github.com` 前缀问题
- 🐛 修复 `verify_cmd` 不支持 `name (alias)` 格式（如 `ripgrep (rg)`）
- 🔧 优化 dl 模式输出，显示 Release 页面镜像链接
- 🔧 SKILL.md 新增代理配置文档

### v1.2.0-fix (2026-03-27)

- 🐛 修复 npm "No matches found" 误判为命中结果
- 🐛 所有包管理器搜索加 timeout 保护
- 🔧 jq GitHub 地址 `stedolan/jq` → `jqlang/jq`

### v1.2.0 (2026-03-27)

- ✨ 每个工具增加安装降级链
- ✨ 自动检测国内网络，GitHub 镜像加速
- ✨ pip 自动切换清华源
- ✨ `--install` 自动安装模式
- ✨ 200+ 工具全部更新为降级链格式

### v1.1.0 (2026-03-18)

- ✨ 初始版本，基础搜索 + 安装功能

## 📄 License

MIT
