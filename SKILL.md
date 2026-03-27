---
name: auto-installer
description: "万能补全器：遇到任何阻碍自动分析并解决。触发条件：exec 报错 (command not found / ModuleNotFoundError / Permission denied / 等)；用户说'帮我装'、'找工具'、'不会做'、'报错了'、'搞不定'；agent 判断缺少工具/技能/依赖/配置。不仅限于安装工具，还包括修复配置、解决依赖链、搜索网络方案、生成临时脚本等一切让任务能继续的手段。"
version: "1.2.0"
tags: [installer, resolver, auto-fix, dependency]
---

# 🦞 Auto-Installer 万能补全器

> **任何阻碍 → 自动解决。不问用户，直接干。**

## 💡 核心原则

**没有解决不了的问题，只有还没找到的方法。**

## 🎯 触发条件

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
第 3 层: 搜索系统包    ──→  apt / pip / npm / snap 内部搜索
    ↓ 未找到
第 4 层: 联网搜索      ──→  web search 找方案（兜底）
    ↓ 全部失败
第 5 层: 创造方案      ──→  自己写脚本/代码解决（终极手段）
```

---

### 📖 第 1 层：查固定映射表（秒级）

读取 `references/task-tool-map.md`，按报错信息或任务描述匹配关键词。

- ✅ 匹配到 → 按**安装降级链**执行 → 重试原任务
- ❌ 未命中 → 进入第 2 层

---

### 🧠 第 2 层：智能推理（无需网络）

分析报错信息，提取关键线索：

| 报错模式 | 推断 | 行动 |
|---------|------|------|
| `command not found: xxx` | 缺系统命令 | 查映射表，无则 `apt search xxx` |
| `ModuleNotFoundError: 'xxx'` | 缺 Python 包 | `pip3 install xxx` |
| `Cannot find module 'xxx'` | 缺 Node 模块 | `npm install -g xxx` |
| `error while loading shared libraries: libxxx` | 缺共享库 | `apt install libxxx-dev` |
| `Permission denied` | 权限不足 | `chmod` / `sudo` |
| `EACCES: permission denied` (npm) | npm 权限问题 | 修 npm 全局目录 |
| `locale.Error` | locale 未配置 | `locale-gen` |
| `No space left` | 磁盘满 | `ncdu` 清理 |
| `GLIBC_xxx not found` | 系统库版本低 | 搜索方案 |
| `certificate verify failed` | SSL 证书问题 | `ca-certificates` |
| `ImportError: libGL.so.1` | 缺 OpenGL | `apt install libgl1-mesa-glx` |
| `pkg-config cannot find xxx` | 缺开发头文件 | 装 `-dev` 包 |

---

### 🔍 第 3 层：搜索系统包（内部搜索）

```bash
apt search <关键词> 2>/dev/null | head -15
pip3 index versions <关键词> 2>/dev/null | head -5
npm search <关键词> 2>/dev/null | head -5
snap find <关键词> 2>/dev/null | head -10
npx clawhub search "<关键词>" 2>/dev/null
```

---

### 🌐 第 4 层：联网搜索方案（兜底）

前 3 层都没解决 → 用 `mimo_web_search` 搜索：

- `"xxx" command not found ubuntu install`
- `"xxx" ModuleNotFoundError python pip`
- `"xxx" error ubuntu 24.04 fix`
- `"xxx" alternative tool linux`

搜索到方案后：执行 → 验证 → **更新映射表**（自我学习）

---

### 🛠️ 第 5 层：创造方案（终极手段）

- 写 Python/Node 脚本临时替代缺失工具
- 用已有工具组合出新能力

---

## 📦 安装降级链（核心改进）

确定需要装什么后，**按优先级依次尝试，一条失败自动换下一条**：

### CLI 工具安装降级链

| 优先级 | 方式 | 命令 | 适用场景 |
|-------|------|------|---------|
| 1 | **apt** | `apt install -y <pkg>` | Debian/Ubuntu 标准包 |
| 2 | **snap** | `snap install <pkg>` | apt 不可用时的首选替代 |
| 3 | **pipx** | `pipx install <pkg>` | Python CLI 工具（隔离环境） |
| 4 | **npm -g** | `npm install -g <pkg>` | Node.js 生态工具 |
| 5 | **GitHub Release** | 见下方模板 | 无包管理器的二进制 |
| 6 | **源码编译** | `git clone && make` | 最后手段 |

### Python 库安装降级链

| 优先级 | 方式 | 命令 |
|-------|------|------|
| 1 | **pip3** | `pip3 install --break-system-packages <pkg>` |
| 2 | **pip3 指定源** | `pip3 install -i https://pypi.tuna.tsinghua.edu.cn/simple <pkg>` |
| 3 | **conda** | `conda install <pkg>`（如已装 conda） |

### GitHub Release 下载模板

```bash
# 检测网络环境，自动选择镜像
get_github_url() {
    local repo="$1" file="$2"
    local base="https://github.com/${repo}/releases/latest/download/${file}"
    # 中国服务器优先用镜像
    if curl -s --connect-timeout 3 https://www.google.com >/dev/null 2>&1; then
        echo "$base"  # 能访问 Google → 国际网络
    else
        echo "https://ghfast.top/${base}"  # 国内镜像加速
    fi
}

# 使用示例
URL=$(get_github_url "junegunn/fzf" "fzf-0.57.0-linux_amd64.tar.gz")
curl -sL "$URL" -o /tmp/tool.tar.gz
```

### 安装后验证

```bash
command -v <cmd>           # 验证命令存在
<cmd> --version            # 验证可运行
python3 -c "import <pkg>"  # 验证 Python 包
```

---

## 🧠 自我学习

每次通过第 4–5 层解决问题后，将方案写入映射表：

```bash
# 追加到 references/task-tool-map.md 的对应分类下
echo "| 任务描述 | 工具名 | 降级链命令 |" >> references/task-tool-map.md
```

---

## 📝 记录

每次安装/解决后，写入 `memory/` 日志：

- 解决了什么问题
- 用了什么方法（哪条降级链成功了）
- 花了多长时间
