#!/usr/bin/env python3
"""
🦞 auto-installer v3.0 — Python 核心
6层智能搜索 + 降级链 + 自学习 + 跨平台 + 安全加固
"""
import os
import sys
import re
import json
import subprocess
import time
import shutil
import tempfile
import hashlib
from pathlib import Path
from datetime import datetime, timedelta
from dataclasses import dataclass, field
from typing import Optional
from urllib.request import urlopen, Request
from urllib.error import URLError

# ── 颜色 ────────────────────────────────────────────
class C:
    G = '\033[0;32m'; B = '\033[0;34m'; Y = '\033[1;33m'
    CY = '\033[0;36m'; R = '\033[0;31m'; BD = '\033[1m'; DM = '\033[2m'; NC = '\033[0m'

def info(msg): print(f"  {C.G}{C.BD}{msg}{C.NC}")
def warn(msg): print(f"  {C.Y}⚠ {msg}{C.NC}")
def err(msg):  print(f"  {C.R}{C.BD}❌ {msg}{C.NC}")
def dim(msg):  print(f"  {C.DM}{msg}{C.NC}")
def note(msg): print(f"  {C.CY}{msg}{C.NC}")


# ═══════════════════════════════════════════════════════
# 配置
# ═══════════════════════════════════════════════════════
@dataclass
class Config:
    skill_dir: Path = field(default_factory=lambda: Path(__file__).resolve().parent.parent)
    map_file: Path = field(init=False)
    learn_log: Path = field(init=False)
    fail_log: Path = field(init=False)
    stats_file: Path = field(init=False)
    history_file: Path = field(init=False)
    installed_index: Path = field(init=False)

    def __post_init__(self):
        refs = self.skill_dir / "references"
        data = self.skill_dir / "data"
        self.map_file = refs / "task-tool-map.md"
        self.learn_log = refs / "learned-tools.log"
        self.fail_log = refs / "failed-installs.log"
        self.stats_file = refs / "usage-stats.json"
        self.history_file = data / "install-history.jsonl"
        self.installed_index = data / "installed-index.json"


# ═══════════════════════════════════════════════════════
# 平台检测
# ═══════════════════════════════════════════════════════
class Platform:
    # 包名映射: canonical_name -> { manager: actual_package_name }
    PACKAGE_MAP = {
        "ripgrep":    {"apt": "ripgrep", "dnf": "ripgrep", "yum": "ripgrep", "pacman": "ripgrep", "brew": "ripgrep", "apk": "ripgrep"},
        "fd":         {"apt": "fd-find", "dnf": "fd-find", "yum": "fd-find", "pacman": "fd", "brew": "fd", "apk": "fd"},
        "bat":        {"apt": "bat", "dnf": "bat", "yum": "bat", "pacman": "bat", "brew": "bat", "apk": "bat"},
        "fzf":        {"apt": "fzf", "dnf": "fzf", "yum": "fzf", "pacman": "fzf", "brew": "fzf", "apk": "fzf"},
        "jq":         {"apt": "jq", "dnf": "jq", "yum": "jq", "pacman": "jq", "brew": "jq", "apk": "jq"},
        "tree":       {"apt": "tree", "dnf": "tree", "yum": "tree", "pacman": "tree", "brew": "tree", "apk": "tree"},
        "htop":       {"apt": "htop", "dnf": "htop", "yum": "htop", "pacman": "htop", "brew": "htop", "apk": "htop"},
        "btop":       {"apt": "btop", "dnf": "btop", "yum": "btop", "pacman": "btop", "brew": "btop", "apk": "btop"},
        "tmux":       {"apt": "tmux", "dnf": "tmux", "yum": "tmux", "pacman": "tmux", "brew": "tmux", "apk": "tmux"},
        "ncdu":       {"apt": "ncdu", "dnf": "ncdu", "yum": "ncdu", "pacman": "ncdu", "brew": "ncdu", "apk": "ncdu"},
        "lsof":       {"apt": "lsof", "dnf": "lsof", "yum": "lsof", "pacman": "lsof", "brew": "lsof", "apk": "lsof"},
        "strace":     {"apt": "strace", "dnf": "strace", "yum": "strace", "pacman": "strace", "apk": "strace"},
        "socat":      {"apt": "socat", "dnf": "socat", "yum": "socat", "pacman": "socat", "brew": "socat", "apk": "socat"},
        "nmap":       {"apt": "nmap", "dnf": "nmap", "yum": "nmap", "pacman": "nmap", "brew": "nmap", "apk": "nmap"},
        "wget":       {"apt": "wget", "dnf": "wget", "yum": "wget", "pacman": "wget", "brew": "wget", "apk": "wget"},
        "curl":       {"apt": "curl", "dnf": "curl", "yum": "curl", "pacman": "curl", "brew": "curl", "apk": "curl"},
        "git":        {"apt": "git", "dnf": "git", "yum": "git", "pacman": "git", "brew": "git", "apk": "git"},
        "vim":        {"apt": "vim", "dnf": "vim", "yum": "vim", "pacman": "vim", "brew": "vim", "apk": "vim"},
        "make":       {"apt": "make", "dnf": "make", "yum": "make", "pacman": "make", "brew": "make"},
        "cmake":      {"apt": "cmake", "dnf": "cmake", "yum": "cmake", "pacman": "cmake", "brew": "cmake"},
        "gcc":        {"apt": "gcc", "dnf": "gcc", "yum": "gcc", "pacman": "gcc", "brew": "gcc"},
        "python3":    {"apt": "python3", "dnf": "python3", "yum": "python3", "pacman": "python", "brew": "python3", "apk": "python3"},
        "nodejs":     {"apt": "nodejs", "dnf": "nodejs", "yum": "nodejs", "pacman": "nodejs", "brew": "node", "apk": "nodejs"},
        "ffmpeg":     {"apt": "ffmpeg", "dnf": "ffmpeg", "yum": "ffmpeg", "pacman": "ffmpeg", "brew": "ffmpeg", "apk": "ffmpeg"},
        "imagemagick":{"apt": "imagemagick", "dnf": "ImageMagick", "yum": "ImageMagick", "pacman": "imagemagick", "brew": "imagemagick", "apk": "imagemagick"},
        "pandoc":     {"apt": "pandoc", "dnf": "pandoc", "yum": "pandoc", "pacman": "pandoc", "brew": "pandoc"},
        "zip":        {"apt": "zip", "dnf": "zip", "yum": "zip", "pacman": "zip", "brew": "zip", "apk": "zip"},
        "unzip":      {"apt": "unzip", "dnf": "unzip", "yum": "unzip", "pacman": "unzip", "brew": "unzip", "apk": "unzip"},
        "p7zip":      {"apt": "p7zip-full", "dnf": "p7zip", "yum": "p7zip", "pacman": "p7zip", "brew": "p7zip", "apk": "p7zip"},
        "zstd":       {"apt": "zstd", "dnf": "zstd", "yum": "zstd", "pacman": "zstd", "brew": "zstd", "apk": "zstd"},
        "xz":         {"apt": "xz-utils", "dnf": "xz", "yum": "xz", "pacman": "xz", "brew": "xz", "apk": "xz"},
        "screen":     {"apt": "screen", "dnf": "screen", "yum": "screen", "pacman": "screen", "brew": "screen", "apk": "screen"},
        "mosh":       {"apt": "mosh", "dnf": "mosh", "yum": "mosh", "pacman": "mosh", "brew": "mosh"},
        "autossh":    {"apt": "autossh", "dnf": "autossh", "yum": "autossh", "pacman": "autossh", "brew": "autossh"},
        "expect":     {"apt": "expect", "dnf": "expect", "yum": "expect", "pacman": "expect", "brew": "expect"},
        "sshpass":    {"apt": "sshpass", "dnf": "sshpass", "yum": "sshpass", "pacman": "sshpass", "brew": "sshpass"},
        "tig":        {"apt": "tig", "dnf": "tig", "yum": "tig", "pacman": "tig", "brew": "tig"},
        "lazygit":    {"apt": "lazygit", "dnf": "lazygit", "yum": "lazygit", "pacman": "lazygit", "brew": "lazygit"},
        "lazydocker": {"apt": "lazydocker", "dnf": "lazydocker", "pacman": "lazydocker", "brew": "lazydocker"},
        "zoxide":     {"apt": "zoxide", "dnf": "zoxide", "yum": "zoxide", "pacman": "zoxide", "brew": "zoxide"},
        "yazi":       {"apt": "yazi", "pacman": "yazi", "brew": "yazi"},
        "parallel":   {"apt": "parallel", "dnf": "parallel", "yum": "parallel", "pacman": "parallel", "brew": "parallel"},
        "moreutils":  {"apt": "moreutils", "dnf": "moreutils", "yum": "moreutils", "pacman": "moreutils", "brew": "moreutils"},
        "pv":         {"apt": "pv", "dnf": "pv", "yum": "pv", "pacman": "pv", "brew": "pv"},
        "silversearcher": {"apt": "silversearcher-ag", "dnf": "the_silver_searcher", "yum": "the_silver_searcher", "pacman": "the_silver_searcher", "brew": "the_silver_searcher"},
        "file":       {"apt": "file", "dnf": "file", "yum": "file", "pacman": "file", "brew": "file", "apk": "file"},
        "mlocate":    {"apt": "mlocate", "dnf": "mlocate", "yum": "mlocate", "pacman": "mlocate"},
        "iotop":      {"apt": "iotop", "dnf": "iotop", "yum": "iotop", "pacman": "iotop"},
        "dstat":      {"apt": "dstat", "dnf": "dstat", "yum": "dstat", "pacman": "dstat"},
        "sysstat":    {"apt": "sysstat", "dnf": "sysstat", "yum": "sysstat", "pacman": "sysstat"},
        "lnav":       {"apt": "lnav", "dnf": "lnav", "pacman": "lnav", "brew": "lnav"},
        "multitail":  {"apt": "multitail", "dnf": "multitail", "pacman": "multitail", "brew": "multitail"},
        "fail2ban":   {"apt": "fail2ban", "dnf": "fail2ban", "yum": "fail2ban", "pacman": "fail2ban"},
        "gnupg":      {"apt": "gnupg", "dnf": "gnupg", "yum": "gnupg", "pacman": "gnupg", "brew": "gnupg", "apk": "gnupg"},
        "pass":       {"apt": "pass", "dnf": "pass", "yum": "pass", "pacman": "pass", "brew": "pass"},
        "openssl":    {"apt": "openssl", "dnf": "openssl", "yum": "openssl", "pacman": "openssl", "brew": "openssl", "apk": "openssl"},
        "age":        {"apt": "age", "dnf": "age", "pacman": "age", "brew": "age"},
        "sops":       {"apt": "sops", "brew": "sops"},
        "socat":      {"apt": "socat", "dnf": "socat", "yum": "socat", "pacman": "socat", "brew": "socat", "apk": "socat"},
        "iperf3":     {"apt": "iperf3", "dnf": "iperf3", "yum": "iperf3", "pacman": "iperf3", "brew": "iperf3", "apk": "iperf3"},
        "mtr":        {"apt": "mtr-tiny", "dnf": "mtr", "yum": "mtr", "pacman": "mtr", "brew": "mtr", "apk": "mtr"},
        "traceroute": {"apt": "traceroute", "dnf": "traceroute", "yum": "traceroute", "pacman": "traceroute", "brew": "traceroute"},
        "whois":      {"apt": "whois", "dnf": "whois", "yum": "whois", "pacman": "whois", "brew": "whois"},
        "dnsutils":   {"apt": "dnsutils", "dnf": "bind-utils", "yum": "bind-utils", "pacman": "bind", "apk": "bind-tools"},
        "netcat":     {"apt": "netcat-openbsd", "dnf": "nmap-ncat", "yum": "nmap-ncat", "pacman": "gnu-netcat", "brew": "netcat"},
        "ncat":       {"apt": "ncat", "dnf": "nmap-ncat", "yum": "nmap-ncat", "pacman": "nmap", "brew": "nmap"},
        "httpie":     {"apt": "httpie", "dnf": "httpie", "yum": "httpie", "pacman": "httpie", "brew": "httpie"},
        "sslscan":    {"apt": "sslscan", "dnf": "sslscan", "yum": "sslscan", "pacman": "sslscan", "brew": "sslscan"},
        "certbot":    {"apt": "certbot", "dnf": "certbot", "yum": "certbot", "pacman": "certbot", "brew": "certbot"},
        "poppler":    {"apt": "poppler-utils", "dnf": "poppler-utils", "yum": "poppler-utils", "pacman": "poppler", "brew": "poppler"},
        "ghostscript":{"apt": "ghostscript", "dnf": "ghostscript", "yum": "ghostscript", "pacman": "ghostscript", "brew": "ghostscript"},
        "wkhtmltopdf":{"apt": "wkhtmltopdf", "dnf": "wkhtmltopdf", "yum": "wkhtmltopdf", "pacman": "wkhtmltopdf", "brew": "wkhtmltopdf"},
        "texlive":    {"apt": "texlive-xetex", "dnf": "texlive-xetex", "yum": "texlive-xetex", "pacman": "texlive-xetex"},
        "groff":      {"apt": "groff", "dnf": "groff", "yum": "groff", "pacman": "groff", "brew": "groff"},
        "graphviz":   {"apt": "graphviz", "dnf": "graphviz", "yum": "graphviz", "pacman": "graphviz", "brew": "graphviz"},
        "rsvg":       {"apt": "librsvg2-bin", "dnf": "librsvg2", "yum": "librsvg2", "pacman": "librsvg", "brew": "librsvg"},
        "pngquant":   {"apt": "pngquant", "dnf": "pngquant", "yum": "pngquant", "pacman": "pngquant", "brew": "pngquant"},
        "optipng":    {"apt": "optipng", "dnf": "optipng", "yum": "optipng", "pacman": "optipng", "brew": "optipng"},
        "jpegoptim":  {"apt": "jpegoptim", "dnf": "jpegoptim", "yum": "jpegoptim", "pacman": "jpegoptim", "brew": "jpegoptim"},
        "gifsicle":   {"apt": "gifsicle", "dnf": "gifsicle", "yum": "gifsicle", "pacman": "gifsicle", "brew": "gifsicle"},
        "webp":       {"apt": "webp", "dnf": "libwebp-tools", "yum": "libwebp-tools", "pacman": "libwebp", "brew": "webp"},
        "tesseract":  {"apt": "tesseract-ocr", "dnf": "tesseract", "yum": "tesseract", "pacman": "tesseract", "brew": "tesseract"},
        "sox":        {"apt": "sox", "dnf": "sox", "yum": "sox", "pacman": "sox", "brew": "sox"},
        "lame":       {"apt": "lame", "dnf": "lame", "yum": "lame", "pacman": "lame", "brew": "lame"},
        "flac":       {"apt": "flac", "dnf": "flac", "yum": "flac", "pacman": "flac", "brew": "flac"},
        "opus":       {"apt": "opus-tools", "dnf": "opus-tools", "yum": "opus-tools", "pacman": "opus-tools", "brew": "opus-tools"},
        "mpg123":     {"apt": "mpg123", "dnf": "mpg123", "yum": "mpg123", "pacman": "mpg123", "brew": "mpg123"},
        "mkvtoolnix": {"apt": "mkvtoolnix", "dnf": "mkvtoolnix", "yum": "mkvtoolnix", "pacman": "mkvtoolnix", "brew": "mkvtoolnix"},
        "unrar":      {"apt": "unrar", "dnf": "unrar", "yum": "unrar", "pacman": "unrar", "brew": "unrar"},
        "pigz":       {"apt": "pigz", "dnf": "pigz", "yum": "pigz", "pacman": "pigz", "brew": "pigz"},
        "pbzip2":     {"apt": "pbzip2", "dnf": "pbzip2", "yum": "pbzip2", "pacman": "pbzip2", "brew": "pbzip2"},
        "cabextract": {"apt": "cabextract", "dnf": "cabextract", "yum": "cabextract", "pacman": "cabextract", "brew": "cabextract"},
        "sqlite3":    {"apt": "sqlite3", "dnf": "sqlite", "yum": "sqlite", "pacman": "sqlite", "brew": "sqlite"},
        "mysql":      {"apt": "mysql-client", "dnf": "mariadb", "yum": "mariadb", "pacman": "mariadb-clients", "brew": "mysql-client"},
        "psql":       {"apt": "postgresql-client", "dnf": "postgresql", "yum": "postgresql", "pacman": "postgresql", "brew": "libpq"},
        "redis-cli":  {"apt": "redis-tools", "dnf": "redis", "yum": "redis", "pacman": "redis", "brew": "redis"},
        "kubectl":    {"apt": "kubectl", "dnf": "kubectl", "brew": "kubectl"},
        "terraform":  {"apt": "terraform", "dnf": "terraform", "brew": "terraform"},
        "ansible":    {"apt": "ansible", "dnf": "ansible", "yum": "ansible", "pacman": "ansible", "brew": "ansible"},
        "docker-compose": {"apt": "docker-compose", "dnf": "docker-compose", "yum": "docker-compose", "pacman": "docker-compose", "brew": "docker-compose"},
        "direnv":     {"apt": "direnv", "dnf": "direnv", "yum": "direnv", "pacman": "direnv", "brew": "direnv"},
        "skopeo":     {"apt": "skopeo", "dnf": "skopeo", "yum": "skopeo", "pacman": "skopeo"},
        "cloc":       {"apt": "cloc", "dnf": "cloc", "yum": "cloc", "pacman": "cloc", "brew": "cloc"},
        "rlwrap":     {"apt": "rlwrap", "dnf": "rlwrap", "yum": "rlwrap", "pacman": "rlwrap", "brew": "rlwrap"},
        "valgrind":   {"apt": "valgrind", "dnf": "valgrind", "yum": "valgrind", "pacman": "valgrind", "brew": "valgrind"},
        "smartctl":   {"apt": "smartmontools", "dnf": "smartmontools", "yum": "smartmontools", "pacman": "smartmontools", "brew": "smartmontools"},
        "vnstat":     {"apt": "vnstat", "dnf": "vnstat", "yum": "vnstat", "pacman": "vnstat"},
        "scrot":      {"apt": "scrot", "dnf": "scrot", "yum": "scrot", "pacman": "scrot"},
        "potrace":    {"apt": "potrace", "dnf": "potrace", "yum": "potrace", "pacman": "potrace", "brew": "potrace"},
        "inkscape":   {"apt": "inkscape", "dnf": "inkscape", "yum": "inkscape", "pacman": "inkscape", "brew": "inkscape"},
        "antiword":   {"apt": "antiword", "dnf": "antiword", "yum": "antiword", "pacman": "antiword"},
        "odt2txt":    {"apt": "odt2txt", "dnf": "odt2txt", "yum": "odt2txt", "pacman": "odt2txt", "brew": "odt2txt"},
        "libreoffice-writer": {"apt": "libreoffice-writer", "dnf": "libreoffice-writer", "yum": "libreoffice-writer", "pacman": "libreoffice-fresh"},
        "libreoffice-calc":   {"apt": "libreoffice-calc", "dnf": "libreoffice-calc", "yum": "libreoffice-calc", "pacman": "libreoffice-fresh"},
        # build tools
        "build-essential": {"apt": "build-essential", "dnf": "@development-tools", "yum": "@development-tools", "pacman": "base-devel"},
        "libssl-dev":  {"apt": "libssl-dev", "dnf": "openssl-devel", "yum": "openssl-devel", "pacman": "openssl"},
        "libffi-dev":  {"apt": "libffi-dev", "dnf": "libffi-devel", "yum": "libffi-devel", "pacman": "libffi"},
        "python3-dev": {"apt": "python3-dev", "dnf": "python3-devel", "yum": "python3-devel", "pacman": "python"},
        "pkg-config":  {"apt": "pkg-config", "dnf": "pkgconfig", "yum": "pkgconfig", "pacman": "pkg-config", "brew": "pkg-config"},
        "golang":      {"apt": "golang", "dnf": "golang", "yum": "golang", "pacman": "go", "brew": "go", "apk": "go"},
        "rustc":       {"apt": "rustc", "dnf": "rust", "yum": "rust", "pacman": "rust", "brew": "rust"},
        "cargo":       {"apt": "cargo", "dnf": "cargo", "yum": "cargo", "pacman": "rust", "brew": "rust"},
        # libraries
        "libgl1":      {"apt": "libgl1-mesa-glx", "dnf": "mesa-libGL", "yum": "mesa-libGL", "pacman": "mesa", "brew": ""},
        "ca-certificates": {"apt": "ca-certificates", "dnf": "ca-certificates", "yum": "ca-certificates", "pacman": "ca-certificates", "apk": "ca-certificates"},
        "locales":     {"apt": "locales", "dnf": "glibc-langpack-en", "yum": "glibc-langpack-en", "pacman": "glibc"},
        "locales-gen": {"apt": "locales", "dnf": "glibc-common", "yum": "glibc-common", "pacman": "glibc"},
    }

    def __init__(self):
        self.mgr = "unknown"
        self.os_id = ""
        self.os_version = ""
        self._detect()

    def _detect(self):
        # OS
        if os.path.exists("/etc/os-release"):
            with open("/etc/os-release") as f:
                for line in f:
                    if line.startswith("ID="):
                        self.os_id = line.strip().split("=", 1)[1].strip('"')
                    elif line.startswith("VERSION_ID="):
                        self.os_version = line.strip().split("=", 1)[1].strip('"')
        elif os.uname().sysname == "Darwin":
            self.os_id = "macos"
            try:
                self.os_version = subprocess.check_output(["sw_vers", "-productVersion"], text=True).strip()
            except Exception:
                self.os_version = "unknown"

        # Package manager
        for m in ["apt", "dnf", "yum", "pacman", "brew", "apk", "zypper"]:
            if shutil.which(m):
                self.mgr = m
                return

    def map_pkg(self, canonical_name: str) -> str:
        """将 canonical 包名映射到当前系统的实际包名"""
        entry = self.PACKAGE_MAP.get(canonical_name)
        if entry:
            return entry.get(self.mgr, canonical_name)
        return canonical_name

    def is_installed(self, pkg: str) -> bool:
        """检查包是否已安装"""
        if shutil.which(pkg):
            return True
        try:
            if self.mgr == "apt":
                r = subprocess.run(["dpkg", "-s", pkg], capture_output=True, text=True)
                return "install ok installed" in r.stdout
            elif self.mgr in ("dnf", "yum"):
                r = subprocess.run([self.mgr, "list", "installed", pkg], capture_output=True, text=True)
                return r.returncode == 0
            elif self.mgr == "pacman":
                r = subprocess.run(["pacman", "-Qi", pkg], capture_output=True, text=True)
                return r.returncode == 0
            elif self.mgr == "brew":
                r = subprocess.run(["brew", "list", pkg], capture_output=True, text=True)
                return r.returncode == 0
            elif self.mgr == "apk":
                r = subprocess.run(["apk", "info", "-e", pkg], capture_output=True, text=True)
                return r.returncode == 0
        except Exception:
            pass
        return False

    def search(self, query: str) -> list[str]:
        """搜索系统包"""
        try:
            if self.mgr == "apt":
                r = subprocess.run(["apt", "search", query], capture_output=True, text=True, timeout=10)
                return [l for l in r.stdout.splitlines() if query.lower() in l.lower() and not l.startswith(("Sorting", "Full", "WARNING"))][:5]
            elif self.mgr in ("dnf", "yum"):
                r = subprocess.run([self.mgr, "search", query], capture_output=True, text=True, timeout=10)
                return [l for l in r.stdout.splitlines() if query.lower() in l.lower()][:5]
            elif self.mgr == "pacman":
                r = subprocess.run(["pacman", "-Ss", query], capture_output=True, text=True, timeout=10)
                return [l for l in r.stdout.splitlines() if query.lower() in l.lower()][:5]
            elif self.mgr == "brew":
                r = subprocess.run(["brew", "search", query], capture_output=True, text=True, timeout=10)
                return r.stdout.strip().splitlines()[:5]
            elif self.mgr == "apk":
                r = subprocess.run(["apk", "search", query], capture_output=True, text=True, timeout=10)
                return [l for l in r.stdout.splitlines() if query.lower() in l.lower()][:5]
        except Exception:
            pass
        return []

    def system_install(self, sudo: str, pkg: str) -> bool:
        """跨平台系统包安装"""
        mapped = self.map_pkg(pkg)
        if not mapped:
            warn(f"{pkg} 在 {self.mgr} 上无需额外安装")
            return True
        try:
            if self.mgr == "apt":
                return subprocess.run(f"{sudo}apt install -y {mapped}", shell=True, capture_output=True).returncode == 0
            elif self.mgr in ("dnf", "yum"):
                return subprocess.run(f"{sudo}{self.mgr} install -y {mapped}", shell=True, capture_output=True).returncode == 0
            elif self.mgr == "pacman":
                return subprocess.run(f"{sudo}pacman -S --noconfirm {mapped}", shell=True, capture_output=True).returncode == 0
            elif self.mgr == "brew":
                return subprocess.run(["brew", "install", mapped], capture_output=True).returncode == 0
            elif self.mgr == "apk":
                return subprocess.run(f"{sudo}apk add {mapped}", shell=True, capture_output=True).returncode == 0
            elif self.mgr == "zypper":
                return subprocess.run(f"{sudo}zypper install -y {mapped}", shell=True, capture_output=True).returncode == 0
        except Exception as e:
            print(f"  {C.R}安装出错: {e}{C.NC}")
        return False

    def wait_for_apt_lock(self, max_wait: int = 60) -> bool:
        """等待 apt 锁释放（不删除锁文件）"""
        if self.mgr != "apt":
            return True
        waited = 0
        lock_files = ["/var/lib/dpkg/lock-frontend", "/var/lib/dpkg/lock", "/var/lib/apt/lists/lock"]
        while waited < max_wait:
            locked = False
            for lf in lock_files:
                try:
                    r = subprocess.run(["fuser", lf], capture_output=True, text=True)
                    if r.returncode == 0:
                        locked = True
                        break
                except FileNotFoundError:
                    # fuser 不可用，跳过锁检查
                    return True
            if not locked:
                return True
            dim(f"⏳ 等待 apt 锁释放... ({waited}s/{max_wait}s)")
            time.sleep(3)
            waited += 3
        err(f"apt 锁等待超时 ({max_wait}s)")
        return False


# ═══════════════════════════════════════════════════════
# 安全安装
# ═══════════════════════════════════════════════════════
class Security:
    @staticmethod
    def safe_pip_install(sudo: str, pkg: str, platform: Platform) -> tuple[bool, str]:
        """
        安全 pip 安装: pipx → venv → --break-system-packages
        返回 (成功与否, 使用的方法)
        """
        mirror = ""
        if not _can_reach_google():
            mirror = "-i https://pypi.tuna.tsinghua.edu.cn/simple"

        # 方案 1: pipx (隔离安装)
        if shutil.which("pipx"):
            note("  → 使用 pipx (隔离安装)")
            r = subprocess.run(f"pipx install {pkg}", shell=True, capture_output=True, text=True)
            if r.returncode == 0:
                return True, "pipx"
            warn("pipx 安装失败，尝试下一种方式")
            if r.stderr:
                dim(f"  pipx 错误: {r.stderr.strip()[:200]}")

        # 方案 2: 用户级 venv
        venv_dir = Path.home() / ".local" / "share" / "auto-installer" / "venv"
        if not venv_dir.exists():
            subprocess.run([sys.executable, "-m", "venv", str(venv_dir)], capture_output=True)
        if venv_dir.exists():
            note("  → 使用用户级 venv")
            pip = str(venv_dir / "bin" / "pip")
            r = subprocess.run(f"{pip} install {mirror} {pkg}", shell=True, capture_output=True, text=True)
            if r.returncode == 0:
                # 为已安装的包创建 wrapper（仅对有 CLI 入口的包）
                bin_dir = Path.home() / ".local" / "bin"
                bin_dir.mkdir(parents=True, exist_ok=True)
                venv_bin = venv_dir / "bin"
                for p in pkg.split():
                    cmd_name = re.split(r'[<>=!]', p)[0]
                    # 检查 venv/bin 里是否真的有这个命令
                    venv_cmd = venv_bin / cmd_name
                    if venv_cmd.exists():
                        wrapper = bin_dir / cmd_name
                        wrapper.write_text(f'#!/bin/bash\nexec "{venv_cmd}" "$@"\n')
                        wrapper.chmod(0o755)
                local_bin = str(bin_dir)
                if local_bin not in os.environ.get("PATH", ""):
                    warn(f"请将 {local_bin} 加入 PATH: export PATH=\"$HOME/.local/bin:$PATH\"")
                return True, "venv"

        # 方案 3: --break-system-packages (最后手段)
        warn("pipx/venv 均不可用")
        warn("将使用 --break-system-packages (会修改系统 Python 环境)")
        r = subprocess.run(f"pip3 install --break-system-packages {mirror} {pkg}", shell=True, capture_output=True, text=True)
        if r.returncode == 0:
            return True, "pip-system"
        if r.stderr:
            dim(f"  pip 错误: {r.stderr.strip()[:200]}")
        return False, "failed"

    @staticmethod
    def safe_apt_install(sudo: str, pkg: str, platform: Platform) -> tuple[bool, str]:
        """安全 apt 安装（等待锁而非删除锁）"""
        if platform.mgr != "apt":
            return platform.system_install(sudo, pkg), platform.mgr

        if not platform.wait_for_apt_lock(60):
            return False, "apt-lock-timeout"

        r = subprocess.run(f"{sudo}apt install -y {pkg}", shell=True, capture_output=True, text=True)
        if r.returncode == 0:
            return True, "apt"
        # 输出实际错误信息
        if r.stderr:
            dim(f"  apt 错误: {r.stderr.strip()[:300]}")
        return False, "apt"

    @staticmethod
    def safe_remote_script(url: str, interactive: bool = False) -> bool:
        """安全远程脚本执行: 下载 → 预览 → 确认"""
        warn(f"检测到远程脚本安装请求")
        note(f"📥 下载脚本到临时文件（请审查后执行）: {url}")

        try:
            req = Request(url, headers={"User-Agent": "auto-installer/3.0"})
            with urlopen(req, timeout=15) as resp:
                content = resp.read().decode("utf-8", errors="replace")
        except Exception as e:
            err(f"下载失败: {e}")
            return False

        lines = content.splitlines()
        print(f"  {C.CY}─── 脚本内容预览 (前 20 行) ───{C.NC}")
        for line in lines[:20]:
            print(f"  │ {line}")
        if len(lines) > 20:
            dim(f"  │ ... (共 {len(lines)} 行)")
        print(f"  {C.CY}──────────────────────────────{C.NC}")

        if interactive:
            confirm = input("  执行此脚本? [y/N] ").strip().lower()
            if confirm == "y":
                return subprocess.run(["bash", "-c", content]).returncode == 0
            dim("已取消")
            return False
        else:
            # 非交互：保存到临时文件
            tf = tempfile.NamedTemporaryFile(mode="w", suffix=".sh", prefix="ai-remote-", delete=False)
            tf.write(content)
            tf.close()
            Path(tf.name).chmod(0o644)
            warn("非交互模式，未自动执行")
            note(f"📄 脚本已保存到: {tf.name}")
            note(f"请手动审查后执行: bash {tf.name}")
            return False


def _can_reach_google() -> bool:
    try:
        urlopen("https://www.google.com", timeout=3)
        return True
    except Exception:
        return False


# ═══════════════════════════════════════════════════════
# 智能推理
# ═══════════════════════════════════════════════════════
class Inference:
    # 命令别名 → 系统包
    CMD_ALIASES = {
        "rg": "ripgrep", "fd": "fd-find", "bat": "bat", "batcat": "bat",
        "ag": "silversearcher", "pip": "python3-pip", "python": "python3",
        "node": "nodejs", "nc": "netcat", "cc": "build-essential",
        "g++": "build-essential", "gcc": "build-essential",
        "make": "build-essential", "pygmentize": "python3-pygments",
        "convert": "imagemagick", "identify": "imagemagick", "mogrify": "imagemagick",
        "dot": "graphviz", "mysql": "mysql-client", "psql": "postgresql-client",
        "redis-cli": "redis-tools", "tshark": "tshark",
        "cwebp": "webp", "dwebp": "webp", "tesseract": "tesseract-ocr",
        "git-delta": "delta", "mlr": "miller",
        "fzf": "fzf", "zoxide": "zoxide", "btop": "btop", "htop": "htop",
        "ncdu": "ncdu", "jq": "jq", "yq": "yq", "lazygit": "lazygit",
        "lazydocker": "lazydocker", "docker-compose": "docker-compose",
    }

    # Python 包 → 系统包
    PYTHON_TO_SYSTEM = {
        "cv2": "python3-opencv", "PIL": "python3-pil", "yaml": "python3-yaml",
        "gi": "python3-gi", "dbus": "python3-dbus", "apt": "python3-apt",
        "lxml": "python3-lxml", "numpy": "numpy", "pandas": "pandas",
        "scipy": "scipy", "sklearn": "scikit-learn", "matplotlib": "matplotlib",
        "requests": "requests", "bs4": "beautifulsoup4", "feedparser": "feedparser",
    }

    @dataclass
    class Result:
        tool: str
        cmd: str
        chain: str
        kind: str  # command / command_alias / python / node / library / builtin / diagnostic

    def infer(self, input_text: str) -> Optional['Inference.Result']:
        # command not found: xxx  OR  bash: xxx: command not found
        m = re.search(r'command\s+not\s+found:?\s+(\S+)', input_text)
        if not m:
            m = re.search(r'(\w+):\s+command not found', input_text)
        if m:
            tool = m.group(1)
            if tool in self.CMD_ALIASES:
                mapped = self.CMD_ALIASES[tool]
                return self.Result(tool=mapped, cmd=tool, chain=f"apt {mapped}", kind="command_alias")
            return self.Result(tool=tool, cmd=tool, chain=f"apt {tool}", kind="command")

        # ModuleNotFoundError / No module named
        m = re.search(r"(?:ModuleNotFoundError|No module named)\s*['\"]?(\w+)['\"]?", input_text)
        if m:
            tool = m.group(1)
            if tool in self.PYTHON_TO_SYSTEM:
                sys_pkg = self.PYTHON_TO_SYSTEM[tool]
                return self.Result(tool=sys_pkg, cmd=tool, chain=f"apt {sys_pkg}", kind="python_system")
            return self.Result(tool=tool, cmd=tool, chain=f"pip {tool}", kind="python")

        # Cannot find module 'xxx' (Node)
        m = re.search(r"Cannot\s+find\s+module\s+['\"]([^'\"]+)['\"]", input_text)
        if m:
            tool = m.group(1)
            return self.Result(tool=tool, cmd=tool, chain=f"npm install -g {tool}", kind="node")

        # ImportError
        m = re.search(r"ImportError:\s*(\w+)", input_text)
        if m:
            tool = m.group(1)
            # libGL 特殊处理
            if "libGL" in tool or "libGL" in input_text:
                return self.Result(tool="libgl1", cmd="libgl1", chain="apt libgl1-mesa-glx", kind="library")
            if tool in self.PYTHON_TO_SYSTEM:
                sys_pkg = self.PYTHON_TO_SYSTEM[tool]
                return self.Result(tool=sys_pkg, cmd=tool, chain=f"apt {sys_pkg}", kind="python_system")
            return self.Result(tool=tool, cmd=tool, chain=f"pip {tool}", kind="python")

        # shared library
        m = re.search(r'lib(\w[\w.-]*?)\.so', input_text)
        if "loading" in input_text and "shared" in input_text and m:
            lib = m.group(1)
            tool = f"lib{lib}-dev"
            return self.Result(tool=tool, cmd=tool, chain=f"apt {tool}", kind="library")

        # Permission denied
        if re.search(r'Permission\s+denied', input_text):
            return self.Result(tool="chmod", cmd="chmod", chain="", kind="builtin")

        # No space left
        if re.search(r'No\s+space\s+left', input_text):
            return self.Result(tool="ncdu", cmd="ncdu", chain="apt ncdu", kind="diagnostic")

        # SSL certificate
        if re.search(r'SSL\s+certificate', input_text):
            return self.Result(tool="ca-certificates", cmd="update-ca-certificates", chain="apt ca-certificates", kind="library")

        # dpkg lock
        if "dpkg" in input_text and "lock" in input_text:
            return self.Result(tool="dpkg", cmd="dpkg", chain="", kind="builtin")

        # cargo not found
        if "cargo" in input_text and not shutil.which("cargo"):
            return self.Result(tool="cargo", cmd="cargo", chain="apt rustc cargo", kind="dev")

        return None


# ═══════════════════════════════════════════════════════
# 学习 / 历史 / 统计管理
# ═══════════════════════════════════════════════════════
class LearningManager:
    def __init__(self, cfg: Config):
        self.cfg = cfg
        self._ensure_dirs()

    def _ensure_dirs(self):
        self.cfg.learn_log.parent.mkdir(parents=True, exist_ok=True)
        self.cfg.history_file.parent.mkdir(parents=True, exist_ok=True)

    def log_history(self, query: str, cmd: str, method: str, success: bool, time_ms: int = 0):
        entry = {
            "ts": datetime.now().isoformat(),
            "query": query, "cmd": cmd, "method": method,
            "success": success, "time_ms": time_ms
        }
        with open(self.cfg.history_file, "a") as f:
            f.write(json.dumps(entry, ensure_ascii=False) + "\n")

    def increment_stat(self, tool: str):
        stats = {}
        if self.cfg.stats_file.exists():
            try:
                stats = json.loads(self.cfg.stats_file.read_text())
            except Exception:
                pass
        stats[tool] = stats.get(tool, 0) + 1
        self.cfg.stats_file.write_text(json.dumps(stats, indent=2, ensure_ascii=False))

    def is_recently_failed(self, tool: str, method: str, pkg: str) -> bool:
        if not self.cfg.fail_log.exists():
            return False
        # 格式: [timestamp] tool | method pkg | reason
        marker = f"{tool} | {method} {pkg}"
        try:
            for line in self.cfg.fail_log.read_text().splitlines():
                if marker in line:
                    # 检查是否 24h 内
                    m = re.match(r'\[(\d{4}-\d{2}-\d{2} \d{2}:\d{2}:\d{2})\]', line)
                    if m:
                        ts = datetime.strptime(m.group(1), "%Y-%m-%d %H:%M:%S")
                        if datetime.now() - ts < timedelta(hours=24):
                            return True
        except Exception:
            pass
        return False

    def record_success(self, tool: str, desc: str, chain: str, query: str = ""):
        if not tool:
            return
        # 去重
        if self.cfg.map_file.exists():
            content = self.cfg.map_file.read_text()
            if f"| `{tool}`" in content:
                return
        if self.cfg.learn_log.exists():
            if tool in self.cfg.learn_log.read_text():
                return

        with open(self.cfg.learn_log, "a") as f:
            f.write(f"[{datetime.now().strftime('%Y-%m-%d %H:%M:%S')}] {tool} | 已学习 | {chain} | {desc}\n")
        info(f"📝 已记录成功: {tool}")
        self._auto_writeback(tool, desc, chain)
        self.increment_stat(tool)

    def _auto_writeback(self, tool: str, desc: str, chain: str):
        if not self.cfg.map_file.exists():
            return
        content = self.cfg.map_file.read_text()
        if f"| `{tool}`" in content:
            return

        if "🔧 自动发现的工具" not in content:
            addition = f"\n## 🔧 自动发现的工具\n\n| 任务 | 工具 | 安装降级链 |\n|------|------|-----------|\n"
            content += addition

        content += f"| {desc} | `{tool}` | `{chain}` |\n"
        self.cfg.map_file.write_text(content)
        info(f"📄 已回写映射表: {tool}")

    def record_failure(self, tool: str, method: str, pkg: str, reason: str = "安装失败"):
        self.cfg.fail_log.parent.mkdir(parents=True, exist_ok=True)
        with open(self.cfg.fail_log, "a") as f:
            f.write(f"[{datetime.now().strftime('%Y-%m-%d %H:%M:%S')}] {tool} | {method} {pkg} | {reason}\n")
        dim(f"📝 已记录失败: {method} {pkg} — {reason}")


# ═══════════════════════════════════════════════════════
# 映射表解析
# ═══════════════════════════════════════════════════════
class MapParser:
    def __init__(self, map_file: Path):
        self.map_file = map_file

    def search(self, query: str) -> Optional[tuple[str, str]]:
        """
        搜索映射表，返回 (cmd_name, chain) 或 None
        """
        if not self.map_file.exists():
            return None
        content = self.map_file.read_text()
        query_lower = query.lower()

        # 精确匹配工具名: | `query`
        for line in content.splitlines():
            if line.startswith("|") and f"| `{query}`" in line.lower():
                return self._parse_line(line)

        # 中文描述匹配
        for line in content.splitlines():
            if line.startswith("|") and query_lower in line.lower():
                if not line.startswith("| 任务") and "---" not in line and "能力" not in line:
                    result = self._parse_line(line)
                    if result:
                        return result

        # 去除常见前缀再搜
        for prefix in ["lib", "python3-", "golang-"]:
            for suffix in ["-dev", "-tools", "-utils"]:
                if query.startswith(prefix) or query.endswith(suffix):
                    stripped = query
                    if stripped.startswith(prefix):
                        stripped = stripped[len(prefix):]
                    if stripped.endswith(suffix):
                        stripped = stripped[:-len(suffix)]
                    if stripped != query:
                        for line in content.splitlines():
                            if line.startswith("|") and f"| `{stripped}`" in line.lower():
                                return self._parse_line(line)

        return None

    def _parse_line(self, line: str) -> Optional[tuple[str, str]]:
        parts = [p.strip().strip('`') for p in line.split("|")]
        if len(parts) >= 5:
            cmd = parts[2].strip()
            chain = parts[3].strip()
            if cmd and chain:
                return (cmd, chain)
        return None


# ═══════════════════════════════════════════════════════
# GitHub 下载
# ═══════════════════════════════════════════════════════
class GitHubDownloader:
    PROXIES = [
        "https://ghfast.top", "https://gh.llkk.cc", "https://gh-proxy.com",
        "https://gh.monlor.com", "https://gh.xxooo.cf", "https://gh.jasonzeng.dev",
        "https://gh.dpik.top",
    ]
    _cached_proxy: Optional[str] = None

    @classmethod
    def _find_fastest_proxy(cls) -> Optional[str]:
        if cls._cached_proxy is not None:
            return cls._cached_proxy or None
        test_path = "/https://raw.githubusercontent.com/cli/cli/master/README.md"
        best = None
        best_ms = 999999
        for proxy in cls.PROXIES:
            try:
                start = time.time()
                req = Request(f"{proxy}{test_path}", headers={"User-Agent": "auto-installer/3.0"})
                resp = urlopen(req, timeout=8)
                elapsed = int((time.time() - start) * 1000)
                if resp.status == 200 and elapsed < best_ms:
                    best_ms = elapsed
                    best = proxy
            except Exception:
                continue
        cls._cached_proxy = best or ""
        return best

    @classmethod
    def mirror_url(cls, url: str) -> str:
        if not _can_reach_google():
            p = cls._find_fastest_proxy()
            if p:
                return f"{p}/{url}"
        return url

    @classmethod
    def download_release(cls, repo_path: str, cmd_name: str) -> bool:
        """下载 GitHub Release 二进制并安装"""
        arch = os.uname().machine
        os_name = os.uname().sysname.lower()
        suffix = {"x86_64": "amd64", "aarch64": "arm64", "arm64": "arm64"}.get(arch, arch)

        note(f"🔍 查询 Release: {repo_path}")
        try:
            url = f"https://api.github.com/repos/{repo_path}/releases/latest"
            req = Request(url, headers={"User-Agent": "auto-installer/3.0"})
            with urlopen(req, timeout=10) as resp:
                rdata = json.loads(resp.read())
        except Exception:
            warn("无 Release 信息")
            return False

        assets = rdata.get("assets", [])
        asset_url = None
        for a in assets:
            dl = a.get("browser_download_url", "")
            if os_name in dl.lower() and suffix in dl.lower():
                asset_url = dl
                break
        if not asset_url:
            for a in assets:
                dl = a.get("browser_download_url", "")
                if "linux" in dl.lower():
                    asset_url = dl
                    break

        if not asset_url:
            warn(f"未找到 {os_name}/{suffix} 的二进制")
            return False

        mirror = cls.mirror_url(asset_url)
        filename = os.path.basename(asset_url)
        tmpfile = f"/tmp/{filename}"
        note(f"⬇️  下载: {mirror}")

        try:
            req = Request(mirror, headers={"User-Agent": "auto-installer/3.0"})
            with urlopen(req, timeout=120) as resp:
                Path(tmpfile).write_bytes(resp.read())
        except Exception as e:
            warn(f"下载失败: {e}")
            return False

        info(f"✓ 下载完成: {tmpfile}")

        # 解压
        tmpdir = tempfile.mkdtemp(prefix="ai-extract-")
        try:
            if filename.endswith((".tar.gz", ".tgz")):
                subprocess.run(["tar", "-xzf", tmpfile, "-C", tmpdir], capture_output=True)
            elif filename.endswith(".zip"):
                subprocess.run(["unzip", "-o", tmpfile, "-d", tmpdir], capture_output=True)
            elif filename.endswith(".deb"):
                r = subprocess.run(["dpkg", "-i", tmpfile], capture_output=True, text=True)
                if r.returncode == 0:
                    return True
            else:
                shutil.copy2(tmpfile, tmpdir)

            # 找可执行文件
            for root, dirs, files in os.walk(tmpdir):
                for f in files:
                    if f == cmd_name or f.startswith(cmd_name):
                        src = os.path.join(root, f)
                        dst = f"/usr/local/bin/{cmd_name}"
                        try:
                            shutil.copy2(src, dst)
                            os.chmod(dst, 0o755)
                            return True
                        except PermissionError:
                            subprocess.run(["sudo", "cp", src, dst], capture_output=True)
                            subprocess.run(["sudo", "chmod", "755", dst], capture_output=True)
                            return True
        finally:
            shutil.rmtree(tmpdir, ignore_errors=True)

        warn("下载成功但未找到可执行文件，请手动安装")
        note(f"文件: {tmpfile}")
        return False


# ═══════════════════════════════════════════════════════
# 安装器
# ═══════════════════════════════════════════════════════
class Installer:
    def __init__(self, platform: Platform, learning: LearningManager):
        self.platform = platform
        self.learn = learning

    def _get_sudo(self) -> str:
        if os.getuid() == 0:
            return ""
        if shutil.which("sudo"):
            r = subprocess.run(["sudo", "-n", "true"], capture_output=True)
            if r.returncode == 0:
                return "sudo "
        warn("需要 sudo 权限")
        return ""

    def verify_cmd(self, cmd: str) -> bool:
        """验证命令可用"""
        # 解析 tool (alias) 格式
        names = []
        m = re.match(r'^(\S+)\s*\((\S+)\)$', cmd)
        if m:
            names = [m.group(2), m.group(1)]
        elif "/" in cmd:
            parts = cmd.split("/")
            names = parts[:2]
        else:
            names = [cmd]

        for n in names:
            if shutil.which(n):
                try:
                    ver = subprocess.run([n, "--version"], capture_output=True, text=True, timeout=5)
                    ver_str = ver.stdout.strip().split("\n")[0] if ver.stdout else "installed"
                except Exception:
                    ver_str = "installed"
                info(f"✅ 安装成功: {n} — {ver_str}")
                return True

        # 系统包兜底
        if self.platform.is_installed(cmd):
            info(f"✅ 安装成功: {cmd} ({self.platform.mgr} 确认)")
            return True

        err(f"验证失败: {cmd} 不存在")
        return False

    def install_from_chain(self, chain: str, cmd_name: str, query: str = "") -> bool:
        """执行降级链安装"""
        sudo = self._get_sudo()
        print(f"\n{C.BD}{C.CY}🔧 安装降级链: {chain}{C.NC}\n")

        # 已安装检查
        if self.platform.is_installed(cmd_name):
            try:
                ver = subprocess.run([cmd_name, "--version"], capture_output=True, text=True, timeout=5)
                ver_str = ver.stdout.strip().split("\n")[0] if ver.stdout else "already installed"
            except Exception:
                ver_str = "already installed"
            info(f"✅ 已安装: {cmd_name} — {ver_str}")
            self.learn.log_history(query, cmd_name, "already", True, 0)
            return True

        steps = [s.strip().strip('`') for s in chain.split("→")]
        tried_any = False
        install_start = time.time()

        for step in steps:
            if not step:
                continue
            parts = step.split(None, 1)
            method = parts[0] if parts else ""
            pkg = parts[1] if len(parts) > 1 else ""
            if not pkg:
                continue

            # 检查近期失败
            if self.learn.is_recently_failed(cmd_name, method, pkg):
                print(f"  {C.B}跳过: {method} {pkg} {C.DM}(近期失败，24h 内不再重试){C.NC}")
                continue

            tried_any = True
            print(f"  {C.B}尝试: {method} {pkg}...{C.NC}")
            step_start = time.time()
            success = False

            if method == "apt":
                if self.platform.mgr == "apt":
                    ok, used = Security.safe_apt_install(sudo, pkg, self.platform)
                    success = ok
                else:
                    success = self.platform.system_install(sudo, pkg)
                if not success:
                    self.learn.record_failure(cmd_name, self.platform.mgr, pkg, "系统包安装失败")

            elif method == "snap":
                r = subprocess.run(f"snap install {pkg}", shell=True, capture_output=True, text=True)
                success = r.returncode == 0
                if not success:
                    self.learn.record_failure(cmd_name, "snap", pkg, "snap install 失败")
                    if r.stderr:
                        dim(f"  snap 错误: {r.stderr.strip()[:200]}")

            elif method == "pip":
                ok, used = Security.safe_pip_install(sudo, pkg, self.platform)
                success = ok
                if not success:
                    self.learn.record_failure(cmd_name, "pip", pkg, "pip install 失败")

            elif method == "npm":
                r = subprocess.run(f"npm install -g {pkg}", shell=True, capture_output=True, text=True)
                success = r.returncode == 0
                if not success:
                    self.learn.record_failure(cmd_name, "npm", pkg, "npm install 失败")
                    if r.stderr:
                        dim(f"  npm 错误: {r.stderr.strip()[:200]}")

            elif method in ("dl", "download"):
                success = GitHubDownloader.download_release(pkg, cmd_name)
                if not success:
                    self.learn.record_failure(cmd_name, "dl", pkg, "下载安装失败")

            elif method in ("src", "source"):
                success = self._try_source_build(pkg, cmd_name, sudo)
                if not success:
                    self.learn.record_failure(cmd_name, "src", pkg, "源码编译失败")

            elif method == "go":
                if shutil.which("go"):
                    r = subprocess.run(f"go install {pkg}@latest", shell=True, capture_output=True, text=True)
                    success = r.returncode == 0
                    if success:
                        info("✓ go install 成功")
                if not success:
                    self.learn.record_failure(cmd_name, "go", pkg, "go install 失败")

            elif method == "pipx":
                if shutil.which("pipx"):
                    r = subprocess.run(f"pipx install {pkg}", shell=True, capture_output=True, text=True)
                    success = r.returncode == 0
                if not success:
                    self.learn.record_failure(cmd_name, "pipx", pkg, "pipx install 失败")

            elif method == "curl":
                warn("跳过自动 curl 安装 (安全策略)")
                note("请手动执行: curl -fsSL <url> | bash")
                self.learn.record_failure(cmd_name, "curl", pkg, "已跳过 (安全策略)")

            else:
                warn(f"未知方式: {method}")

            # 验证
            if success:
                elapsed_ms = int((time.time() - step_start) * 1000)
                if self.verify_cmd(cmd_name):
                    self.learn.record_success(cmd_name, "自动学习", f"{method} {pkg}", query)
                    self.learn.log_history(query, cmd_name, method, True, elapsed_ms)
                    return True

        # 全部失败
        elapsed_ms = int((time.time() - install_start) * 1000)
        self.learn.log_history(query, cmd_name, "chain_failed", False, elapsed_ms)

        if not tried_any:
            warn("所有步骤均被跳过（近期均失败过）")
            dim("等待 24h 后重试，或用 --failures 查看详情")
        else:
            err("所有安装方式均失败")
        return False

    def _try_source_build(self, repo: str, cmd_name: str, sudo: str) -> bool:
        """源码编译安装"""
        if repo.startswith("github.com/"):
            repo = repo[len("github.com/"):]
        elif "github.com/" in repo:
            m = re.search(r'github\.com/([^/]+/[^/]+)', repo)
            if m:
                repo = m.group(1)

        if not repo:
            warn("无仓库信息，无法编译")
            return False

        # 检查编译工具
        for tool in ["make", "cargo", "go"]:
            if shutil.which(tool):
                break
        else:
            note("⚠ 缺少编译工具，尝试安装 build-essential")
            self.platform.system_install(sudo, "build-essential")

        src_url = GitHubDownloader.mirror_url(f"https://github.com/{repo}.git")
        note(f"📥 克隆: {src_url}")
        tmpdir = tempfile.mkdtemp(prefix=f"ai-build-{cmd_name}-")

        try:
            r = subprocess.run(["git", "clone", "--depth", "1", src_url, tmpdir], capture_output=True, text=True)
            if r.returncode != 0:
                warn("克隆失败")
                return False

            build_dir = Path(tmpdir)
            if (build_dir / "Makefile").exists():
                r = subprocess.run("make -j$(nproc)", shell=True, cwd=tmpdir, capture_output=True, text=True)
                if r.returncode == 0:
                    subprocess.run(f"{sudo}make install", shell=True, cwd=tmpdir, capture_output=True)
                    return self.verify_cmd(cmd_name)
            elif (build_dir / "Cargo.toml").exists() and shutil.which("cargo"):
                r = subprocess.run("cargo build --release", shell=True, cwd=tmpdir, capture_output=True, text=True)
                if r.returncode == 0:
                    src = f"{tmpdir}/target/release/{cmd_name}"
                    if os.path.exists(src):
                        subprocess.run(f"{sudo}cp {src} /usr/local/bin/", shell=True, capture_output=True)
                        return self.verify_cmd(cmd_name)
        finally:
            shutil.rmtree(tmpdir, ignore_errors=True)

        warn("编译失败")
        return False


# ═══════════════════════════════════════════════════════
# 搜索引擎（6 层）
# ═══════════════════════════════════════════════════════
class SearchEngine:
    def __init__(self, cfg: Config, platform: Platform, learning: LearningManager):
        self.cfg = cfg
        self.platform = platform
        self.learn = learning
        self.mapper = MapParser(cfg.map_file)
        self.infer = Inference()
        self.installer = Installer(platform, learning)

    def search(self, query: str, do_install: bool = False) -> int:
        """6 层搜索，返回退出码"""
        found_chain = None
        found_cmd = None

        print(f"\n{C.BD}{C.CY}╔══════════════════════════════════════════════════════════════╗{C.NC}")
        print(f"{C.BD}{C.CY}║  🦞 Auto-Installer v3.0 (Python) · 6层搜索 + 跨平台        ║{C.NC}")
        print(f"{C.BD}{C.CY}╚══════════════════════════════════════════════════════════════╝{C.NC}")
        print(f"  {C.Y}关键词: {C.BD}{query}{C.NC}")
        print(f"  {C.DM}系统: {self.platform.mgr} ({self.platform.os_id}){C.NC}")
        mode_str = "搜索 + 自动安装" if do_install else "仅搜索"
        print(f"  {C.G if do_install else C.CY}模式: {mode_str}{C.NC}")
        if not _can_reach_google():
            print(f"  {C.Y}网络: 国内环境，镜像加速{C.NC}")
        self.learn.increment_stat("_searches")
        print()

        # 第 1 层: 映射表
        print(f"{C.G}{C.BD}━━━ 第 1 层: 固定映射表 ━━━{C.NC}")
        result = self.mapper.search(query)
        if result:
            found_cmd, found_chain = result
            print(f"  {result}")
            info(f"✓ 命中！降级链: {found_chain}")
        else:
            dim("○ 未命中")

        # 第 2 层: 智能推理
        print(f"\n{C.B}{C.BD}━━━ 第 2 层: 智能推理 ━━━{C.NC}")
        inf = self.infer.infer(query)
        if inf:
            info(f"✓ 推断: {C.BD}{inf.tool}{C.NC} ({inf.kind}) → {inf.chain}")
            # 别名匹配映射表
            if not found_chain:
                alias_result = self.mapper.search(inf.tool)
                if alias_result:
                    found_cmd, found_chain = alias_result
                    info(f"  ✓ 别名→映射表: {found_cmd} → {found_chain}")
            if not found_chain:
                found_chain = inf.chain
                found_cmd = inf.tool
        else:
            dim("○ 非报错格式")

        # 第 3 层: 系统包
        print(f"\n{C.B}{C.BD}━━━ 第 3 层: 系统包 ({self.platform.mgr}) ━━━{C.NC}")
        sys_results = self.platform.search(query)
        if sys_results:
            for r in sys_results:
                print(f"  {r}")
        else:
            dim(f"○ {self.platform.mgr} 未找到")

        # 第 4 层: pip/npm
        print(f"\n{C.B}{C.BD}━━━ 第 4 层: Python / Node 包 ━━━{C.NC}")
        pip_found = False
        npm_found = False
        if shutil.which("pip3"):
            try:
                r = subprocess.run(["pip3", "index", "versions", query], capture_output=True, text=True, timeout=10)
                if r.stdout.strip():
                    print(f"  pip: {r.stdout.strip().splitlines()[0]}")
                    pip_found = True
            except Exception:
                pass
        if shutil.which("npm"):
            try:
                r = subprocess.run(["npm", "search", query], capture_output=True, text=True, timeout=10)
                if r.stdout.strip() and "No matches" not in r.stdout:
                    print(f"  npm: {r.stdout.strip().splitlines()[0]}")
                    npm_found = True
            except Exception:
                pass
        if not pip_found and not npm_found:
            dim("○ pip/npm 未找到")

        # 第 5 层: ClawHub
        print(f"\n{C.B}{C.BD}━━━ 第 5 层: ClawHub 技能 ━━━{C.NC}")
        if shutil.which("npx"):
            try:
                r = subprocess.run(["npx", "clawhub", "search", query], capture_output=True, text=True, timeout=15)
                if r.stdout.strip():
                    print(r.stdout.strip())
                else:
                    dim("○ ClawHub 未找到")
            except Exception:
                dim("○ ClawHub 搜索超时")
        else:
            dim("○ npx 不可用")

        # 第 6 层: 学习记录
        print(f"\n{C.B}{C.BD}━━━ 第 6 层: 学习记录 ━━━{C.NC}")
        if self.cfg.learn_log.exists():
            hits = [l for l in self.cfg.learn_log.read_text().splitlines() if query.lower() in l.lower()][:3]
            if hits:
                for h in hits:
                    print(f"  {h}")
                info("✓ 匹配学习记录")
                if not found_chain:
                    parts = [p.strip() for p in hits[0].split("|")]
                    if len(parts) >= 4:
                        found_chain = parts[3].strip()
                        found_cmd = parts[1].strip()
                        info(f"  降级链: {found_chain}")
            else:
                dim("○ 未找到")
        else:
            dim("○ 暂无记录")

        # 汇总
        print()
        print(f"{C.BD}{C.CY}╔══════════════════════════════════════════════════════════════╗{C.NC}")

        if found_chain and found_cmd:
            print(f"{C.BD}{C.CY}║{C.NC}  {C.G}{C.BD}✅ 找到方案{C.NC}: {found_cmd} 降级链: {found_chain}")
            if do_install:
                print(f"{C.BD}{C.CY}║{C.NC}  {C.G}正在安装...{C.NC}")
                print(f"{C.BD}{C.CY}╚══════════════════════════════════════════════════════════════╝{C.NC}")
                if not self.installer.install_from_chain(found_chain, found_cmd, query):
                    return 1
            else:
                print(f"{C.BD}{C.CY}║{C.NC}  {C.CY}加 --install 自动安装{C.NC}")
                print(f"{C.BD}{C.CY}╚══════════════════════════════════════════════════════════════╝{C.NC}")
        elif sys_results or pip_found or npm_found:
            print(f"{C.BD}{C.CY}║{C.NC}  {C.Y}⚡ 中置信：包管理器有结果，建议分析后安装{C.NC}")
            print(f"{C.BD}{C.CY}╚══════════════════════════════════════════════════════════════╝{C.NC}")
        else:
            print(f"{C.BD}{C.CY}║{C.NC}  {C.R}{C.BD}❌ 6层全部未命中{C.NC}")
            print(f"{C.BD}{C.CY}║{C.NC}  {C.Y}→ agent 应调用 mimo_web_search 联网搜索{C.NC}")
            print(f"{C.BD}{C.CY}║{C.NC}  {C.DM}  退出码 10 表示需联网搜索{C.NC}")
            print(f"{C.BD}{C.CY}╚══════════════════════════════════════════════════════════════╝{C.NC}")
            return 10

        print()
        return 0

    def batch_install(self, tools: list[str]) -> int:
        """批量安装"""
        print(f"\n{C.BD}{C.CY}📦 批量安装: {' '.join(tools)}{C.NC}\n")
        total = len(tools)
        ok = fail = 0

        for i, tool in enumerate(tools, 1):
            print(f"{C.BD}── [{i}/{total}] {tool} ──{C.NC}")

            # 6 层搜索
            result = self.mapper.search(tool)
            chain = cmd = None
            if result:
                cmd, chain = result
            else:
                inf = self.infer.infer(tool)
                if inf:
                    chain = inf.chain
                    cmd = inf.tool
                    alias = self.mapper.search(inf.tool)
                    if alias:
                        cmd, chain = alias

            if not chain:
                # 系统包搜索
                sys_results = self.platform.search(tool)
                if sys_results:
                    pkg = sys_results[0].split("/")[0].split()[0]
                    chain = f"{self.platform.mgr} {pkg}"
                    cmd = pkg

            if not chain and shutil.which("pip3"):
                try:
                    r = subprocess.run(["pip3", "index", "versions", tool], capture_output=True, text=True, timeout=10)
                    if r.stdout.strip():
                        chain = f"pip {tool}"
                        cmd = tool
                except Exception:
                    pass

            if not chain and shutil.which("npm"):
                try:
                    r = subprocess.run(["npm", "search", tool], capture_output=True, text=True, timeout=10)
                    if r.stdout.strip() and "No matches" not in r.stdout:
                        chain = f"npm {tool}"
                        cmd = tool
                except Exception:
                    pass

            if chain and cmd:
                if self.installer.install_from_chain(chain, cmd, tool):
                    ok += 1
                else:
                    fail += 1
            else:
                err("6层全部未命中，跳过")
                self.learn.log_history(tool, tool, "not_found", False, 0)
                fail += 1
            print()

        print(f"{C.BD}{C.CY}📦 批量安装完成: {C.G}{ok} 成功{C.NC} / {C.R}{fail} 失败{C.NC} / {total} 总计{C.NC}")
        return 0 if fail == 0 else 1


# ═══════════════════════════════════════════════════════
# 其他命令
# ═══════════════════════════════════════════════════════
def cmd_learn(cfg: Config, platform: Platform, args: list[str]):
    if not args:
        err("用法: --learn <工具名> [描述]")
        sys.exit(1)
    tool = args[0]
    desc = args[1] if len(args) > 1 else "自动学习"
    lm = LearningManager(cfg)

    print(f"\n{C.BD}{C.CY}📝 自学习模式{C.NC}\n")
    chain = f"{platform.mgr} {tool}"
    if shutil.which(tool):
        info(f"✓ {tool} 已安装")
    skip_wb = len(args) <= 1
    lm.record_success(tool, desc, chain)


def cmd_history(cfg: Config):
    print(f"\n{C.BD}{C.CY}📝 学习历史{C.NC}\n")
    if not cfg.learn_log.exists():
        dim("○ 暂无记录")
        return
    lines = cfg.learn_log.read_text().splitlines()
    info(f"共学习 {len(lines)} 个工具:\n")
    for l in lines:
        print(f"  {l}")


def cmd_failures(cfg: Config):
    print(f"\n{C.BD}{C.CY}📝 失败记录{C.NC}\n")
    if not cfg.fail_log.exists():
        dim("○ 暂无失败记录")
        return
    lines = cfg.fail_log.read_text().splitlines()
    print(f"  {C.R}共 {len(lines)} 条失败记录:{C.NC}\n")
    for l in lines:
        print(f"  {l}")


def cmd_stats(cfg: Config):
    print(f"\n{C.BD}{C.CY}📊 安装统计{C.NC}\n")

    if cfg.stats_file.exists():
        try:
            stats = json.loads(cfg.stats_file.read_text())
            print(f"  {C.CY}🔑 使用次数:{C.NC}")
            for k, v in sorted(stats.items(), key=lambda x: -x[1]):
                if k != "_searches":
                    print(f"    {k}: {v} 次")
        except Exception:
            pass

    if cfg.history_file.exists():
        lines = cfg.history_file.read_text().strip().splitlines()
        total = len(lines)
        success = sum(1 for l in lines if '"success": true' in l)
        fail = total - success
        rate = (success * 100 // total) if total > 0 else 0
        print(f"\n  {C.CY}📦 安装历史: {total} 条{C.NC}")
        print(f"  {C.G}  ✅ 成功: {success}{C.NC}")
        print(f"  {C.R}  ❌ 失败: {fail}{C.NC}")
        print(f"  {C.CY}  📈 成功率: {rate}%{C.NC}")

    if cfg.learn_log.exists():
        lc = len(cfg.learn_log.read_text().strip().splitlines())
        print(f"\n  {C.CY}📝 已学习工具: {lc} 个{C.NC}")

    if cfg.map_file.exists():
        mc = cfg.map_file.read_text().count("\n| ")
        print(f"  {C.CY}🗺️  映射表条目: {mc} 个{C.NC}")
    print()


def cmd_scan(platform: Platform):
    print(f"\n{C.BD}{C.CY}🔍 扫描系统已安装工具{C.NC}")
    print(f"  {C.DM}系统: {platform.mgr} ({platform.os_id}){C.NC}\n")

    if platform.mgr == "apt" and shutil.which("dpkg"):
        r = subprocess.run(["dpkg", "-l"], capture_output=True, text=True)
        count = r.stdout.count("\nii ")
        print(f"  {C.CY}📦 dpkg: {count} 个包{C.NC}")
    elif platform.mgr in ("dnf", "yum"):
        r = subprocess.run([platform.mgr, "list", "installed"], capture_output=True, text=True)
        count = len(r.stdout.strip().splitlines()) - 1
        print(f"  {C.CY}📦 {platform.mgr}: {count} 个包{C.NC}")
    elif platform.mgr == "brew":
        r = subprocess.run(["brew", "list"], capture_output=True, text=True)
        count = len(r.stdout.split())
        print(f"  {C.CY}📦 brew: {count} 个包{C.NC}")

    if shutil.which("pip3"):
        r = subprocess.run(["pip3", "list", "--format=json"], capture_output=True, text=True)
        try:
            pkgs = json.loads(r.stdout)
            print(f"  {C.CY}🐍 pip3: {len(pkgs)} 个包{C.NC}")
        except Exception:
            pass

    if shutil.which("npm"):
        r = subprocess.run(["npm", "list", "-g", "--depth=0"], capture_output=True, text=True)
        count = r.stdout.count("──")
        print(f"  {C.CY}📦 npm: {count} 个全局包{C.NC}")

    if shutil.which("snap"):
        r = subprocess.run(["snap", "list"], capture_output=True, text=True)
        count = len(r.stdout.strip().splitlines()) - 1
        print(f"  {C.CY}📦 snap: {count} 个包{C.NC}")

    print(f"\n  {C.G}{C.BD}✅ 扫描完成{C.NC}\n")


def cmd_promote(cfg: Config):
    print(f"\n{C.BD}{C.CY}🔄 整理学习记录到映射表{C.NC}\n")
    if not cfg.learn_log.exists():
        dim("○ 无学习记录可整理")
        return

    promoted = skipped = 0
    content = cfg.map_file.read_text() if cfg.map_file.exists() else ""

    for line in cfg.learn_log.read_text().splitlines():
        parts = re.sub(r'^\[[^\]]*\]\s*', '', line).split("|")
        if len(parts) < 3:
            continue
        tool = parts[0].strip()
        chain = parts[2].strip()
        desc = parts[3].strip() if len(parts) > 3 else "自动发现的工具"
        if not tool:
            continue
        if f"| `{tool}`" in content:
            dim(f"跳过 {tool}（已存在）")
            skipped += 1
            continue
        if "🔧 自动发现的工具" not in content:
            content += "\n## 🔧 自动发现的工具\n\n| 任务 | 工具 | 安装降级链 |\n|------|------|-----------|\n"
        content += f"| {desc} | `{tool}` | `{chain}` |\n"
        info(f"✓ 已写入: {tool} → {chain}")
        promoted += 1

    cfg.map_file.write_text(content)
    print(f"\n  {C.G}{C.BD}整理完成: {promoted} 个已写入, {skipped} 个跳过{C.NC}")
    if promoted > 0:
        cfg.learn_log.write_text("")
        dim("学习记录已清空")


# ═══════════════════════════════════════════════════════
# 主入口
# ═══════════════════════════════════════════════════════
def main():
    cfg = Config()
    platform = Platform()
    learning = LearningManager(cfg)

    if len(sys.argv) < 2:
        print(f"{C.R}用法: python3 auto-installer.py <关键词> [--install]{C.NC}")
        print(f"{C.DM}      python3 auto-installer.py --install tool1 tool2 tool3{C.NC}")
        print(f"{C.DM}      python3 auto-installer.py --learn <工具名> [描述]{C.NC}")
        print(f"{C.DM}      python3 auto-installer.py --promote{C.NC}")
        print(f"{C.DM}      python3 auto-installer.py --history / --failures / --stats / --scan{C.NC}")
        print()
        dim(f"  系统: {platform.mgr} ({platform.os_id})")
        sys.exit(1)

    arg1 = sys.argv[1]

    if arg1 in ("--version", "-v"):
        print("auto-installer v3.0 (Python)")
        sys.exit(0)
    elif arg1 == "--learn":
        cmd_learn(cfg, platform, sys.argv[2:])
        sys.exit(0)
    elif arg1 == "--history":
        cmd_history(cfg)
        sys.exit(0)
    elif arg1 == "--failures":
        cmd_failures(cfg)
        sys.exit(0)
    elif arg1 == "--promote":
        cmd_promote(cfg)
        sys.exit(0)
    elif arg1 == "--scan":
        cmd_scan(platform)
        sys.exit(0)
    elif arg1 == "--stats":
        cmd_stats(cfg)
        sys.exit(0)
    elif arg1 == "--install":
        if len(sys.argv) < 3:
            err("--install 需要至少一个工具名")
            sys.exit(1)
        tools = sys.argv[2:]
        engine = SearchEngine(cfg, platform, learning)
        if len(tools) == 1:
            sys.exit(engine.search(tools[0], do_install=True))
        else:
            sys.exit(engine.batch_install(tools))
    else:
        # 搜索模式
        query = arg1
        do_install = "--install" in sys.argv
        engine = SearchEngine(cfg, platform, learning)
        sys.exit(engine.search(query, do_install=do_install))


if __name__ == "__main__":
    main()
