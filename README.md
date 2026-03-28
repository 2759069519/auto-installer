# 🦞 Auto-Installer 万能补全器

> **任何阻碍 → 自动解决。成功学，失败也学。越用越强。**

OpenClaw 智能技能：遇到任何环境阻碍（命令找不到、模块缺失、权限问题等）时，自动分析并解决。

## ✨ 核心特性

- **6 层递进搜索**：映射表 → 智能推理 → 系统包搜索 → pip/npm → ClawHub → 学习记录
- **安装降级链**：每条工具支持多路径安装（apt→snap→pip→npm→GitHub下载→源码编译），首选失败自动降级
- **🧠 自学习（成功+失败）**：成功安装自动记录，失败也记录（24h 内自动跳过避免重试）
- **📄 自动回写映射表**：安装成功后自动追加到 `task-tool-map.md`，下次秒级命中
- **📥 JSONL 安装历史**：每次安装记录到 `data/install-history.jsonl`，含时间戳/耗时/成功状态
- **🔍 已装工具检测**：安装前自动检查是否已安装，跳过重复操作
- **📊 系统扫描**：`--scan` 一键扫描 dpkg/pip/npm/snap 已装工具，生成索引
- **📥 dl 真正下载**：调用 GitHub API → 架构匹配 → 镜像加速下载 → 自动解压安装
- **🇨🇳 国内镜像加速**：7 个 GitHub 代理并行测速自动选择最快，pip 走清华源
- **🔤 中英文双搜**：中文描述（如"压缩文件"）也能命中映射表（45+ 中文别名）
- **🧠 智能推理**：从 `command not found`/`ModuleNotFoundError` 等报错自动推断依赖 + 别名匹配
- **📦 批量安装**：`--install tool1 tool2 tool3`（v2.2 起走 6 层全链路搜索）
- **🔄 学习整理**：`--promote` 将学习记录正式写入映射表
- **📊 260+ 工具映射**：任务描述直接对应安装命令，秒级响应
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
bash scripts/auto-install-search.sh "系统监控"

# 批量安装（v2.2 起走6层全链路搜索）
bash scripts/auto-install-search.sh --install ripgrep fzf jq bat tree

# 手动学习
bash scripts/auto-install-search.sh --learn "lazydocker" "Docker管理TUI"

# 整理学习到映射表（v2.2 起安装时自动回写，--promote 用于手动整理残留）
bash scripts/auto-install-search.sh --promote

# 查看历史 / 失败记录 / 统计
bash scripts/auto-install-search.sh --history
bash scripts/auto-install-search.sh --failures
bash scripts/auto-install-search.sh --stats

# 扫描系统已装工具
bash scripts/auto-install-search.sh --scan
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
| 🔤 中文别名速查 | 45+ |
| 🔧 自动发现的工具 | 持续增长 |

## 📁 文件结构

```
auto-installer/
├── README.md                         # 本文件
├── SKILL.md                          # 技能主文档（Agent 读取）
├── data/
│   ├── install-history.jsonl         # 安装历史（JSONL 格式）
│   └── installed-index.json          # 系统已装工具索引（--scan 生成）
├── references/
│   ├── task-tool-map.md              # 260+ 工具映射表（含降级链 + 中文别名）
│   ├── learned-tools.log             # 成功学习记录
│   ├── failed-installs.log           # 失败学习记录（24h 防重试）
│   └── usage-stats.json              # 使用统计
└── scripts/
    └── auto-install-search.sh        # 主脚本（6层搜索 + 降级链 + 自学习 + 自动回写）
```

## 📋 更新日志

### v2.2.0
- ✨ **自动回写映射表**：安装成功后自动追加到 task-tool-map.md，无需手动 --promote
- ✨ **JSONL 安装历史**：每次安装记录到 data/install-history.jsonl（时间戳/查询词/方法/耗时/成功状态）
- ✨ **已装工具检测**：安装前自动检查 command/dpkg，避免重复安装
- ✨ **系统扫描**：`--scan` 扫描 dpkg/pip/npm/snap 已装工具，生成 installed-index.json
- ✨ **安装统计**：`--stats` 查看安装成功率、使用次数、映射表大小
- ✨ **中文搜索增强**：新增 45+ 中文别名（压缩文件、系统监控、JSON处理 等）
- ✨ **批量安装走6层全链路**：不再仅查映射表，支持 apt/pip/npm 搜索 + 智能推理
- ✨ **失败日志优雅处理**：文件不存在时显示"暂无"而非报错
- ✨ **Permission denied 推断**：智能推理层新增权限错误识别
- ✨ **更多前缀去除**：搜索时自动去除 python3-/golang- 前缀再匹配

### v2.1.0
- ✨ 自学习-失败：安装失败记录，24h 内自动跳过
- ✨ 批量安装：`--install tool1 tool2 tool3`
- ✨ 学习整理：`--promote` 写入正式映射表
- ✨ 退出码 10：6层全未命中供 agent 联网搜索
- ✨ dpkg 兜底验证
- ✨ 使用统计

### v2.0.0
- ✨ 智能推理层 / 自学习 / 中文支持 / 6层全部实装

### v1.3.0
- ✨ 7 个 GitHub 代理 / 降级链 / 200+ 工具映射

## License

MIT
