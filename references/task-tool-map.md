# 📋 任务 → 工具 全场景映射表

> 遇到以下任务时，直接查表安装对应工具，不需要搜索。

---

## 📂 文件搜索 & 操作

| 任务 | 工具 | 安装命令 |
|------|------|---------|
| 搜索文件内容 | `ripgrep (rg)` | `apt install -y ripgrep` |
| 查找文件名/路径 | `fd-find (fd)` | `apt install -y fd-find` |
| 查看文件（语法高亮） | `bat (batcat)` | `apt install -y bat` |
| 查看目录树结构 | `tree` | `apt install -y tree` |
| 快速文本搜索 | `silversearcher (ag)` | `apt install -y silversearcher-ag` |
| 数据库定位文件 | `locate (mlocate)` | `apt install -y mlocate` |
| 识别文件类型 | `file` | `apt install -y file` |
| 管道进度条 | `pv` | `apt install -y pv` |
| cp/mv/dd 进度 | `progress` | `apt install -y progress` |
| sponge / vidir / ts | `moreutils` | `apt install -y moreutils` |

---

## 📊 数据处理（JSON / YAML / XML / CSV / TOML）

| 任务 | 工具 | 安装命令 |
|------|------|---------|
| 处理 JSON | `jq` | `apt install -y jq` |
| 处理 YAML | `yq` | `wget -qO /usr/local/bin/yq https://github.com/mikefarah/yq/releases/latest/download/yq_linux_amd64 && chmod +x /usr/local/bin/yq` |
| 处理 XML | `xmlstarlet` | `apt install -y xmlstarlet` |
| 处理 CSV（强大） | `miller (mlr)` | `apt install -y miller` |
| 处理 CSV（简单） | `csvtool` | `apt install -y csvtool` |
| 万能数据查询 | `dasel` | `wget -qO /tmp/dasel.gz "https://github.com/TomWright/dasel/releases/latest/download/dasel_linux_amd64.gz" && gunzip -f /tmp/dasel.gz && mv /tmp/dasel /usr/local/bin/dasel && chmod +x /usr/local/bin/dasel` |
| 处理 TOML | `toml-cli` | `pip3 install --break-system-packages toml-cli` |

---

## 🌐 网络 & API

| 任务 | 工具 | 安装命令 |
|------|------|---------|
| HTTP 客户端（友好） | `httpie` | `apt install -y httpie` |
| HTTP 下载 | `wget` | `apt install -y wget` |
| DNS 查询 | `dnsutils (dig/nslookup)` | `apt install -y dnsutils` |
| 域名信息查询 | `whois` | `apt install -y whois` |
| 路由追踪 | `traceroute` | `apt install -y traceroute` |
| 网络诊断 | `mtr` | `apt install -y mtr-tiny` |
| Ping | `iputils-ping` | `apt install -y iputils-ping` |
| 网络调试 | `netcat (nc)` | `apt install -y netcat-openbsd` |
| 增强版 nc | `ncat (nmap)` | `apt install -y ncat` |
| 双向数据管道 | `socat` | `apt install -y socat` |
| 带宽测试 | `iperf3` | `apt install -y iperf3` |
| 端口扫描 | `nmap` | `apt install -y nmap` |
| SSL/TLS 检查 | `sslscan` | `apt install -y sslscan` |
| Let's Encrypt 证书 | `certbot` | `apt install -y certbot` |
| API 测试 & Mock | `json-server` | `npm install -g json-server` |

---

## 📄 文档处理（PDF / Word / Excel / PPT / LaTeX）

| 任务 | 工具 | 安装命令 |
|------|------|---------|
| 文档格式万能转换 | `pandoc` | `apt install -y pandoc` |
| PDF 转文本 / 拆分 / 合并 | `poppler-utils` | `apt install -y poppler-utils` |
| HTML → PDF | `wkhtmltopdf` | `apt install -y wkhtmltopdf` |
| PDF 压缩 / 处理 | `ghostscript` | `apt install -y ghostscript` |
| LaTeX 引擎 | `texlive-xetex` | `apt install -y texlive-xetex texlive-fonts-recommended texlive-plain-generic` |
| 中文 PDF 支持 | `texlive-lang-chinese` | `apt install -y texlive-lang-chinese` |
| man 页面渲染 | `groff` | `apt install -y groff` |
| Word 处理 | `libreoffice-writer` | `apt install -y libreoffice-writer` |
| Excel 处理 | `libreoffice-calc` | `apt install -y libreoffice-calc` |
| 老 Word 读取 | `antiword` | `apt install -y antiword` |
| ODT → 文本 | `odt2txt` | `apt install -y odt2txt` |

---

## 🖼️ 图片处理

| 任务 | 工具 | 安装命令 |
|------|------|---------|
| 图片万能处理 | `imagemagick` | `apt install -y imagemagick` |
| WebP 转换 | `cwebp / dwebp` | `apt install -y webp` |
| PNG 有损压缩 | `pngquant` | `apt install -y pngquant` |
| PNG 无损压缩 | `optipng` | `apt install -y optipng` |
| JPEG 优化 | `jpegoptim` | `apt install -y jpegoptim` |
| GIF 编辑 / 优化 | `gifsicle` | `apt install -y gifsicle` |
| 流程图 / 架构图 | `graphviz (dot)` | `apt install -y graphviz` |
| SVG → PNG | `rsvg-convert` | `apt install -y librsvg2-bin` |
| 位图 → 矢量 | `potrace` | `apt install -y potrace` |
| SVG 编辑（CLI） | `inkscape` | `apt install -y inkscape` |
| 屏幕截图 | `scrot` | `apt install -y scrot` |
| OCR 文字识别 | `tesseract` | `apt install -y tesseract-ocr tesseract-ocr-chi-sim` |

---

## 🎵 音频处理

| 任务 | 工具 | 安装命令 |
|------|------|---------|
| 音频万能处理 | `sox` | `apt install -y sox libsox-fmt-all` |
| MP3 编码 | `lame` | `apt install -y lame` |
| Opus 编解码 | `opus-tools` | `apt install -y opus-tools` |
| OGG 处理 | `vorbis-tools` | `apt install -y vorbis-tools` |
| FLAC 无损 | `flac` | `apt install -y flac` |
| WavPack | `wavpack` | `apt install -y wavpack` |
| MP3 解码 | `mpg123` | `apt install -y mpg123` |
| 音量标准化 | `normalize-audio` | `apt install -y normalize-audio` |

---

## 🎬 视频处理

| 任务 | 工具 | 安装命令 |
|------|------|---------|
| 视频万能处理 | `ffmpeg` | `apt install -y ffmpeg` |
| 额外编解码器 | `libavcodec-extra` | `apt install -y libavcodec-extra` |
| MKV 容器编辑 | `mkvtoolnix` | `apt install -y mkvtoolnix` |

---

## 📦 压缩归档

| 任务 | 工具 | 安装命令 |
|------|------|---------|
| zip 打包 | `zip` | `apt install -y zip` |
| 7z 格式 | `p7zip-full` | `apt install -y p7zip-full` |
| RAR 解压 | `unrar` | `apt install -y unrar` |
| Zstandard 压缩 | `zstd` | `apt install -y zstd` |
| xz / lzma | `xz-utils` | `apt install -y xz-utils` |
| 并行 gzip | `pigz` | `apt install -y pigz` |
| 并行 bzip2 | `pbzip2` | `apt install -y pbzip2` |
| 大文件高压缩 | `lrzip` | `apt install -y lrzip` |
| CAB 解压 | `cabextract` | `apt install -y cabextract` |

---

## 🔐 SSH & 远程 & 容器

| 任务 | 工具 | 安装命令 |
|------|------|---------|
| SSH 自动化密码登录 | `sshpass` | `apt install -y sshpass` |
| 断线重连 shell | `mosh` | `apt install -y mosh` |
| SSH 自动重连 | `autossh` | `apt install -y autossh` |
| 交互式命令自动化 | `expect` | `apt install -y expect` |
| 终端复用（强） | `tmux` | `apt install -y tmux` |
| 终端复用（经典） | `screen` | `apt install -y screen` |
| 容器 | `docker` | `curl -fsSL https://get.docker.com \| bash` |

---

## 🛠️ 开发基础

| 任务 | 工具 | 安装命令 |
|------|------|---------|
| C/C++ 编译 | `build-essential` | `apt install -y build-essential` |
| CMake 构建 | `cmake` | `apt install -y cmake` |
| 编译依赖查询 | `pkg-config` | `apt install -y pkg-config` |
| Python pip | `python3-pip` | `apt install -y python3-pip python3-venv python3-dev` |
| Python 隔离安装 | `pipx` | `apt install -y pipx` |
| SSL 编译依赖 | `libssl-dev` | `apt install -y libssl-dev libffi-dev` |
| TypeScript | `typescript + ts-node` | `npm install -g typescript ts-node` |
| 进程管理 | `pm2` | `npm install -g pm2` |
| 代码格式化 | `prettier` | `npm install -g prettier` |
| 代码热重载 | `nodemon` | `npm install -g nodemon` |
| 命令速查 | `tldr` | `npm install -g tldr` |
| 快速 HTTP 服务 | `http-server` | `npm install -g http-server` |
| 代码统计 | `cloc` | `apt install -y cloc` |
| Git 增强 | `tig` | `apt install -y tig` |
| Git diff 增强 | `delta` | `apt install -y git-delta` |

---

## ☁️ DevOps & 云原生

| 任务 | 工具 | 安装命令 |
|------|------|---------|
| K8s 管理 | `kubectl` | `curl -LO "https://dl.k8s.io/release/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl" && chmod +x kubectl && mv kubectl /usr/local/bin/` |
| 基础设施即代码 | `terraform` | 搜索官网安装或 `apt install -y terraform` |
| 配置管理 | `ansible` | `pip3 install --break-system-packages ansible` |
| 容器编排 | `docker-compose` | `apt install -y docker-compose` |
| 容器镜像工具 | `skopeo` | `apt install -y skopeo` |
| YAML lint | `yamllint` | `pip3 install --break-system-packages yamllint` |
| JSON lint | `jsonlint` | `npm install -g jsonlint` |
| 环境变量管理 | `direnv` | `apt install -y direnv` |
| HTTP 压测 | `wrk` | `apt install -y wrk` |
| 反向代理测试 | `hey` | `go install github.com/rakyll/hey@latest` |

---

## 🗄️ 数据库客户端

| 任务 | 工具 | 安装命令 |
|------|------|---------|
| MySQL 客户端 | `mysql-client` | `apt install -y mysql-client` |
| PostgreSQL 客户端 | `postgresql-client` | `apt install -y postgresql-client` |
| Redis 客户端 | `redis-tools` | `apt install -y redis-tools` |
| MongoDB Shell | `mongosh` | 搜索官网安装 |
| SQLite | `sqlite3` | `apt install -y sqlite3` |
| 数据库 GUI | `dbeaver-ce` | `snap install dbeaver-ce` |

---

## 📡 系统监控 & 调试

| 任务 | 工具 | 安装命令 |
|------|------|---------|
| 系统监控（好看） | `btop` | `apt install -y btop` |
| 系统监控（经典） | `htop` | `apt install -y htop` |
| IO 监控 | `iotop` | `apt install -y iotop` |
| 磁盘占用可视化 | `ncdu` | `apt install -y ncdu` |
| 打开文件查看 | `lsof` | `apt install -y lsof` |
| 系统调用追踪 | `strace` | `apt install -y strace` |
| 系统资源统计 | `dstat` | `apt install -y dstat` |
| 系统统计工具集 | `sysstat` | `apt install -y sysstat` |
| 硬盘健康 | `smartmontools` | `apt install -y smartmontools` |
| 网络流量统计 | `vnstat` | `apt install -y vnstat` |
| 日志查看 | `lnav` | `apt install -y lnav` |
| 日志实时追踪 | `multitail` | `apt install -y multitail` |

---

## ⚡ 终端效率

| 任务 | 工具 | 安装命令 |
|------|------|---------|
| GNU 并行执行 | `parallel` | `apt install -y parallel` |
| readline 包装 | `rlwrap` | `apt install -y rlwrap` |
| 目录快速跳转 | `zoxide` | `apt install -y zoxide` |
| 模糊查找 | `fzf` | `apt install -y fzf` |
| 历史搜索增强 | `mcfly` | `cargo install mcfly` |
| 文件管理器（TUI） | `yazi` | `cargo install yazi` |
| 终端 PDF 阅读 | `zathura` | `apt install -y zathura` |

---

## 🔒 安全 & 加密

| 任务 | 工具 | 安装命令 |
|------|------|---------|
| 现代加密 | `age` | `apt install -y age` |
| 密钥管理 | `sops` | `apt install -y sops` |
| 防暴力破解 | `fail2ban` | `apt install -y fail2ban` |
| GPG 加密 | `gnupg` | `apt install -y gnupg` |
| 密码管理 | `pass` | `apt install -y pass` |
| SSL/TLS | `openssl` | `apt install -y openssl` |

---

## 🐍 Python 数据科学 & ML

| 任务 | 工具 | 安装命令 |
|------|------|---------|
| 数组 / 矩阵计算 | `numpy` | `pip3 install --break-system-packages numpy` |
| 数据分析 | `pandas` | `pip3 install --break-system-packages pandas` |
| 科学计算 | `scipy` | `pip3 install --break-system-packages scipy` |
| 机器学习 | `scikit-learn` | `pip3 install --break-system-packages scikit-learn` |
| 梯度提升 | `xgboost` | `pip3 install --break-system-packages xgboost` |
| 统计建模 | `statsmodels` | `pip3 install --break-system-packages statsmodels` |
| 数据可视化 | `matplotlib` | `pip3 install --break-system-packages matplotlib` |
| 统计可视化 | `seaborn` | `pip3 install --break-system-packages seaborn` |
| Jupyter Notebook | `jupyter` | `pip3 install --break-system-packages jupyter` |
| Excel 读写 | `openpyxl, xlrd` | `pip3 install --break-system-packages openpyxl xlrd` |
| 表格格式化 | `tabulate` | `pip3 install --break-system-packages tabulate` |
| YAML（Python） | `pyyaml` | `pip3 install --break-system-packages pyyaml` |
| HTTP 客户端 | `requests` | `pip3 install --break-system-packages requests` |
| 网页解析 | `beautifulsoup4, lxml` | `pip3 install --break-system-packages beautifulsoup4 lxml` |
| 图片处理（Python） | `Pillow` | `pip3 install --break-system-packages Pillow` |
| PDF 生成（Python） | `reportlab` | `pip3 install --break-system-packages reportlab` |
| Markdown 处理 | `markdown` | `pip3 install --break-system-packages markdown` |
| RSS 解析 | `feedparser` | `pip3 install --break-system-packages feedparser` |
| HTML 解析 | `html5lib` | `pip3 install --break-system-packages html5lib` |

---

## 🦞 ClawHub 技能（免费，不需要 key）

| 能力 | 技能 slug | 安装命令 |
|------|----------|---------|
| 图表生成 | `chart-generator` | `npx clawhub install chart-generator --workdir ~/.openclaw` |
| 图片处理增强 | `image-process` | `npx clawhub install image-process --workdir ~/.openclaw` |
| 图片增强 | `image-enhancer` | `npx clawhub install image-enhancer --workdir ~/.openclaw` |
| PDF 专业处理 | `pdf-toolkit-pro` | `npx clawhub install pdf-toolkit-pro --workdir ~/.openclaw` |
| PDF 助手 | `pdf-helper` | `npx clawhub install pdf-helper --workdir ~/.openclaw` |
| 文档处理增强 | `document-pro` | `npx clawhub install document-pro --workdir ~/.openclaw` |
| 数据图表工具 | `data-chart-tool` | `npx clawhub install data-chart-tool --workdir ~/.openclaw` |
| 自动化工作流 | `automation-workflows` | `npx clawhub install automation-workflows --workdir ~/.openclaw` |

---

## 🧩 常见报错 → 修复速查

| 报错信息 | 原因 | 修复 |
|---------|------|------|
| `command not found: xxx` | 缺系统工具 | 查上方对应分类安装 |
| `ModuleNotFoundError: No module named 'xxx'` | 缺 Python 包 | `pip3 install --break-system-packages xxx` |
| `Cannot find module 'xxx'` | 缺 Node 模块 | `npm install -g xxx` |
| `error while loading shared libraries: libxxx.so` | 缺共享库 | `apt install -y libxxx-dev` |
| `Permission denied` | 权限不足 | 检查是否需要 `sudo` 或 `chmod` |
| `No space left on device` | 磁盘满 | `ncdu /` 查看大文件，清理 |
| `Connection refused` | 服务未启动 | `systemctl start xxx` |
| `SSL certificate verify failed` | 证书问题 | `apt install -y ca-certificates` |
| `locale.Error: unsupported locale` | 缺 locale | `apt install -y locales && locale-gen en_US.UTF-8` |
| `ImportError: libGL.so.1` | 缺 OpenGL 库 | `apt install -y libgl1-mesa-glx` |
| `Could not get lock /var/lib/dpkg` | apt 被锁 | `rm /var/lib/dpkg/lock* && dpkg --configure -a` |
| `GPG error ... NO_PUBKEY` | 缺 apt key | `apt-key adv --keyserver keyserver.ubuntu.com --recv-keys <KEY>` |
| `unmet dependencies` | 依赖冲突 | `apt --fix-broken install` |
| `Out of memory / Killed` | 内存不足 | `free -h` 检查，加 swap 或用轻量方案 |
| `docker: permission denied` | Docker 权限 | `usermod -aG docker $USER` 重新登录 |
| `make: No rule to make target` | 缺构建依赖 | 检查 Makefile，通常装 `build-essential` |

---

## 🔧 常用组合安装（一行搞定）

```bash
# 🖼️ 图片处理全家桶
apt install -y imagemagick webp pngquant jpegoptim gifsicle graphviz librsvg2-bin

# 📄 文档处理全家桶
apt install -y pandoc poppler-utils wkhtmltopdf ghostscript texlive-xetex texlive-lang-chinese

# 🌐 网络工具全家桶
apt install -y httpie dnsutils mtr-tiny socat nmap sslscan certbot

# 🐍 Python 数据科学全家桶
pip3 install --break-system-packages numpy pandas scipy scikit-learn matplotlib seaborn xgboost statsmodels

# 🎵 音频处理全家桶
apt install -y sox libsox-fmt-all lame opus-tools flac mpg123 normalize-audio

# ☁️ DevOps 全家桶
apt install -y docker-compose ansible terraform kubectl

# 🗄️ 数据库客户端全家桶
apt install -y mysql-client postgresql-client redis-tools sqlite3

# ⚡ 终端效率全家桶
apt install -y tmux fzf zoxide btop ripgrep fd-find bat tree
```

---

## 🧠 任务推理链（映射表之外的问题）

当用户描述模糊任务时，按推理链定位工具：

**"帮我把图片转成 WebP"**
→ 需要图片转换工具 → 查映射表 → `webp (cwebp)` → `apt install -y webp`

**"帮我生成一个 PDF"**
→ 纯文本 → pandoc + LaTeX ｜ 带格式 → wkhtmltopdf ｜ Python → reportlab
→ 按场景选最合适的

**"帮我写个网页爬虫"**
→ 需要 HTTP 客户端 + HTML 解析 → Python: requests + beautifulsoup4
→ `pip3 install --break-system-packages requests beautifulsoup4 lxml`

**"帮我监控服务器"**
→ 系统监控 → htop / btop / iotop / ncdu → 按需求装

**"帮我处理 Excel 文件"**
→ 系统工具 → libreoffice-calc ｜ Python → openpyxl / pandas
→ 按场景选

**"帮我翻译这段文字"**
→ 不需要装工具 → agent 直接翻译
→ 批量/自动化 → 搜索 API 方案

**"帮我发邮件"**
→ Python smtplib（标准库，不需要额外安装）
