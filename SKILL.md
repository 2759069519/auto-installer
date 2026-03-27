---
name: auto-installer
description: "万能补全器：遇到任何阻碍自动分析并解决。触发条件：exec 报错 (command not found / ModuleNotFoundError / Permission denied / 等)；用户说'帮我装'、'找工具'、'不会做'、'报错了'、'搞不定'；agent 判断缺少工具/技能/依赖/配置。不仅限于安装工具，还包括修复配置、解决依赖链、搜索网络方案、生成临时脚本等一切让任务能继续的手段。"
version: "1.1.0"
tags: [installer, resolver, auto-fix, dependency]
---

# 🦞 Auto-Installer 万能补全器

> **任何阻碍 → 自动解决。不问用户，直接干。**

## 💡 核心原则

**没有解决不了的问题，只有还没找到的方法。**

## 🎯 触发条件

当以下任一情况发生时，激活本技能：

| 触发类型 | 示例 |
|---------|------|
| exec 报错 | `command not found`, `ModuleNotFoundError`, `Permission denied` 等 |
| 用户表达 | "帮我装"、"找工具"、"不会做"、"报错了"、"搞不定" |
| agent 判断 | 任务需要某个能力但当前环境不具备 |

## 🔄 执行流程（5 层递进）

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

---

### 📖 第 1 层：查固定映射表（秒级）

读取 `references/task-tool-map.md`，按报错信息或任务描述匹配关键词。

- ✅ 匹配到 → 直接执行安装命令 → 重试原任务
- ❌ 未命中 → 进入第 2 层

---

### 🧠 第 2 层：智能推理（无需网络）

分析报错信息，提取关键线索，判断问题类型：

| 报错模式 | 推断 | 行动 |
|---------|------|------|
| `command not found: xxx` | 缺系统命令 | 装 xxx |
| `ModuleNotFoundError: 'xxx'` | 缺 Python 包 | `pip3 install xxx` |
| `Cannot find module 'xxx'` | 缺 Node 模块 | `npm install xxx` |
| `error while loading shared libraries: libxxx` | 缺共享库 | `apt install libxxx-dev` |
| `Permission denied` | 权限不足 | `chmod` / `sudo` |
| `EACCES: permission denied` (npm) | npm 权限问题 | 修 npm 全局目录 |
| `locale.Error` | locale 未配置 | `locale-gen` |
| `No space left` | 磁盘满 | `ncdu` 清理 |
| `GLIBC_xxx not found` | 系统库版本低 | 搜索方案 |
| `certificate verify failed` | SSL 证书问题 | `ca-certificates` |
| `pkg-config cannot find xxx` | 缺开发头文件 | 装 `-dev` 包 |

---

### 🔍 第 3 层：搜索系统包（内部搜索）

```bash
apt search <关键词> 2>/dev/null | head -15
pip3 index versions <关键词> 2>/dev/null | head -5
npm search <关键词> 2>/dev/null | head -10
npx clawhub search "<关键词>" 2>/dev/null
```

---

### 🌐 第 4 层：联网搜索方案（兜底）

前 3 层都没解决 → 用 `mimo_web_search` 搜索：

**搜索模板：**
- `"xxx" command not found ubuntu install`
- `"xxx" ModuleNotFoundError python pip`
- `"xxx" error ubuntu 24.04 fix`
- `"xxx" alternative tool linux`
- `"how to do xxx on linux"`

**搜索到方案后：**
1. 阅读结果，提取有效步骤
2. 执行解决方案
3. 验证是否解决
4. **把方案更新到映射表**（自我学习）

---

### 🛠️ 第 5 层：创造方案（终极手段）

前 4 层全失败 → 自己造：
- 写 Python 脚本临时替代缺失工具
- 用已有工具组合出新能力
- 用 Node.js / Python 搭建临时服务

---

## 📦 安装优先级

确定需要装什么后，按顺序尝试：

| 优先级 | 方式 | 命令示例 |
|-------|------|---------|
| 1 | **apt** | `apt install -y <pkg>` |
| 2 | **pip3** | `pip3 install --break-system-packages <pkg>` |
| 3 | **npm -g** | `npm install -g <pkg>` |
| 4 | **clawhub** | `npx clawhub install <slug> --workdir ~/.openclaw` |
| 5 | **手动下载** | `wget` / `curl` 官方二进制 |
| 6 | **源码编译** | `git clone && make`（最后手段） |

**安装后验证：**
```bash
command -v <cmd>           # 验证命令
python3 -c "import <pkg>"  # 验证 Python 包
```

---

## 🧠 自我学习

每次通过第 4–5 层解决问题后，将方案写入映射表：

```bash
# 追加到 references/task-tool-map.md
echo "| 问题描述 | 解决方案 | 安装命令 |" >> references/task-tool-map.md
```

> 下次遇到同样问题，直接第 1 层秒级解决。

---

## 📝 记录

每次安装/解决后，写入 `memory/` 日志：

- 解决了什么问题
- 用了什么方法
- 花了多长时间
