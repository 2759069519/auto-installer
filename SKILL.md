---
name: auto-installer
description: "遇到 command not found / ModuleNotFoundError / Permission denied 等报错时，自动搜索并安装所需依赖工具。支持 apt/snap/pip/npm 降级链 + 自学习 + 自动回写映射表 + JSONL历史 + 已装检测 + 批量安装走6层全链路，含 260+ 工具映射（含45+中文别名）。"
version: "2.2.0"
tags: [installer, resolver, auto-fix, dependency, self-learning, batch, auto-writeback]
---

# 🦞 Auto-Installer 万能补全器 v2.2

> **任何阻碍 → 自动解决。成功学，失败也学。越用越强。**

## 💡 核心原则

**没有解决不了的问题，只有还没找到的方法。**

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
第 2 层: 智能推理      ──→  从报错推断依赖 + 别名匹配映射表
    ↓ 无法推断
第 3 层: 搜索系统包    ──→  apt / snap 内部搜索
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

**中文支持**：同时搜索工具名（英文）和描述（中文），如"压缩文件"能匹配到 `zip`/`p7zip-full` 等。v2.2 新增 45+ 中文别名速查表。

- ✅ 匹配到 → 按**安装降级链**执行 → 重试原任务
- ❌ 未命中 → 进入第 2 层

### 🧠 第 2 层：智能推理

解析报错信息，自动推断依赖：

| 报错格式 | 推断结果 |
|---------|---------|
| `command not found: xxx` | 系统工具 xxx |
| `ModuleNotFoundError: 'xxx'` | Python 包 xxx |
| `Cannot find module 'xxx'` | Node 模块 xxx |
| `libxxx.so: cannot open` | 系统库 libxxx-dev |
| `ImportError: libGL.so.1` | libgl1-mesa-glx |
| `Permission denied` | chmod 权限问题 |

然后查询映射表中的**别名匹配**（如 rg → ripgrep），找到完整降级链。

- ✅ 推断成功 → 执行降级链
- ❌ 无法推断 → 进入第 3 层

### 📦 第 3-5 层：包管理器搜索

依次搜索 apt/snap → pip/npm → ClawHub。

### 📚 第 6 层：学习记录

查询 `references/learned-tools.log` 和 `references/failed-installs.log`。

---

## 🔧 安装降级链

每条工具支持多路径安装，首选失败自动降级：

```
apt → snap → pip → npm → dl (GitHub Release 下载) → src (源码编译) → go → pipx
```

安装前自动检查是否已安装（command + dpkg），避免重复操作。

安装成功后：
1. ✅ 自动验证命令可用
2. ✅ 自动记录到 `learned-tools.log`
3. ✅ **自动回写**到 `task-tool-map.md`（无需手动 --promote）
4. ✅ 记录到 `data/install-history.jsonl`（含时间戳/耗时/成功状态）
5. ✅ 更新使用统计

安装失败后：
1. ✅ 记录到 `failed-installs.log`
2. ✅ 24h 内自动跳过同路径，避免重试
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

# 批量安装（走6层全链路搜索）
bash scripts/auto-install-search.sh --install tool1 tool2 tool3

# 手动学习
bash scripts/auto-install-search.sh --learn "工具名" "描述"

# 整理学习记录到映射表
bash scripts/auto-install-search.sh --promote

# 查看学习历史
bash scripts/auto-install-search.sh --history

# 查看失败记录
bash scripts/auto-install-search.sh --failures

# 查看安装统计
bash scripts/auto-install-search.sh --stats

# 扫描系统已装工具
bash scripts/auto-install-search.sh --scan
```

## 退出码

| 退出码 | 含义 |
|--------|------|
| 0 | 成功 |
| 1 | 参数错误 |
| 10 | 6层全部未命中 → agent 应联网搜索 |

当退出码为 10 时，agent 应调用 `mimo_web_search` 搜索并手动安装。

---

## 📁 文件位置

```
~/.openclaw/skills/auto-installer/
├── scripts/auto-install-search.sh    # 主脚本
├── references/task-tool-map.md       # 260+ 工具映射表
├── references/learned-tools.log      # 学习记录
├── references/failed-installs.log    # 失败记录
├── references/usage-stats.json       # 使用统计
├── data/install-history.jsonl        # 安装历史 JSONL
└── data/installed-index.json         # 已装工具索引
```
