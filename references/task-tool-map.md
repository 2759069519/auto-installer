# 📋 任务 → 工具 全场景映射表

> 遇到以下任务时，直接查表安装对应工具。每条记录包含**降级链**——首选失败自动试下一条。

**降级链格式：** `方式1 → 方式2 → 方式3`
- `apt` = 系统包管理器 (自动适配: apt/dnf/yum/pacman/brew/apk)
- `snap` = snap install
- `pip` = pip3 install (安全模式: pipx → venv → 用户级安装)
- `npm` = npm install -g
- `dl` = 自动下载 GitHub Release 二进制（国内镜像加速）
- `src` = 源码编译
- `go` = go install
- `pipx` = pipx install

---

## 📂 文件搜索 & 操作

| 任务 | 工具 | 安装降级链 |
|------|------|-----------|
| 搜索文件内容 | `ripgrep (rg)` | `apt ripgrep → dl github.com/BurntSushi/ripgrep` |
| 查找文件名/路径 | `fd-find (fd)` | `apt fd-find → dl github.com/sharkdp/fd` |
| 查看文件（语法高亮） | `bat (batcat)` | `apt bat → snap bat → dl github.com/sharkdp/bat` |
| 查看目录树结构 | `tree` | `apt tree → snap tree → src` |
| 快速文本搜索 | `silversearcher (ag)` | `apt silversearcher-ag → src github.com/ggreer/the_silver_searcher` |
| 数据库定位文件 | `locate (mlocate)` | `apt mlocate` |
| 识别文件类型 | `file` | `apt file` |
| 管道进度条 | `pv` | `apt pv` |
| cp/mv/dd 进度 | `progress` | `apt progress → src github.com/Xfennec/progress` |
| sponge / vidir / ts | `moreutils` | `apt moreutils` |

---

## 📊 数据处理（JSON / YAML / XML / CSV / TOML）

| 任务 | 工具 | 安装降级链 |
|------|------|-----------|
| 处理 JSON | `jq` | `apt jq → dl github.com/jqlang/jq` |
| 处理 YAML | `yq` | `snap yq → dl github.com/mikefarah/yq` |
| 处理 XML | `xmlstarlet` | `apt xmlstarlet` |
| 处理 CSV（强大） | `miller (mlr)` | `apt miller → dl github.com/johnkerl/miller` |
| 处理 CSV（简单） | `csvtool` | `apt csvtool` |
| 万能数据查询 | `dasel` | `dl github.com/TomWright/dasel → go install github.com/TomWright/dasel` |
| 处理 TOML | `toml-cli` | `pip toml-cli` |

---

## 🌐 网络 & API

| 任务 | 工具 | 安装降级链 |
|------|------|-----------|
| HTTP 客户端（友好） | `httpie` | `apt httpie → pip httpie` |
| HTTP 下载 | `wget` | `apt wget` |
| DNS 查询 | `dnsutils (dig/nslookup)` | `apt dnsutils` |
| 域名信息查询 | `whois` | `apt whois` |
| 路由追踪 | `traceroute` | `apt traceroute` |
| 网络诊断 | `mtr` | `apt mtr-tiny` |
| Ping | `iputils-ping` | `apt iputils-ping` |
| 网络调试 | `netcat (nc)` | `apt netcat-openbsd` |
| 增强版 nc | `ncat (nmap)` | `apt ncat` |
| 双向数据管道 | `socat` | `apt socat` |
| 带宽测试 | `iperf3` | `apt iperf3` |
| 端口扫描 | `nmap` | `apt nmap` |
| SSL/TLS 检查 | `sslscan` | `apt sslscan` |
| Let's Encrypt 证书 | `certbot` | `apt certbot → pip certbot` |
| API 测试 & Mock | `json-server` | `npm json-server` |

---

## 📄 文档处理（PDF / Word / Excel / PPT / LaTeX）

| 任务 | 工具 | 安装降级链 |
|------|------|-----------|
| 文档格式万能转换 | `pandoc` | `apt pandoc → dl github.com/jgm/pandoc` |
| PDF 转文本 / 拆分 / 合并 | `poppler-utils` | `apt poppler-utils` |
| HTML → PDF | `wkhtmltopdf` | `apt wkhtmltopdf` |
| PDF 压缩 / 处理 | `ghostscript` | `apt ghostscript` |
| LaTeX 引擎 | `texlive-xetex` | `apt texlive-xetex texlive-fonts-recommended texlive-plain-generic` |
| 中文 PDF 支持 | `texlive-lang-chinese` | `apt texlive-lang-chinese` |
| man 页面渲染 | `groff` | `apt groff` |
| Word 处理 | `libreoffice-writer` | `apt libreoffice-writer` |
| Excel 处理 | `libreoffice-calc` | `apt libreoffice-calc` |
| 老 Word 读取 | `antiword` | `apt antiword` |
| ODT → 文本 | `odt2txt` | `apt odt2txt` |

---

## 🖼️ 图片处理

| 任务 | 工具 | 安装降级链 |
|------|------|-----------|
| 图片万能处理 | `imagemagick` | `apt imagemagick` |
| WebP 转换 | `cwebp / dwebp` | `apt webp` |
| PNG 有损压缩 | `pngquant` | `apt pngquant` |
| PNG 无损压缩 | `optipng` | `apt optipng` |
| JPEG 优化 | `jpegoptim` | `apt jpegoptim` |
| GIF 编辑 / 优化 | `gifsicle` | `apt gifsicle` |
| 流程图 / 架构图 | `graphviz (dot)` | `apt graphviz` |
| SVG → PNG | `rsvg-convert` | `apt librsvg2-bin` |
| 位图 → 矢量 | `potrace` | `apt potrace` |
| SVG 编辑（CLI） | `inkscape` | `apt inkscape` |
| 屏幕截图 | `scrot` | `apt scrot` |
| OCR 文字识别 | `tesseract` | `apt tesseract-ocr tesseract-ocr-chi-sim` |

---

## 🎵 音频处理

| 任务 | 工具 | 安装降级链 |
|------|------|-----------|
| 音频万能处理 | `sox` | `apt sox libsox-fmt-all` |
| MP3 编码 | `lame` | `apt lame` |
| Opus 编解码 | `opus-tools` | `apt opus-tools` |
| OGG 处理 | `vorbis-tools` | `apt vorbis-tools` |
| FLAC 无损 | `flac` | `apt flac` |
| WavPack | `wavpack` | `apt wavpack` |
| MP3 解码 | `mpg123` | `apt mpg123` |
| 音量标准化 | `normalize-audio` | `apt normalize-audio` |

---

## 🎬 视频处理

| 任务 | 工具 | 安装降级链 |
|------|------|-----------|
| 视频万能处理 | `ffmpeg` | `apt ffmpeg → snap ffmpeg` |
| 额外编解码器 | `libavcodec-extra` | `apt libavcodec-extra` |
| MKV 容器编辑 | `mkvtoolnix` | `apt mkvtoolnix` |

---

## 📦 压缩归档

| 任务 | 工具 | 安装降级链 |
|------|------|-----------|
| zip 打包 | `zip` | `apt zip` |
| 7z 格式 | `p7zip-full` | `apt p7zip-full` |
| RAR 解压 | `unrar` | `apt unrar` |
| Zstandard 压缩 | `zstd` | `apt zstd` |
| xz / lzma | `xz-utils` | `apt xz-utils` |
| 并行 gzip | `pigz` | `apt pigz` |
| 并行 bzip2 | `pbzip2` | `apt pbzip2` |
| 大文件高压缩 | `lrzip` | `apt lrzip` |
| CAB 解压 | `cabextract` | `apt cabextract` |

---

## 🔐 SSH & 远程 & 容器

| 任务 | 工具 | 安装降级链 |
|------|------|-----------|
| SSH 自动化密码登录 | `sshpass` | `apt sshpass` |
| 断线重连 shell | `mosh` | `apt mosh` |
| SSH 自动重连 | `autossh` | `apt autossh` |
| 交互式命令自动化 | `expect` | `apt expect` |
| 终端复用（强） | `tmux` | `apt tmux` |
| 终端复用（经典） | `screen` | `apt screen` |
| 容器 | `docker` | `curl -fsSL https://get.docker.com | bash` |

---

## 🛠️ 开发基础

| 任务 | 工具 | 安装降级链 |
|------|------|-----------|
| C/C++ 编译 | `build-essential` | `apt build-essential` |
| CMake 构建 | `cmake` | `apt cmake → snap cmake --classic` |
| 编译依赖查询 | `pkg-config` | `apt pkg-config` |
| Python pip | `python3-pip` | `apt python3-pip python3-venv python3-dev` |
| Python 隔离安装 | `pipx` | `apt pipx → pip pipx` |
| SSL 编译依赖 | `libssl-dev` | `apt libssl-dev libffi-dev` |
| TypeScript | `typescript + ts-node` | `npm typescript ts-node` |
| 进程管理 | `pm2` | `npm pm2` |
| 代码格式化 | `prettier` | `npm prettier` |
| 代码热重载 | `nodemon` | `npm nodemon` |
| 命令速查 | `tldr` | `npm tldr` |
| 快速 HTTP 服务 | `http-server` | `npm http-server` |
| 代码统计 | `cloc` | `apt cloc → npm cloc` |
| Git 增强 | `tig` | `apt tig` |
| Git diff 增强 | `delta` | `apt git-delta → dl github.com/dandavison/delta` |

---

## ☁️ DevOps & 云原生

| 任务 | 工具 | 安装降级链 |
|------|------|-----------|
| K8s 管理 | `kubectl` | `snap kubectl --classic → dl k8s.io` |
| 基础设施即代码 | `terraform` | `snap terraform --classic → dl hashicorp` |
| 配置管理 | `ansible` | `pip ansible` |
| 容器编排 | `docker-compose` | `apt docker-compose → dl github.com/docker/compose` |
| 容器镜像工具 | `skopeo` | `apt skopeo` |
| YAML lint | `yamllint` | `pip yamllint` |
| JSON lint | `jsonlint` | `npm jsonlint` |
| 环境变量管理 | `direnv` | `apt direnv → snap direnv` |
| HTTP 压测 | `wrk` | `apt wrk → src` |
| 反向代理测试 | `hey` | `go install github.com/rakyll/hey → dl github.com/rakyll/hey` |

---

## 🗄️ 数据库客户端

| 任务 | 工具 | 安装降级链 |
|------|------|-----------|
| MySQL 客户端 | `mysql-client` | `apt mysql-client` |
| PostgreSQL 客户端 | `postgresql-client` | `apt postgresql-client` |
| Redis 客户端 | `redis-tools` | `apt redis-tools` |
| MongoDB Shell | `mongosh` | `snap mongosh → dl mongodb` |
| SQLite | `sqlite3` | `apt sqlite3` |

---

## 📡 系统监控 & 调试

| 任务 | 工具 | 安装降级链 |
|------|------|-----------|
| 系统监控（好看） | `btop` | `apt btop → snap btop → dl github.com/aristocratos/btop` |
| 系统监控（经典） | `htop` | `apt htop` |
| IO 监控 | `iotop` | `apt iotop` |
| 磁盘占用可视化 | `ncdu` | `apt ncdu` |
| 打开文件查看 | `lsof` | `apt lsof` |
| 系统调用追踪 | `strace` | `apt strace` |
| 系统资源统计 | `dstat` | `apt dstat` |
| 系统统计工具集 | `sysstat` | `apt sysstat` |
| 硬盘健康 | `smartmontools` | `apt smartmontools` |
| 网络流量统计 | `vnstat` | `apt vnstat` |
| 日志查看 | `lnav` | `apt lnav → snap lnav` |
| 日志实时追踪 | `multitail` | `apt multitail` |

---

## ⚡ 终端效率

| 任务 | 工具 | 安装降级链 |
|------|------|-----------|
| GNU 并行执行 | `parallel` | `apt parallel` |
| readline 包装 | `rlwrap` | `apt rlwrap` |
| 目录快速跳转 | `zoxide` | `apt zoxide → dl github.com/ajeetdsouza/zoxide` |
| 模糊查找 | `fzf` | `apt fzf → dl github.com/junegunn/fzf → src` |
| 终端文件管理 | `yazi` | `cargo install yazi → dl github.com/sxyazi/yazi` |
| Git TUI | `lazygit` | `apt lazygit → snap lazygit → dl github.com/jesseduffield/lazygit` |

---

## 🔒 安全 & 加密

| 任务 | 工具 | 安装降级链 |
|------|------|-----------|
| 现代加密 | `age` | `apt age → dl github.com/FiloSottile/age` |
| 密钥管理 | `sops` | `apt sops → dl github.com/getsops/sops` |
| 防暴力破解 | `fail2ban` | `apt fail2ban` |
| GPG 加密 | `gnupg` | `apt gnupg` |
| 密码管理 | `pass` | `apt pass` |
| SSL/TLS | `openssl` | `apt openssl` |

---

## 🐍 Python 数据科学 & ML

| 任务 | 工具 | 安装降级链 |
|------|------|-----------|
| 数组 / 矩阵计算 | `numpy` | `pip numpy → pip -i https://pypi.tuna.tsinghua.edu.cn/simple numpy` |
| 数据分析 | `pandas` | `pip pandas → pip -i https://pypi.tuna.tsinghua.edu.cn/simple pandas` |
| 科学计算 | `scipy` | `pip scipy → pip -i https://pypi.tuna.tsinghua.edu.cn/simple scipy` |
| 机器学习 | `scikit-learn` | `pip scikit-learn → pip -i https://pypi.tuna.tsinghua.edu.cn/simple scikit-learn` |
| 梯度提升 | `xgboost` | `pip xgboost → pip -i https://pypi.tuna.tsinghua.edu.cn/simple xgboost` |
| 统计建模 | `statsmodels` | `pip statsmodels → pip -i https://pypi.tuna.tsinghua.edu.cn/simple statsmodels` |
| 数据可视化 | `matplotlib` | `pip matplotlib → pip -i https://pypi.tuna.tsinghua.edu.cn/simple matplotlib` |
| 统计可视化 | `seaborn` | `pip seaborn → pip -i https://pypi.tuna.tsinghua.edu.cn/simple seaborn` |
| Jupyter Notebook | `jupyter` | `pip jupyter → pip -i https://pypi.tuna.tsinghua.edu.cn/simple jupyter` |
| Excel 读写 | `openpyxl, xlrd` | `pip openpyxl xlrd → pip -i https://pypi.tuna.tsinghua.edu.cn/simple openpyxl xlrd` |
| 表格格式化 | `tabulate` | `pip tabulate → pip -i https://pypi.tuna.tsinghua.edu.cn/simple tabulate` |
| YAML（Python） | `pyyaml` | `pip pyyaml → pip -i https://pypi.tuna.tsinghua.edu.cn/simple pyyaml` |
| HTTP 客户端 | `requests` | `pip requests → pip -i https://pypi.tuna.tsinghua.edu.cn/simple requests` |
| 网页解析 | `beautifulsoup4, lxml` | `pip beautifulsoup4 lxml → pip -i https://pypi.tuna.tsinghua.edu.cn/simple beautifulsoup4 lxml` |
| 图片处理（Python） | `Pillow` | `pip Pillow → pip -i https://pypi.tuna.tsinghua.edu.cn/simple Pillow` |
| PDF 生成（Python） | `reportlab` | `pip reportlab → pip -i https://pypi.tuna.tsinghua.edu.cn/simple reportlab` |
| Markdown 处理 | `markdown` | `pip markdown → pip -i https://pypi.tuna.tsinghua.edu.cn/simple markdown` |
| RSS 解析 | `feedparser` | `pip feedparser → pip -i https://pypi.tuna.tsinghua.edu.cn/simple feedparser` |
| HTML 解析 | `html5lib` | `pip html5lib → pip -i https://pypi.tuna.tsinghua.edu.cn/simple html5lib` |

---

## 🦞 ClawHub 技能（免费，不需要 key）

| 能力 | 技能 slug | 安装命令 |
|------|----------|---------|
| 图表生成 | `chart-generator` | `npx clawhub install chart-generator --workdir ~/.openclaw` |
| 图片处理增强 | `image-process` | `npx clawhub install image-process --workdir ~/.openclaw` |
| PDF 专业处理 | `pdf-toolkit-pro` | `npx clawhub install pdf-toolkit-pro --workdir ~/.openclaw` |
| 文档处理增强 | `document-pro` | `npx clawhub install document-pro --workdir ~/.openclaw` |
| 数据图表工具 | `data-chart-tool` | `npx clawhub install data-chart-tool --workdir ~/.openclaw` |
| 自动化工作流 | `automation-workflows` | `npx clawhub install automation-workflows --workdir ~/.openclaw` |

---

## 🧩 常见报错 → 修复速查

| 报错信息 | 原因 | 修复 |
|---------|------|------|
| `command not found: xxx` | 缺系统工具 | 查映射表，无则 `apt search xxx` |
| `ModuleNotFoundError: No module named 'xxx'` | 缺 Python 包 | `pip install xxx` |
| `Cannot find module 'xxx'` | 缺 Node 模块 | `npm install -g xxx` |
| `error while loading shared libraries: libxxx.so` | 缺共享库 | `apt install libxxx-dev` |
| `Permission denied` | 权限不足 | 检查 `sudo` 或 `chmod` |
| `No space left on device` | 磁盘满 | `ncdu /` 清理 |
| `Connection refused` | 服务未启动 | `systemctl start xxx` |
| `SSL certificate verify failed` | 证书问题 | `apt ca-certificates && update-ca-certificates` |
| `locale.Error: unsupported locale` | 缺 locale | `apt locales && locale-gen en_US.UTF-8` |
| `ImportError: libGL.so.1` | 缺 OpenGL | `apt libgl1-mesa-glx` |
| `Could not get lock /var/lib/dpkg` | apt 被锁 | `rm /var/lib/dpkg/lock* && dpkg --configure -a` |
| `GPG error ... NO_PUBKEY` | 缺 apt key | `apt-key adv --keyserver keyserver.ubuntu.com --recv-keys <KEY>` |
| `unmet dependencies` | 依赖冲突 | `apt --fix-broken install` |
| `Out of memory / Killed` | 内存不足 | `free -h` 检查，加 swap |
| `docker: permission denied` | Docker 权限 | `usermod -aG docker $USER` |
| `make: No rule to make target` | 缺构建依赖 | 装 `build-essential` |

---

## 🔧 常用组合安装（一行搞定）

```bash
# 🖼️ 图片处理全家桶
apt install -y imagemagick webp pngquant jpegoptim gifsicle graphviz librsvg2-bin

# 📄 文档处理全家桶
apt install -y pandoc poppler-utils wkhtmltopdf ghostscript

# 🌐 网络工具全家桶
apt install -y httpie dnsutils mtr-tiny socat nmap certbot

# 🐍 Python 数据科学全家桶
pip3 install numpy pandas scipy scikit-learn matplotlib seaborn

# 🎵 音频处理全家桶
apt install -y sox libsox-fmt-all lame opus-tools flac mpg123 normalize-audio

# ☁️ DevOps 全家桶
snap install kubectl --classic && snap install terraform --classic && pip3 install ansible

# ⚡ 终端效率全家桶
apt install -y tmux fzf zoxide btop ripgrep fd-find tree
```

---

## 🧠 任务推理链

**"帮我把图片转成 WebP"**
→ `webp (cwebp)` → `apt webp`

**"帮我生成一个 PDF"**
→ 纯文本 → pandoc+LaTeX ｜ 带格式 → wkhtmltopdf ｜ Python → reportlab

**"帮我写个网页爬虫"**
→ `pip requests beautifulsoup4 lxml`

**"帮我处理 Excel 文件"**
→ 系统 → libreoffice-calc ｜ Python → openpyxl/pandas

**"帮我发邮件"**
→ Python smtplib（标准库，无需安装）

## 🔧 自动发现的工具

| 任务 | 工具 | 安装降级链 |
|------|------|-----------|
| Docker管理TUI | `lazydocker` | `apt lazydocker` |

---

## 🔤 中文别名速查（v2.2 新增）

| 中文描述 | 工具 | 安装降级链 |
|---------|------|-----------|
| 解压文件/解压缩/解包 | `p7zip-full` | `apt p7zip-full` |
| 压缩文件/打包压缩 | `zip` | `apt zip` |
| 下载文件/HTTP下载 | `wget` | `apt wget` |
| 查找文件/搜索文件名 | `fd-find (fd)` | `apt fd-find → dl github.com/sharkdp/fd` |
| 搜索文本/搜索内容 | `ripgrep (rg)` | `apt ripgrep → dl github.com/BurntSushi/ripgrep` |
| 查看目录/目录树 | `tree` | `apt tree → snap tree → src` |
| 系统监控/资源监控 | `btop` | `apt btop → snap btop → dl github.com/aristocratos/btop` |
| 进程管理/查看进程 | `htop` | `apt htop` |
| PDF处理/转换PDF | `poppler-utils` | `apt poppler-utils` |
| 图片处理/图片转换 | `imagemagick` | `apt imagemagick` |
| 音频处理/音频转换 | `sox` | `apt sox libsox-fmt-all` |
| 视频处理/视频转换 | `ffmpeg` | `apt ffmpeg → snap ffmpeg` |
| JSON处理/解析JSON | `jq` | `apt jq → dl github.com/jqlang/jq` |
| YAML处理/解析YAML | `yq` | `snap yq → dl github.com/mikefarah/yq` |
| HTTP请求/发请求 | `httpie` | `apt httpie → pip httpie` |
| SSH连接/远程登录 | `sshpass` | `apt sshpass` |
| 密码管理/加密文件 | `gnupg` | `apt gnupg` |
| 格式转换/文档转换 | `pandoc` | `apt pandoc → dl github.com/jgm/pandoc` |
| 截图/屏幕截图 | `scrot` | `apt scrot` |
| OCR/文字识别 | `tesseract` | `apt tesseract-ocr tesseract-ocr-chi-sim` |
| Git增强/Git界面 | `lazygit` | `apt lazygit → snap lazygit → dl github.com/jesseduffield/lazygit` |
| Docker管理/容器管理 | `lazydocker` | `apt lazydocker` |
| 模糊搜索/模糊查找 | `fzf` | `apt fzf → dl github.com/junegunn/fzf → src` |
| 磁盘分析/磁盘占用 | `ncdu` | `apt ncdu` |
| 端口查看/网络连接 | `lsof` | `apt lsof` |
| 网络扫描/端口扫描 | `nmap` | `apt nmap` |
| 终端复用/后台运行 | `tmux` | `apt tmux` |
| 并行执行/批量执行 | `parallel` | `apt parallel` |
| 日志查看/日志分析 | `lnav` | `apt lnav → snap lnav` |
| 内存分析/内存泄漏 | `valgrind` | `apt valgrind` |
| 权限错误/没有权限 | `chmod` | `chmod` |
| Python数据分析 | `pandas` | `pip pandas → pip -i https://pypi.tuna.tsinghua.edu.cn/simple pandas` |
| Python机器学习 | `scikit-learn` | `pip scikit-learn → pip -i https://pypi.tuna.tsinghua.edu.cn/simple scikit-learn` |
| Python画图/数据可视化 | `matplotlib` | `pip matplotlib → pip -i https://pypi.tuna.tsinghua.edu.cn/simple matplotlib` |
| Excel处理/读写Excel | `openpyxl, xlrd` | `pip openpyxl xlrd → pip -i https://pypi.tuna.tsinghua.edu.cn/simple openpyxl xlrd` |
| 网页爬虫/抓取网页 | `requests, beautifulsoup4` | `pip requests beautifulsoup4 lxml → pip -i https://pypi.tuna.tsinghua.edu.cn/simple requests beautifulsoup4 lxml` |
| Markdown转HTML | `markdown` | `pip markdown → pip -i https://pypi.tuna.tsinghua.edu.cn/simple markdown` |
| RSS订阅/RSS解析 | `feedparser` | `pip feedparser → pip -i https://pypi.tuna.tsinghua.edu.cn/simple feedparser` |
| 服务器初始化/新机器 | `build-essential` | `apt build-essential` |
| Docker安装/装Docker | `docker` | `curl -fsSL https://get.docker.com | bash` |
| Go语言/Go开发 | `golang` | `apt golang` |
| Node.js/Node | `nodejs` | `apt nodejs npm` |
| Rust开发 | `rustc` | `apt rustc cargo` |
