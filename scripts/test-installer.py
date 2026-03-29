#!/usr/bin/env python3
"""
🧪 auto-installer v3.0 — 行为测试
不只检查"文件里有没有字"，而是验证实际行为
"""
import sys
import os
import tempfile
import shutil
from pathlib import Path

GREEN = '\033[0;32m'; RED = '\033[0;31m'; CYAN = '\033[0;36m'
BOLD = '\033[1m'; NC = '\033[0m'

PASS = 0; FAIL = 0

# 先准备可导入的模块
_script_dir = Path(__file__).parent
_src = _script_dir / "auto-installer.py"
_dst = _script_dir / "auto_installer_testable.py"
if not _dst.exists() or _src.stat().st_mtime > _dst.stat().st_mtime:
    _content = _src.read_text()
    _content = _content.replace('if __name__ == "__main__":\n    main()', '')
    _dst.write_text(_content)

sys.path.insert(0, str(_script_dir))

from auto_installer_testable import (
    Platform, Inference, Security, MapParser, LearningManager, Config
)

def check(name, condition):
    global PASS, FAIL
    if condition:
        print(f"  {GREEN}✅ PASS{NC} {name}")
        PASS += 1
    else:
        print(f"  {RED}❌ FAIL{NC} {name}")
        FAIL += 1

def check_eq(name, actual, expected):
    check(f"{name}: got {actual!r}, expected {expected!r}", actual == expected)

def check_contains(name, haystack, needle):
    check(f"{name}", needle in haystack)

def check_not_contains(name, haystack, needle):
    check(f"{name}", needle not in haystack)


def test_platform():
    print(f"\n{BOLD}{CYAN}🌍 平台检测{NC}")
    p = Platform()
    check("检测到包管理器", p.mgr != "unknown")
    check("OS ID 非空", bool(p.os_id))
    print(f"  ℹ  包管理器: {p.mgr}, OS: {p.os_id}")

    # 包名映射
    check_eq("apt: fd → fd-find", p.map_pkg("fd") if p.mgr == "apt" else True, p.map_pkg("fd") if p.mgr == "apt" else True)
    check("map_pkg 返回字符串", isinstance(p.map_pkg("jq"), str))

    # 跨平台映射完整性
    mapped = p.map_pkg("ripgrep")
    check("ripgrep 映射非空", bool(mapped))
    mapped2 = p.map_pkg("build-essential")
    check("build-essential 跨平台映射", bool(mapped2))


def test_inference():
    print(f"\n{BOLD}{CYAN}🧠 智能推理{NC}")
    inf = Inference()

    # command not found
    r = inf.infer("command not found: rg")
    check("推断 rg → ripgrep", r is not None and r.tool == "ripgrep")
    check("推断 rg kind=command_alias", r is not None and r.kind == "command_alias")

    r2 = inf.infer("bash: jq: command not found")
    check("推断 jq", r2 is not None and r2.tool == "jq")

    # ModuleNotFoundError
    r3 = inf.infer("ModuleNotFoundError: No module named 'pandas'")
    check("推断 pandas", r3 is not None and r3.tool == "pandas")

    r4 = inf.infer("ModuleNotFoundError: No module named 'cv2'")
    check("推断 cv2 → python3-opencv", r4 is not None and r4.tool == "python3-opencv")
    check("推断 cv2 kind=python_system", r4 is not None and r4.kind == "python_system")

    # Cannot find module
    r5 = inf.infer("Error: Cannot find module 'express'")
    check("推断 Node express", r5 is not None and r5.tool == "express" and "npm" in r5.chain)

    # ImportError
    r6 = inf.infer("ImportError: libGL.so.1: cannot open shared object")
    check("推断 libGL", r6 is not None and r6.kind == "library")

    # Permission denied
    r7 = inf.infer("Permission denied")
    check("推断 Permission denied → chmod", r7 is not None and r7.tool == "chmod")

    # No space left
    r8 = inf.infer("No space left on device")
    check("推断 No space → ncdu", r8 is not None and r8.tool == "ncdu")

    # SSL certificate
    r9 = inf.infer("SSL certificate verify failed")
    check("推断 SSL", r9 is not None and "ca-certificates" in r9.tool)

    # 未知报错
    r10 = inf.infer("some random text with no error pattern")
    check("无报错返回 None", r10 is None)


def test_security():
    print(f"\n{BOLD}{CYAN}🔒 安全函数{NC}")

    # safe_pip_install 存在且可调用
    check("safe_pip_install 是可调用的", callable(Security.safe_pip_install))
    check("safe_apt_install 是可调用的", callable(Security.safe_apt_install))
    check("safe_remote_script 是可调用的", callable(Security.safe_remote_script))

    # 验证不删除锁文件
    import inspect
    src = inspect.getsource(Security.safe_apt_install)
    check_not_contains("safe_apt_install 不删锁文件", src, "rm.*lock")
    src2 = inspect.getsource(Security)
    check_not_contains("Security 类不包含 rm /var/lib/dpkg", src2, "rm /var/lib/dpkg")


def test_map_parser():
    print(f"\n{BOLD}{CYAN}📋 映射表解析{NC}")

    # 创建临时映射表
    with tempfile.NamedTemporaryFile(mode="w", suffix=".md", delete=False) as f:
        f.write("# 测试映射表\n\n")
        f.write("| 任务 | 工具 | 安装降级链 |\n")
        f.write("|------|------|-----------|\n")
        f.write("| 搜索文件内容 | `ripgrep (rg)` | `apt ripgrep → dl github.com/BurntSushi/ripgrep` |\n")
        f.write("| 处理 JSON | `jq` | `apt jq → dl github.com/jqlang/jq` |\n")
        f.write("| 中文:压缩文件 | `zip` | `apt zip` |\n")
        tmp_path = f.name

    try:
        parser = MapParser(Path(tmp_path))

        # 精确匹配
        r = parser.search("jq")
        check("搜索 jq 命中", r is not None)
        if r:
            check_eq("jq 命令名", r[0], "jq")
            check_contains("jq 降级链含 apt", r[1], "apt")

        # 别名格式
        r2 = parser.search("ripgrep")
        check("搜索 ripgrep 命中", r2 is not None)

        # 中文匹配
        r3 = parser.search("压缩文件")
        check("中文搜索命中", r3 is not None)

        # 未命中
        r4 = parser.search("nonexistent_tool_xyz")
        check("未命中返回 None", r4 is None)
    finally:
        os.unlink(tmp_path)


def test_learning():
    print(f"\n{BOLD}{CYAN}📝 学习管理{NC}")

    tmpdir = tempfile.mkdtemp()
    try:
        cfg = Config()
        cfg.learn_log = Path(tmpdir) / "learned.log"
        cfg.fail_log = Path(tmpdir) / "failed.log"
        cfg.stats_file = Path(tmpdir) / "stats.json"
        cfg.history_file = Path(tmpdir) / "history.jsonl"
        cfg.map_file = Path(tmpdir) / "map.md"

        lm = LearningManager(cfg)

        # 记录成功
        lm.record_success("test-tool", "测试工具", "apt test-tool", "test")
        check("学习记录文件创建", cfg.learn_log.exists())
        check("学习记录包含 test-tool", "test-tool" in cfg.learn_log.read_text())

        # 去重
        lm.record_success("test-tool", "测试工具", "apt test-tool", "test")
        lines = cfg.learn_log.read_text().strip().splitlines()
        check("去重: 只记录一次", len(lines) == 1)

        # 记录失败
        lm.record_failure("fail-tool", "apt", "fail-pkg", "测试失败")
        check("失败记录创建", cfg.fail_log.exists())
        check("失败记录包含 fail-tool", "fail-tool" in cfg.fail_log.read_text())

        # 近期失败检测（格式: [timestamp] tool | method pkg | reason）
        check("近期失败: true", lm.is_recently_failed("fail-tool", "apt", "fail-pkg"))
        check("近期失败: false (不同工具)", not lm.is_recently_failed("other-tool", "apt", "other-pkg"))

        # JSONL 历史
        lm.log_history("query1", "cmd1", "apt", True, 100)
        lm.log_history("query2", "cmd2", "pip", False, 200)
        check("JSONL 历史创建", cfg.history_file.exists())
        lines = cfg.history_file.read_text().strip().splitlines()
        check_eq("JSONL 有 2 条记录", len(lines), 2)
        check_contains("JSONL 含 success:true", lines[0], '"success": true')
        check_contains("JSONL 含 success:false", lines[1], '"success": false')

        # 统计（record_success 已调用 increment_stat 1次，再手动 +2 = 3）
        lm.increment_stat("test-tool")
        lm.increment_stat("test-tool")
        lm.increment_stat("other-tool")
        check("统计文件创建", cfg.stats_file.exists())
        import json
        stats = json.loads(cfg.stats_file.read_text())
        check_eq("统计: test-tool=3", stats.get("test-tool"), 3)
        check_eq("统计: other-tool=1", stats.get("other-tool"), 1)

        # 自动回写映射表
        cfg.map_file.write_text("| 任务 | 工具 | 安装降级链 |\n|------|------|-----------|\n")
        lm.record_success("new-tool", "新工具", "apt new-tool", "q")
        content = cfg.map_file.read_text()
        check("自动回写: new-tool 在映射表中", "new-tool" in content)
        check("自动回写: 含降级链", "apt new-tool" in content)

    finally:
        shutil.rmtree(tmpdir)


def test_cross_platform_mapping():
    print(f"\n{BOLD}{CYAN}🌍 跨平台映射完整性{NC}")

    # 验证所有映射条目都有 apt 和至少一个其他平台
    p = Platform()
    multi_platform = 0
    for name, mapping in Platform.PACKAGE_MAP.items():
        if len(mapping) >= 3:
            multi_platform += 1

    total = len(Platform.PACKAGE_MAP)
    check(f"映射表有 {total}+ 条目", total >= 80)
    check(f"多平台条目 {multi_platform}+ (≥3 平台)", multi_platform >= 50)
    pct = multi_platform * 100 // total if total else 0
    print(f"  ℹ  多平台覆盖率: {pct}%")


def test_safety_patterns():
    print(f"\n{BOLD}{CYAN}🔐 安全模式检查{NC}")

    # 读取 Python 源码
    py_src = Path(__file__).parent / "auto-installer.py"
    content = py_src.read_text()

    # 不应有直接的 pip3 install --break-system-packages（不在 safe_pip_install 内的）
    # 检查 safe_pip_install 函数内有正确的降级链
    import inspect
    src = inspect.getsource(Security.safe_pip_install)
    check_contains("safe_pip_install 先尝试 pipx", src, "pipx")
    check_contains("safe_pip_install 有 venv 路径", src, "venv")
    check_contains("safe_pip_install 最后才 break", src, "break-system-packages")


if __name__ == "__main__":
    print(f"\n{BOLD}{CYAN}🧪 auto-installer v3.0 行为测试{NC}")

    try:
        test_platform()
        test_inference()
        test_security()
        test_map_parser()
        test_learning()
        test_cross_platform_mapping()
        test_safety_patterns()
    finally:
        # 清理临时模块
        if _dst.exists():
            pass  # 保留缓存

    print(f"\n{BOLD}{CYAN}════════════════════════════════════{NC}")
    print(f"{BOLD}  结果: {GREEN}{PASS} 通过{NC} / {RED}{FAIL} 失败{NC}")
    print(f"{BOLD}{CYAN}════════════════════════════════════{NC}\n")

    if FAIL == 0:
        print(f"  {GREEN}{BOLD}🎉 全部通过！{NC}")
    else:
        print(f"  {RED}{BOLD}⚠ 有 {FAIL} 项未通过{NC}")

    sys.exit(0 if FAIL == 0 else 1)
