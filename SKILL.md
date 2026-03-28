---
name: auto-installer
description: "遇到 command not found / ModuleNotFoundError / Permission denied 等报错时，自动搜索并安装所需依赖工具。支持 apt/snap/pip/npm 降级链 + 自学习(成功+失败) + 批量安装，含 213+ 工具映射表。"
version: "2.1.0"
tags: [installer, resolver, auto-fix, dependency, self-learning, batch]
---

# 🦞 Auto-Installer 万能补全器 v2.1

> **任何阻碍 → 自动解决。成功学，失败也学。越用越强。**

## 💡 核心原则

**没有解决不了的问题，只有还没找到的方法。**

## 🎯 触发条件

| 触发类型 | 示例 |
|---------|------|
| exec 报错 | `command not found`, `ModuleNotFoundError`, `Permission denied` 等 |
| 用户表达 | "帮我装"、"找工具"、"不会做"、"报错了"、"搞不定" |
| agent 判断 | 任务需要某个能力但当前环境不具备 |

## 🔄 执行流程（6 层递进 + 自学习）

```
第 1 层: 查固定映射表  ──→  秒级匹配，中英文双搜
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

**中文支持**：同时搜索工具名（英文）和描述（中文），如"压缩文件"能匹配到 `zip`/`p7zip-full` 等。

- ✅ 匹配到 → 按**安装降级链**执行 → 重试原任务
- ❌ 未命中 → 进入第 2 层

---

### 🧠 第 2 层：智能推理（无需网络）

从报错信息中自动提取关键线索，并交叉匹配映射表别名：

| 报错模式 | 推断 | 自动生成的降级链 |
|---------|------|---------|
| `command not found: xxx` | 缺系统命令 | `apt xxx`（或别名匹配映射表） |
| `ModuleNotFoundError: 'xxx'` | 缺 Python 包 | `pip xxx → pip(清华源) xxx` |
| `Cannot find module 'xxx'` | 缺 Node 模块 | `npm xxx` |
| `error while loading shared libraries: libxxx` | 缺共享库 | `apt libxxx-dev` |
| `ImportError: libGL.so.1` | 缺 OpenGL | `apt libgl1-mesa-glx` |

**别名识别**：推断出 `rg` → 自动查映射表 → 匹配 `ripgrep (rg)` → 使用完整降级链 `apt ripgrep → dl github.com/BurntSushi/ripgrep`

---

### 🔍 第 3 层：搜索系统包（内部搜索）

```bash
apt search <关键词> 2>/dev/null | head -15
snap find <关键词> 2>/dev/null | head -10
```

---

### 📦 第 4 层：搜索 pip/npm

```bash
pip3 index versions <关键词> 2>/dev/null | head -5
npm search <关键词> 2>/dev/null | head -5
```

---

### 🦞 第 5 层：ClawHub 技能

```bash
npx clawhub search "<关键词>" 2>/dev/null | head -5
```

---

### 📝 第 6 层：学习记录

查询 `references/learned-tools.log` 中的历史成功学习记录。

---

## 📦 安装降级链

确定需要装什么后，**按优先级依次尝试，一条失败自动换下一条**：

### CLI 工具安装降级链

| 优先级 | 方式 | 命令 | 适用场景 |
|-------|------|------|---------|
| 1 | **apt** | `apt install -y <pkg>` | Debian/Ubuntu 标准包 |
| 2 | **snap** | `snap install <pkg>` | apt 不可用时的首选替代 |
| 3 | **pipx** | `pipx install <pkg>` | Python CLI 工具（隔离环境） |
| 4 | **npm -g** | `npm install -g <pkg>` | Node.js 生态工具 |
| 5 | **GitHub Release** | 自动下载+安装 | 无包管理器的二进制 |
| 6 | **源码编译** | `git clone && make` | 最后手段 |

### Python 库安装降级链

| 优先级 | 方式 | 命令 |
|-------|------|------|
| 1 | **pip3** | `pip3 install --break-system-packages <pkg>` |
| 2 | **pip3 指定源** | `pip3 install -i https://pypi.tuna.tsinghua.edu.cn/simple <pkg>` |
| 3 | **conda** | `conda install <pkg>`（如已装 conda） |

### GitHub Release 自动下载

`dl` 模式会**自动完成**以下步骤：
1. 调用 GitHub API 获取最新 Release 信息
2. 根据当前系统架构（linux/amd64/arm64）匹配正确的二进制文件
3. 通过镜像加速下载到 `/tmp/`
4. 自动解压（tar.gz/zip/deb）
5. 安装二进制到 `/usr/local/bin/`
6. 验证命令可用性

### 安装后自动验证

```bash
command -v <cmd>           # 验证命令存在
<cmd> --version            # 验证可运行
dpkg -s <pkg>              # dpkg 兜底（包名≠命令名时）
```

---

## 🧠 自学习（核心特性）

### 双向学习：成功 + 失败

**成功学习**：每次成功安装后自动记录工具名、安装方式、GitHub 仓库。
**失败学习**：每次安装失败也记录，**24 小时内自动跳过该路径**，避免重复踩坑。

```bash
# 查看成功记录
bash auto-install-search.sh --history

# 查看失败记录
bash auto-install-search.sh --failures
```

### 整理学习记录到映射表

```bash
# 将所有成功学习的工具正式写入 task-tool-map.md
bash auto-install-search.sh --promote
# 写入后自动清空学习记录
```

### 自学习流程

1. 用户通过第 3-5 层成功/失败安装了一个工具
2. 脚本自动记录到 `learned-tools.log` / `failed-installs.log`
3. 失败记录 24h 内自动跳过该安装路径
4. 下次搜索时第 6 层会命中成功学习记录
5. 用 `--promote` 整理到正式映射表

---

## 🔧 高级功能

### 批量安装

```bash
# 一次安装多个工具
bash auto-install-search.sh --install ripgrep fzf jq bat tree
```

### 退出码信号

| 退出码 | 含义 |
|-------|------|
| 0 | 成功（找到方案或安装成功） |
| 1 | 参数错误 |
| **10** | **6层全部未命中 → agent 应调用 mimo_web_search 联网搜索** |

### sudo 自动检测

- 已是 root → 直接执行
- 有 sudo 权限 → 自动加 `sudo`
- 无 sudo 权限 → 提示用户并尝试继续

### 国内网络加速

- 7 个 GitHub 代理并行测速，自动选择最快
- 结果缓存，后续调用秒级响应
- pip 自动切换清华源
- 国际网络直连，不走代理

### 使用统计

脚本自动记录 `references/usage-stats.json`，统计每个工具的搜索/安装次数。

---

## 📝 使用示例

```bash
# 搜索工具（不安装）
bash auto-install-search.sh "ripgrep"

# 搜索并自动安装
bash auto-install-search.sh "fzf" --install

# 从报错信息推断（自动识别别名）
bash auto-install-search.sh "command not found: rg" --install

# 中文关键词搜索
bash auto-install-search.sh "压缩文件"

# 批量安装
bash auto-install-search.sh --install pv moreutils tree

# 手动学习
bash auto-install-search.sh --learn "lazydocker" "Docker 管理 TUI"

# 整理学习记录到映射表
bash auto-install-search.sh --promote

# 查看学习/失败历史
bash auto-install-search.sh --history
bash auto-install-search.sh --failures
```

---

## 📁 文件结构

```
auto-installer/
├── SKILL.md                          # 技能主文档
├── README.md                         # 项目说明
├── references/
│   ├── task-tool-map.md              # 213+ 工具映射表（含降级链 + 自发现分类）
│   ├── learned-tools.log             # 成功学习记录
│   ├── failed-installs.log           # 失败学习记录
│   └── usage-stats.json              # 使用统计
└── scripts/
    └── auto-install-search.sh        # 主脚本（6层搜索 + 降级链 + 自学习）
```

## 📋 更新日志

### v2.1.0
- ✨ **自学习-失败**：安装失败也记录，24h 内自动跳过该路径
- ✨ **批量安装**：`--install tool1 tool2 tool3`
- ✨ **学习整理**：`--promote` 将学习记录写入正式映射表
- ✨ **退出码 10**：6层全未命中时返回 10，供 agent 联网搜索
- ✨ **dpkg 兜底验证**：包名≠命令名时用 dpkg 确认安装
- ✨ **使用统计**：自动记录搜索/安装次数
- 🐛 修复 `--promote` 字段解析错误
- 🔧 中文关键词搜索增强（同时搜索描述列）
- 🔧 智能推理层增加别名映射表交叉匹配
- 🔧 dl 模式：真正下载+解压+安装，不再只打印链接
- 🔧 sudo 自动检测

### v2.0.0
- ✨ 智能推理层：从报错信息自动推断依赖
- ✨ 自学习-成功：安装成功自动记录
- ✨ 中文关键词支持
- ✨ 6 层递进搜索全部实装

### v1.3.0
- ✨ 7 个 GitHub 代理并行测速
- ✨ 安装降级链
- ✨ 200+ 工具映射表
