# 🦞 Auto-Installer 万能补全器

> **任何阻碍 → 自动解决。成功学，失败也学。越用越强。**

OpenClaw 智能技能：遇到任何环境阻碍（命令找不到、模块缺失、权限问题等）时，自动分析并解决。

## ✨ 核心特性

- **6 层递进搜索**：映射表 → 智能推理 → 系统包搜索 → pip/npm → ClawHub → 学习记录
- **安装降级链**：每条工具支持多路径安装（apt→snap→pip→npm→GitHub下载→源码编译），首选失败自动降级
- **🧠 自学习（成功+失败）**：成功安装自动记录，失败也记录（24h 内自动跳过避免重试）
- **📥 dl 真正下载**：调用 GitHub API → 架构匹配 → 镜像加速下载 → 自动解压安装
- **🇨🇳 国内镜像加速**：7 个 GitHub 代理并行测速自动选择最快，pip 走清华源
- **🔤 中英文双搜**：中文描述（如"压缩文件"）也能命中映射表
- **🧠 智能推理**：从 `command not found`/`ModuleNotFoundError` 等报错自动推断依赖 + 别名匹配
- **📦 批量安装**：`--install tool1 tool2 tool3`
- **🔄 学习整理**：`--promote` 将学习记录正式写入映射表
- **📊 213+ 工具映射**：任务描述直接对应安装命令，秒级响应
- **退出码信号**：6层全未命中返回退出码 10，供 agent 联网搜索

## 📦 安装

```bash
git clone https://github.com/2759069519/auto-installer.git ~/.openclaw/skills/auto-installer
```

## 🚀 使用

```bash
# 搜索工具
bash scripts/auto-install-search.sh "jq"

# 搜索并自动安装
bash scripts/auto-install-search.sh "fzf" --install

# 从报错推断（自动识别别名：rg → ripgrep）
bash scripts/auto-install-search.sh "command not found: rg" --install

# 中文关键词
bash scripts/auto-install-search.sh "压缩文件"

# 批量安装
bash scripts/auto-install-search.sh --install ripgrep fjq jq bat tree

# 手动学习
bash scripts/auto-install-search.sh --learn "lazydocker" "Docker管理TUI"

# 整理学习到映射表
bash scripts/auto-install-search.sh --promote

# 查看历史
bash scripts/auto-install-search.sh --history
bash scripts/auto-install-search.sh --failures
```

## 📊 工具分类

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
| 🔧 自动发现的工具 | 持续增长 |

## 📁 文件结构

```
auto-installer/
├── README.md                         # 本文件
├── SKILL.md                          # 技能主文档（Agent 读取）
├── references/
│   ├── task-tool-map.md              # 213+ 工具映射表（含降级链）
│   ├── learned-tools.log             # 成功学习记录
│   ├── failed-installs.log           # 失败学习记录（24h 防重试）
│   └── usage-stats.json              # 使用统计
└── scripts/
    └── auto-install-search.sh        # 主脚本（6层搜索 + 降级链 + 自学习）
```

## 📋 更新日志

### v2.1.0
- ✨ 自学习-失败：安装失败记录，24h 内自动跳过
- ✨ 批量安装：`--install tool1 tool2 tool3`
- ✨ 学习整理：`--promote` 写入正式映射表
- ✨ 退出码 10：6层全未命中供 agent 联网搜索
- ✨ dpkg 兜底验证
- ✨ 使用统计
- 🔧 中文搜索增强 / 别名映射表交叉匹配 / dl 真正下载 / sudo 检测

### v2.0.0
- ✨ 智能推理层 / 自学习 / 中文支持 / 6层全部实装

### v1.3.0
- ✨ 7 个 GitHub 代理 / 降级链 / 200+ 工具映射

## License

MIT
